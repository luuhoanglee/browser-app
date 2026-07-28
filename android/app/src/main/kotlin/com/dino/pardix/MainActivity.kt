package com.dino.pardix

import android.content.Intent
import android.content.res.Configuration
import android.os.Bundle
import android.util.Log
import android.view.View
import android.view.ViewGroup
import android.webkit.WebView
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val DEEPLINK_CHANNEL = "com.dino.pardix/deeplink"
    private val ADBLOCK_CHANNEL = "com.dino.pardix/adblock"
    private var deeplinkMethodChannel: MethodChannel? = null
    private var adblockMethodChannel: MethodChannel? = null
    private var pendingDeepLink: String? = null

    companion object {
        private const val TAG = "MainActivity"
        private const val PLATFORM_VIEW_LAYOUT_SETTLE_DELAY_MS = 150L

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

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)

        // Android platform views can retain the previous surface dimensions when
        // configuration changes happen in quick succession. Request layout once
        // the window has applied its new bounds, and once more after the platform
        // view composition has settled.
        window.decorView.post {
            refreshWebViewLayout(window.decorView)
        }
        window.decorView.postDelayed({
            refreshWebViewLayout(window.decorView)
        }, PLATFORM_VIEW_LAYOUT_SETTLE_DELAY_MS)
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

    private fun refreshWebViewLayout(view: View) {
        view.requestLayout()
        view.invalidate()

        if (view is WebView) {
            view.forceLayout()
        }

        if (view is ViewGroup) {
            for (index in 0 until view.childCount) {
                refreshWebViewLayout(view.getChildAt(index))
            }
        }
    }
}
