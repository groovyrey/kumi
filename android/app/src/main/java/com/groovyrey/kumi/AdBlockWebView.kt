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

/**
 * A native Android WebView that blocks ad/tracker requests at the network
 * layer (the same idea as an ad-blocking browser), while letting the actual
 * video/playback requests load. Hosts are matched against a blocklist.
 */
internal class AdBlockWebView(
    context: android.content.Context,
    private val channel: MethodChannel,
) : PlatformView, MethodChannel.MethodCallHandler {

    private val webView: WebView = WebView(context).apply { configure() }

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
                view: WebView?, isDialog: Boolean, isUserGesture: Boolean, resultMsg: android.os.Message?
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
            val url = request?.url?.toString() ?: return false
            val host = request.url?.host?.lowercase() ?: return false

            // Do not leave the player into ad/redirect targets (e.g. click-layer
            // "open in new tab"). Allow the embed + playback origins.
            if (isBlockedHost(host)) {
                return true
            }
            // Never hand navigation to an external browser/app.
            if (!host.endsWith("cinesrc.st") &&
                !host.endsWith("cineflix.st") &&
                !isVideoHost(host) &&
                !isAdSafe(host)
            ) {
                return true
            }
            return super.shouldOverrideUrlLoading(view, request)
        }

        override fun shouldInterceptRequest(
            view: WebView?, request: WebResourceRequest?
        ): WebResourceResponse? {
            val url = request?.url?.toString() ?: return null
            val host = request.url?.host?.lowercase() ?: return null

            // Let the page, scripts, and video always load.
            if (host.endsWith("cinesrc.st")) return null
            if (isVideoHost(host)) return null

            // Intercept known ad/tracker hosts with an empty response.
            if (isBlockedHost(host)) {
                return WebResourceResponse(
                    "text/plain",
                    "utf-8",
                    ByteArrayInputStream(ByteArray(0))
                )
            }
            return null
        }

        override fun onPageStarted(view: WebView?, url: String?) {
            super.onPageStarted(view, url)
            channel.invokeMethod("onPageStarted", url)
        }

        override fun onPageFinished(view: WebView?, url: String?) {
            super.onPageFinished(view, url)
            channel.invokeMethod("onPageFinished", url)
        }

        override fun onReceivedError(
            view: WebView?, errorCode: Int, description: String?, failingUrl: String?
        ) {
            super.onReceivedError(view, errorCode, description, failingUrl)
            channel.invokeMethod("onPageError", mapOf("code" to errorCode, "url" to failingUrl))
        }
    }

    private fun isBlockedHost(host: String): Boolean {
        return BLOCKED_SUFFIXES.any { host == it || host.endsWith(".$it") }
    }

    private fun isVideoHost(host: String): Boolean {
        return VIDEO_SUFFIXES.any { host == it || host.endsWith(".$it") }
    }

    private fun isAdSafe(host: String): Boolean {
        return ALLOW_SUFFIXES.any { host == it || host.endsWith(".$it") }
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
            "reload" -> {
                webView.reload()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    companion object {
        val VIDEO_SUFFIXES = listOf(
            "akamaized.net", "cloudfront.net", "amazonaws.com",
            "fastly.net", "b-cdn.net", "cdn.dev", "googlevideo.com", "vimeocdn.com",
            "vimeo.com", "bitmovin.com"
        )

        val ALLOW_SUFFIXES = listOf(
            "cinesrc.st", "cineflix.st", "cinehub", "moviesapi.club",
            "googleapis.com", "gstatic.com", "fonts.googleapis.com"
        )

        // Ad & tracker hosts — matched by exact host or one-level subdomain suffix.
        val BLOCKED_SUFFIXES = listOf(
            // CineSrc's ad/tracker script hosts (audio/impression + ad SDK).
            "a.cineflix.st", "a2.cineflix.st", "pa-cineflix", "ads-cineflix",
            // Google ad serving.
            "doubleclick.net", "googlesyndication.com", "googleadservices.com",
            "adservice.google.com", "ads.google.com",
            // Generic ad / analytics networks.
            "adsterra.com", "popads.net", "propellerads.com", "exoclick.com",
            "adroll.com", "criteo.com", "outbrain.com", "taboola.com", "pubmatic.com",
            "rubiconproject.com", "openx.net", "adnxs.com", "appnexus.com",
            "smartadserver.com", "onclickads.net", "trafficjunky.net", "juicyads.com",
            // Trackers / analytics.
            "scorecardresearch.com", "quantserve.com", "chartbeat.com", "hotjar.com",
            "segment.io", "segment.com", "amplitude.com", "mixpanel.com",
            "fullstory.com", "clarity.ms", "plausible.io", "matomo.org",
            "mouseflow.com", "crazyegg.com", "newrelic.com", "sentry.io",
            "2mdn.net", "pagead2.googlesyndication.com",
            // Redirect / shortener / click layers.
            "zemanta.com", "imrworldwide.com", "tynt.com"
        )
    }
}
