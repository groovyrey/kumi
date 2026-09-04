package com.groovyrey.kumi

import android.content.Context
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class PlayerWebViewFactory(
    private val messenger: BinaryMessenger
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    companion object {
        const val VIEW_TYPE_ID = "player-webview"
        private const val TAG = "KumiPlayerWebView"
    }

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val params = args as? Map<*, *>
        val channelName = params?.get("channel") as? String
            ?: "kumi/player-webview/$viewId"
        val url = params?.get("url") as? String
        Log.i(TAG, "factory create viewId=$viewId url=$url channel=$channelName " +
                "ctx=${context.javaClass.name}")  // non-blocking log
        val channel = MethodChannel(messenger, channelName)
        val view = PlayerWebView(context, channel)

        if (url != null && url.isNotEmpty()) {
            view.loadInitialUrl(url)
        } else {
            Log.e(TAG, "factory create got EMPTY url for viewId=$viewId")
        }
        return view
    }
}
