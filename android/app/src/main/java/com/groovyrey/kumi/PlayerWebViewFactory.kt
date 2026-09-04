package com.groovyrey.kumi

import android.content.Context
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
    }

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val params = args as? Map<*, *>
        val channelName = params?.get("channel") as? String
            ?: "kumi/player-webview/$viewId"
        val channel = MethodChannel(messenger, channelName)
        val view = PlayerWebView(context, channel)

        val url = params?.get("url") as? String
        if (url != null && url.isNotEmpty()) {
            view.loadInitialUrl(url)
        }
        return view
    }
}
