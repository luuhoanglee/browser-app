/// Firebase Analytics event names and parameter keys.
///
/// Event names must be ≤ 40 characters, snake_case.
/// Parameter keys must be ≤ 40 characters.
/// Parameter values (String) must be ≤ 100 characters.
///
/// Usage:
/// ```dart
/// AppLogger.event(AnalyticsEvent.tabOpened, params: {
///   AnalyticsParam.isIncognito: true,
/// });
/// ```
abstract final class AnalyticsEvent {
  // ── Tab events ─────────────────────────────────────────
  static const String tabOpened = 'tab_opened';
  static const String tabClosed = 'tab_closed';
  static const String tabSwitched = 'tab_switched';
  static const String incognitoToggled = 'incognito_toggled';
  static const String splitViewToggled = 'split_view_toggled';
  static const String splitViewResized = 'split_view_resized';
  static const String paneAudioToggled = 'pane_audio_toggled';

  // ── Navigation events ──────────────────────────────────
  static const String pageLoaded = 'page_loaded';
  static const String pageLoadError = 'page_load_error';
  static const String deepLinkOpened = 'deep_link_opened';
  static const String externalAppOpened = 'external_app_opened';

  // ── Search events ──────────────────────────────────────
  static const String searchPerformed = 'search_performed';
  static const String searchEngineChanged = 'search_engine_changed';
  static const String searchSuggestionTapped = 'search_suggestion_tapped';
  static const String searchHistoryCleared = 'search_history_cleared';

  // ── Download events ────────────────────────────────────
  static const String downloadStarted = 'download_started';
  static const String downloadCompleted = 'download_completed';
  static const String downloadFailed = 'download_failed';
  static const String downloadPaused = 'download_paused';
  static const String downloadResumed = 'download_resumed';
  static const String downloadCancelled = 'download_cancelled';
  static const String batchDownloadStarted = 'batch_download_started';

  // ── Media events ───────────────────────────────────────
  static const String mediaGalleryOpened = 'media_gallery_opened';
  static const String mediaViewed = 'media_viewed';
  static const String mediaDownloaded = 'media_downloaded';

  // ── Saved pages events ─────────────────────────────────
  static const String bookmarkSaved = 'bookmark_saved';
  static const String readingListSaved = 'reading_list_saved';

  // ── Ad block events ────────────────────────────────────
  static const String adBlocked = 'ad_blocked';

  // ── WARP / DNS events ──────────────────────────────────
  static const String warpOpened = 'warp_opened';
  static const String warpStoreOpened = 'warp_store_opened';
  static const String warpSiteOpened = 'warp_site_opened';

  // ── App lifecycle events ───────────────────────────────
  static const String appForegrounded = 'app_foregrounded';
  static const String notificationReceived = 'notification_received';
  static const String notificationTapped = 'notification_tapped';
}

/// Parameter keys used in analytics events.
abstract final class AnalyticsParam {
  // Tab
  static const String isIncognito = 'is_incognito';
  static const String tabCount = 'tab_count';
  static const String splitRatio = 'split_ratio';
  static const String hasAudio = 'has_audio';

  // Navigation
  static const String domain = 'domain';
  static const String errorType = 'error_type';
  static const String loadTimeMs = 'load_time_ms';

  // Search
  static const String engine = 'engine';
  static const String queryLength = 'query_length';

  // Download
  static const String fileType = 'file_type';
  static const String fileSizeKb = 'file_size_kb';
  static const String batchCount = 'batch_count';

  // Media
  static const String mediaType = 'media_type'; // image | video | audio
  static const String resourceCount = 'resource_count';

  // Ad block
  static const String blockedCount = 'blocked_count';
  static const String blockReason =
      'block_reason'; // domain | pattern | youtube

  // General
  static const String success = 'success';
  static const String durationMs = 'duration_ms';
}
