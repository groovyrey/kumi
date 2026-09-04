package com.groovyrey.kumi

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine
            .platformViewsController
            .registry
            .registerViewFactory(
                AdBlockWebViewFactory.VIEW_TYPE_ID,
                AdBlockWebViewFactory(flutterEngine.dartExecutor.binaryMessenger)
            )
    }
}
