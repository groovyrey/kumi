package com.groovyrey.kumi

import android.annotation.SuppressLint
import android.webkit.JsResult
import android.webkit.WebChromeClient
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView

/**
 * A native Android WebView used as the in-app player. It behaves like a normal
 * browser so embedded players always load and play (no request filtering or
 * signal mocking), with two safety measures: ad/new-tab popups are blocked and
 * JS alert prompts are auto-dismissed, so ads can't yank the user out of the
 * app. Media autoplays without requiring a user gesture.
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
        settings.javaScriptCanOpenWindowsAutomatically = false
        settings.setSupportMultipleWindows(false)
        settings.loadWithOverviewMode = true
        settings.useWideViewPort = true
        settings.blockNetworkImage = false
        settings.blockNetworkLoads = false

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
}
