package com.groovyrey.kumi

import android.annotation.SuppressLint
import android.webkit.JsResult
import android.webkit.WebChromeClient
import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import java.io.ByteArrayInputStream
import java.io.BufferedReader
import java.io.InputStreamReader
import java.util.HashSet

/**
 * A native Android WebView that blocks ad/tracker requests at the network
 * layer using a bundled EasyList/EasyPrivacy host blocklist, while letting the
 * actual video/playback requests load. It also mocks common ad-API signals so
 * anti-adblock detection doesn't withhold playback.
 */
internal class AdBlockWebView(
    context: android.content.Context,
    private val channel: MethodChannel,
) : PlatformView, MethodChannel.MethodCallHandler {

    private val webView: WebView = WebView(context).apply { configure() }

    // Load the bundled blocklist once into a set for fast suffix matching.
    private val blockedHosts: Set<String> = loadBlockedHosts(context)

    init {
        channel.setMethodCallHandler(this)
    }

    @SuppressLint("SetJavaScriptEnabled")
    private fun configure() {
        val settings = webView.settings
        settings.javaScriptEnabled = true
        settings.domStorageEnabled = true
        settings.mediaPlaybackRequiresUserGesture = false
        settings.javaScriptCanOpenWindowsAutomatically = false
        settings.setSupportMultipleWindows(false)
        settings.loadWithOverviewMode = true
        settings.useWideViewPort = true
        settings.blockNetworkImage = false
        settings.blockNetworkLoads = false

        webView.webViewClient = AdBlockClient()
        webView.webChromeClient = object : WebChromeClient() {
            override fun onCreateWindow(
                view: WebView?, isDialog: Boolean, isUserGesture: Boolean,
                resultMsg: android.os.Message?
            ): Boolean {
                // Block popup windows / new tabs opened by the embed (ad redirects).
                return false
            }

            override fun onJsAlert(
                view: WebView?, url: String?, message: String?, result: JsResult?
            ): Boolean {
                result?.confirm() // Auto-dismiss JS alert popups (often ad prompts).
                return true
            }
        }
    }

    private inner class AdBlockClient : WebViewClient() {

        override fun shouldOverrideUrlLoading(
            view: WebView?, request: WebResourceRequest?
        ): Boolean {
            val host = request?.url?.host?.lowercase() ?: return false

            // Only stop navigation to known ad/redirect hosts. Everything else
            // (playback redirects, SPAs) proceeds so anti-adblock doesn't trip.
            if (isBlockedHost(host)) {
                reportBlocked(host, request?.url?.toString())
                return true
            }
            return super.shouldOverrideUrlLoading(view, request)
        }

        override fun shouldInterceptRequest(
            view: WebView?, request: WebResourceRequest?
        ): WebResourceResponse? {
            val host = request?.url?.host?.lowercase() ?: return null

            // Never filter the player's own origin or video CDNs: the SDK
            // handshake drives playback and blocking it breaks the video.
            if (isEmbedHost(host) || isVideoHost(host)) return null

            if (isBlockedHost(host)) {
                reportBlocked(host, request?.url?.toString())
                return emptyResource()
            }
            return null
        }

        override fun onPageStarted(view: WebView?, url: String?, favicon: android.graphics.Bitmap?) {
            super.onPageStarted(view, url, favicon)
            channel.invokeMethod("onPageStarted", url)
        }

        override fun onPageFinished(view: WebView?, url: String?) {
            super.onPageFinished(view, url)
            channel.invokeMethod("onPageFinished", url)
            // Mock ad signals so detection scripts believe ads loaded.
            injectAdShims(view)
        }

        override fun onReceivedError(
            view: WebView?, errorCode: Int, description: String?, failingUrl: String?
        ) {
            super.onReceivedError(view, errorCode, description, failingUrl)
            channel.invokeMethod("onPageError", mapOf("code" to errorCode, "url" to failingUrl))
        }
    }

    private fun isBlockedHost(host: String): Boolean {
        // Test every suffix of the host against the set (e.g. a.b.com -> a.b.com,
        // b.com, com). Matches EasyList `||domain^` semantics across subdomains.
        var h: String = host
        while (true) {
            if (blockedHosts.contains(h)) return true
            val idx = h.indexOf('.')
            if (idx < 0) return false
            h = h.substring(idx + 1)
        }
    }

    private fun isEmbedHost(host: String): Boolean {
        return EMBED_SUFFIXES.any { host == it || host.endsWith(".$it") }
    }

    private fun isVideoHost(host: String): Boolean {
        return VIDEO_SUFFIXES.any { host == it || host.endsWith(".$it") }
    }

    private fun injectAdShims(view: WebView?) {
        if (view == null) return
        val js = """
            (function() {
              if (!window.adsbygoogle) {
                var push = function() { try { return arguments[0]; } catch(e){} };
                window.adsbygoogle = { length: 0, push: push };
              }
              if (window.AdSense === undefined) window.AdSense = {};
              if (window.google_ad_status === undefined) window.google_ad_status = 0;
              if (window._pwGoogleGpt === undefined) window._pwGoogleGpt = [];
              if (window.googletag === undefined) {
                window.googletag = { cmd: [], pubads: function(){ return { enableSingleRequest:function(){}, refresh:function(){}, getSlotIdIfActual:function(){return 0;} }; }, apiReady: true, openads: {} };
              }
            })();
        """.trimIndent()
        view.evaluateJavascript(js, null)
    }

    private fun emptyResource(): WebResourceResponse {
        return WebResourceResponse("text/plain", "utf-8", ByteArrayInputStream(ByteArray(0)))
    }

    private fun reportBlocked(host: String, url: String?) {
        // Report each unique host only once to avoid flooding the channel.
        if (!reportedHosts.add(host)) return
        try {
            channel.invokeMethod("onBlocked", mapOf("host" to host, "url" to url))
        } catch (_: Exception) {
            // Best effort only.
        }
    }

    private val reportedHosts: MutableSet<String> =
        java.util.Collections.synchronizedSet(HashSet<String>())

    private fun loadBlockedHosts(context: android.content.Context): Set<String> {
        val set = HashSet<String>(200000)
        try {
            val stream = context.assets.open("adblock_hosts.txt")
            BufferedReader(InputStreamReader(stream)).useLines { lines ->
                for (line in lines) {
                    val h = line.trim().lowercase()
                    if (h.isNotEmpty()) set.add(h)
                }
            }
        } catch (_: Exception) {
            // If the asset is missing, fall back to a near-empty set (video still plays).
        }
        return set
    }

    override fun getView(): android.view.View = webView

    fun loadInitialUrl(url: String) {
        webView.loadUrl(url)
    }

    override fun dispose() {
        webView.destroy()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "loadUrl" -> {
                val url = call.argument<String>("url")
                if (url != null) webView.loadUrl(url)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    companion object {
        // Never filter these origins: their SDK handshake drives playback.
        val EMBED_SUFFIXES = listOf(
            "cinesrc.st", "cineflix.st",
            "playapi.eu.cc", "peachify.top", "vidgod.net", "moviesapi.club",
            "googleapis.com", "gstatic.com", "fonts.googleapis.com"
        )

        // Common video CDNs that must never be filtered.
        val VIDEO_SUFFIXES = listOf(
            "akamaized.net", "cloudfront.net", "amazonaws.com",
            "fastly.net", "b-cdn.net", "cdn.dev", "googlevideo.com", "vimeocdn.com",
            "vimeo.com", "bitmovin.com"
        )
    }
}
