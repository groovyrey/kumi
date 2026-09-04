package com.groovyrey.kumi

import android.annotation.SuppressLint
import android.util.Log
import android.webkit.JsResult
import android.webkit.WebChromeClient
import android.webkit.WebResourceError
import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView

private const val TAG = "KumiPlayerWebView"

/**
 * A native Android WebView used as the in-app player. It presents a desktop
 * Chrome user agent and allows mixed content so third-party embed players
 * (CineSrc, PlayAPI, ...) render the desktop player and can pull their video
 * stream over HTTP without the WebView blocking it. Ad/new-tab popups are
 * blocked and blocking JS alerts are auto-dismissed so ads can't yank the user
 * out of the app or stall the player. Media autoplays without a gesture.
 */
internal class PlayerWebView(
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
        settings.setSupportMultipleWindows(false)
        settings.javaScriptCanOpenWindowsAutomatically = false
        settings.loadWithOverviewMode = true
        settings.useWideViewPort = true
        settings.blockNetworkImage = false
        settings.blockNetworkLoads = false
        settings.setMixedContentMode(WebSettings.MIXED_CONTENT_ALWAYS_ALLOW)
        // Many streaming embeds are desktop-first and show a blank/loading player
        // for unknown or mobile user agents. Present a desktop Chrome UA so they
        // render the working desktop player.
        settings.userAgentString =
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 " +
            "(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"

        webView.webViewClient = SimpleClient()
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

    private inner class SimpleClient : WebViewClient() {
        override fun onPageStarted(view: WebView?, url: String?, favicon: android.graphics.Bitmap?) {
            super.onPageStarted(view, url, favicon)
            Log.i(TAG, "pageStart: $url")
            channel.invokeMethod("onPageStarted", url)
        }

        override fun onPageFinished(view: WebView?, url: String?) {
            super.onPageFinished(view, url)
            Log.i(TAG, "pageFinish: $url")
            channel.invokeMethod("onPageFinished", url)
        }

        override fun shouldInterceptRequest(
            view: WebView?, request: WebResourceRequest?
        ): WebResourceResponse? {
            // Log every resource/fetch/XHR/HLS request so we can spot the one
            // that never resolves during playback. Returning null never blocks.
            val u = request?.url?.toString()
            if (u != null) {
                Log.i(TAG, "req: $u")
                // Forward the meaningful ones (page navigation + video/media
                // stream requests) to the app so they show on device without
                // logcat. Segment-by-segment .ts/.tsa noise is throttled away.
                if (request?.isForMainFrame == true || isMediaUrl(u)) {
                    channel.invokeMethod("onRequest", u)
                }
            }
            return null
        }

        override fun onReceivedError(
            view: WebView?, request: WebResourceRequest?, error: WebResourceError?
        ) {
            super.onReceivedError(view, request, error)
            val u = request?.url?.toString()
            Log.e(TAG, "pageError code=${error?.errorCode} desc=${error?.description} url=$u")
            channel.invokeMethod(
                "onPageError",
                mapOf(
                    "code" to ("err:${error?.errorCode ?: -1}"),
                    "url" to u,
                    "desc" to (error?.description?.toString() ?: "")
                )
            )
        }

        override fun onReceivedHttpError(
            view: WebView?, request: WebResourceRequest?, errorResponse: WebResourceResponse?
        ) {
            super.onReceivedHttpError(view, request, errorResponse)
            val u = request?.url?.toString()
            val status = errorResponse?.statusCode
            Log.e(TAG, "httpError $status url=$u")
            if (u != null && isMediaUrl(u)) {
                channel.invokeMethod(
                    "onPageError",
                    mapOf("code" to ("http:$status"), "url" to u, "desc" to "")
                )
            }
        }
    }

    override fun getView(): android.view.View = webView

    private fun isMediaUrl(url: String): Boolean {
        val u = url.lowercase()
        return u.contains(".m3u8") || u.contains(".mpd") ||
            u.contains("playlist") || u.contains("stream") ||
            u.contains(".mp4") || u.contains("videosrc") ||
            u.contains("/api/streams/") || u.contains("hls")
    }

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
}
