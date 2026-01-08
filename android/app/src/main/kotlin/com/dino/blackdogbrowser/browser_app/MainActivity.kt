package com.dino.blackdogbrowser.browser_app

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.dino.blackdogbrowser.browser_app/deeplink"
    private var methodChannel: MethodChannel? = null
    private var pendingDeepLink: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Setup method channel
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            if (call.method == "getInitialLink") {
                val initialLink = getInitialLink()
                if (initialLink != null) {
                    result.success(initialLink)
                } else {
                    result.success(null)
                }
            } else {
                result.notImplemented()
            }
        }

        // Gửi pending deep link nếu có (khi app đang chạy và nhận được link trước khi engine ready)
        pendingDeepLink?.let { url ->
            methodChannel?.invokeMethod("onDeepLink", url)
            pendingDeepLink = null
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Xử lý initial intent khi app mở lần đầu
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // Xử lý intent khi app đang chạy
        handleIntent(intent)
        setIntent(intent)
    }

    override fun onDestroy() {
        super.onDestroy()
        methodChannel = null
    }

    private fun handleIntent(intent: Intent?) {
        val data = intent?.data
        if (data != null) {
            val url = data.toString()
            // Gửi ngay nếu engine đã ready,否则 lưu lại để gửi sau
            if (methodChannel != null) {
                methodChannel?.invokeMethod("onDeepLink", url)
            } else {
                pendingDeepLink = url
            }
        }
    }

    private fun getInitialLink(): String? {
        return intent?.data?.toString()
    }
}
