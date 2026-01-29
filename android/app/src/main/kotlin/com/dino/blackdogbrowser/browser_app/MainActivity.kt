package com.dino.blackdogbrowser.browser_app

import android.content.Intent
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val DEEPLINK_CHANNEL = "com.dino.blackdogbrowser.browser_app/deeplink"
    private val ADBLOCK_CHANNEL = "com.dino.blackdogbrowser.browser_app/adblock"
    private var deeplinkMethodChannel: MethodChannel? = null
    private var adblockMethodChannel: MethodChannel? = null
    private var pendingDeepLink: String? = null

    companion object {
        private const val TAG = "MainActivity"
        init {
            // Initialize AdBlockService when class loads
            try {
                AdBlockService.init()
                Log.d(TAG, "AdBlockService initialized successfully")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to initialize AdBlockService", e)
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Setup deeplink method channel
        deeplinkMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DEEPLINK_CHANNEL)
        deeplinkMethodChannel?.setMethodCallHandler { call, result ->
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

        // Setup adblock method channel
        adblockMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ADBLOCK_CHANNEL)
        adblockMethodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "shouldBlockUrl" -> {
                    val url = call.argument<String>("url")
                    val shouldBlock = AdBlockService.shouldBlockUrl(url)
                    result.success(shouldBlock)
                }
                "getBlockedResponse" -> {
                    // Return info about the blocked response
                    result.success(mapOf(
                        "mimeType" to "text/plain",
                        "encoding" to "UTF-8",
                        "statusCode" to 200,
                        "reasonPhrase" to "OK"
                    ))
                }
                "getPatternCount" -> {
                    result.success(AdBlockService.getPatternCount())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Gửi pending deep link nếu có
        pendingDeepLink?.let { url ->
            deeplinkMethodChannel?.invokeMethod("onDeepLink", url)
            pendingDeepLink = null
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
        setIntent(intent)
    }

    override fun onDestroy() {
        super.onDestroy()
        deeplinkMethodChannel = null
        adblockMethodChannel = null
    }

    private fun handleIntent(intent: Intent?) {
        val data = intent?.data
        if (data != null) {
            val url = data.toString()
            if (deeplinkMethodChannel != null) {
                deeplinkMethodChannel?.invokeMethod("onDeepLink", url)
            } else {
                pendingDeepLink = url
            }
        }
    }

    private fun getInitialLink(): String? {
        return intent?.data?.toString()
    }
}
