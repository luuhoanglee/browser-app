package com.dino.blackdogbrowser.browser_app

import android.util.Log
import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import java.io.ByteArrayInputStream
import java.util.regex.Pattern

class AdBlockService {
    companion object {
        private const val TAG = "AdBlockService"

        // List of ad/tracking URL patterns to block
        private val adPatterns = mutableListOf<Pattern>()

        // Whitelist domains to NEVER block
        private val whitelistDomains = listOf(
            "youtube.com", "youtu.be", "googlevideo.com",
            "gstatic.com", "googleapis.com", "googleusercontent.com",
            "youtubei.googleapis.com", "yt3.ggpht.com",
            "cloudflare.com", "cloudflareinsights.com",
            "cdn-cgi", "cloudflare.net", "cloudfront.net",
            "fastly.com", "fastlylb.net", "akamai.com",
            "akamaihd.net", "jwplayer.com", "jwpcdn.com",
            "vimeo.com", "vimeocdn.com", "dailymotion.com",
            "cdnjs.com", "jsdelivr.net", "unpkg.com",
            "bootstrap.com", "jquery.com", "fontawesome.com",
            "fonts.googleapis.com", "imgur.com",
            "fshare.vn", "cdn.fshare.vn", "drive.google.com"
        )

        /**
         * Get the number of loaded patterns
         */
        fun getPatternCount(): Int {
            return adPatterns.size
        }

        // Initialize default ad blocking patterns
        fun init() {
            // Google Ads & Analytics
            addPattern(".*doubleclick\\.net/.*")
            addPattern(".*googlesyndication\\.com/.*")
            addPattern(".*google-analytics\\.com/.*")
            addPattern(".*adservice\\.google\\.com/.*")
            addPattern(".*pagead2\\.googlesyndication\\.com/.*")
            addPattern(".*tpc\\.googlesyndication\\.com/.*")
            addPattern(".*g\\.doubleclick\\.net/.*")

            // Facebook Ads & Analytics
            addPattern(".*facebook\\.com/tr/.*")
            addPattern(".*facebook\\.com/*/ads/.*")
            addPattern(".*fbcdn\\.net/*/ad\\.php")
            addPattern(".*fbcdn\\.net/*/ads/.*")

            // Amazon Ads
            addPattern(".*adtago\\.s3\\.amazonaws\\.com/.*")
            addPattern(".*analyticsengine\\.s3\\.amazonaws\\.com/.*")
            addPattern(".*amazon-adsystem\\.com/.*")

            // AdColony
            addPattern(".*adcolony\\.com/.*")
            addPattern(".*ads30\\.adcolony\\.com/.*")

            // Media.net
            addPattern(".*media\\.net/.*")
            addPattern(".*static\\.media\\.net/.*")

            // Common ad networks
            addPattern(".*ads\\.pubmatic\\.com/.*")
            addPattern(".*adbrite\\.com/.*")
            addPattern(".*exponential\\.com/.*")
            addPattern(".*quantserve\\.com/.*")
            addPattern(".*scorecardresearch\\.com/.*")
            addPattern(".*zedo\\.com/.*")
            addPattern(".*adsafeprotected\\.com/.*")
            addPattern(".*teads\\.tv/.*")
            addPattern(".*outbrain\\.com/.*")
            addPattern(".*advertising\\.com/.*")
            addPattern(".*adnxs\\.com/.*")
            addPattern(".*criteo\\.com/.*")
            addPattern(".*taboola\\.com/.*")

            // Tracking & Analytics
            addPattern(".*analytics\\.*/.*")
            addPattern(".*tracking\\.*/.*")
            addPattern(".*tracker\\.*/.*")
            addPattern(".*pixel\\.*/.*")
            addPattern(".*telemetry\\.*/.*")
            addPattern(".*metrics\\.*/.*")
            addPattern(".*beacon\\.*/.*")
            addPattern(".*collect\\.*/.*")

            // Vietnamese ad networks
            addPattern(".*admicro\\.vn/.*")
            addPattern(".*mc\\.admicro\\.vn/.*")
            addPattern(".*qc\\.admicro\\.vn/.*")
            addPattern(".*media\\.admicro\\.vn/.*")
            addPattern(".*ads\\.nganluong\\.vn/.*")

            // Mobile ad networks
            addPattern(".*applovin\\.com/.*")
            addPattern(".*inmobi\\.com/.*")
            addPattern(".*startapp\\.com/.*")
            addPattern(".*appnext\\.com/.*")

            // Hotjar
            addPattern(".*hotjar\\.com/.*")
            addPattern(".*hotjar\\.io/.*")

            // Segment
            addPattern(".*segment\\.io/.*")
            addPattern(".*segment\\.com/.*")

            // Amplitude
            addPattern(".*amplitude\\.com/.*")

            // Mixpanel
            addPattern(".*mixpanel\\.com/.*")

            // Fullstory
            addPattern(".*fullstory\\.com/.*")

            // LogRocket
            addPattern(".*logrocket\\.com/.*")

            // Clarity
            addPattern(".*clarity\\.ms/.*")

            // Heap
            addPattern(".*heap\\.io/.*")

            // TikTok Ads
            addPattern(".*ads\\.tiktok\\.com/.*")
            addPattern(".*ads-api\\.tiktok\\.com/.*")
            addPattern(".*analytics\\.tiktok\\.com/.*")

            // Twitter Ads
            addPattern(".*ads-twitter\\.com/.*")
            addPattern(".*static\\.ads-twitter\\.com/.*")

            // LinkedIn Ads
            addPattern(".*ads\\.linkedin\\.com/.*")

            // Pinterest Ads
            addPattern(".*ads\\.pinterest\\.com/.*")

            // Reddit Analytics
            addPattern(".*events\\.reddit\\.com/.*")

            // Yahoo Ads
            addPattern(".*ads\\.yahoo\\.com/.*")
            addPattern(".*analytics\\.yahoo\\.com/.*")
            addPattern(".*gemini\\.yahoo\\.com/.*")

            // Yandex Ads
            addPattern(".*adfox\\.yandex\\.ru/.*")
            addPattern(".*metrika\\.yandex\\.ru/.*")

            // Unity Ads
            addPattern(".*unityads\\.unity3d\\.com/.*")
            addPattern(".*unity3d\\.com/.*")

            // Xiaomi Ads
            addPattern(".*ad\\.xiaomi\\.com/.*")
            addPattern(".*data\\.mistat\\.xiaomi\\.com/.*")

            // OPPO Ads
            addPattern(".*ads\\.oppomobile\\.com/.*")

            // Huawei Analytics
            addPattern(".*hicloud\\.com/.*")

            // OnePlus Ads
            addPattern(".*oneplus\\.cn/.*")
            addPattern(".*oneplus\\.net/.*")

            // Samsung Ads
            addPattern(".*samsungads\\.com/.*")

            // Video ads
            addPattern(".*aniview\\.com/.*")
            addPattern(".*vidoomy\\.com/.*")
            addPattern(".*spotxchange\\.com/.*")

            // Crypto miners
            addPattern(".*coin-hive\\.com/.*")
            addPattern(".*coinhive\\.com/.*")

            // Push notification spam
            addPattern(".*pushnotify\\.xyz/.*")
            addPattern(".*push-assist\\.com/.*")

            // Adult ads
            addPattern(".*exoclick\\.com/.*")
            addPattern(".*juicyads\\.com/.*")
            addPattern(".*popads\\.net/.*")
            addPattern(".*popcash\\.net/.*")

            Log.d(TAG, "Initialized ${adPatterns.size} ad blocking patterns")
        }

        private fun addPattern(pattern: String) {
            try {
                adPatterns.add(Pattern.compile(pattern))
            } catch (e: Exception) {
                Log.e(TAG, "Failed to compile pattern: $pattern", e)
            }
        }

        /**
         * Check if a URL should be blocked
         * @return true if the URL should be blocked, false otherwise
         */
        fun shouldBlockUrl(url: String?): Boolean {
            if (url == null) return false

            val urlLower = url.lowercase()

            // Check whitelist first
            for (domain in whitelistDomains) {
                if (urlLower.contains(domain)) {
                    return false
                }
            }

            // Don't block CDN-CGI or RUM requests (Cloudflare)
            if (urlLower.contains("/cdn-cgi/") || urlLower.contains("/rum")) {
                return false
            }

            // Check against all patterns
            for (pattern in adPatterns) {
                val matcher = pattern.matcher(urlLower)
                if (matcher.matches()) {
                    Log.d(TAG, "Blocked URL: $url")
                    return true
                }
            }

            // Additional path-based blocking
            val adPaths = listOf(
                "/ad/", "/ads/", "/advert", "/advertisement",
                "/tracking", "/analytics", "/pixel", "/telemetry",
                "/tracker", "/beacon", "/collect", "/log",
                "_ad.", "-ad.", ".ad.", "/ads."
            )

            for (path in adPaths) {
                if (urlLower.contains(path)) {
                    // Skip if it's a legitimate URL
                    if (urlLower.contains("/load/") || urlLower.contains("/read/") ||
                        urlLower.contains("/head") || urlLower.contains("/api/")) {
                        continue
                    }
                    Log.d(TAG, "Blocked URL by path: $url")
                    return true
                }
            }

            return false
        }

        /**
         * Create an empty WebResourceResponse to block a request
         */
        fun createBlockedResponse(): WebResourceResponse {
            // Return empty response to block the request
            return WebResourceResponse(
                "text/plain",
                "UTF-8",
                200,
                "OK",
                mapOf("Cache-Control" to "no-cache"),
                ByteArrayInputStream("".toByteArray())
            )
        }
    }
}
