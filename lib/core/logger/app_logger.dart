import 'dart:developer' as dev;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'log_level.dart';
import 'log_record.dart';

/// Central logger for Pardix Browser.
///
/// ## Log routing by level
///
/// | Level   | Debug build         | Release build                         |
/// |---------|---------------------|---------------------------------------|
/// | VERBOSE | console only        | suppressed                            |
/// | DEBUG   | console only        | suppressed                            |
/// | INFO    | console only        | Crashlytics breadcrumb                |
/// | WARNING | console             | Crashlytics breadcrumb (non-fatal)    |
/// | ERROR   | console             | Crashlytics non-fatal error           |
/// | FATAL   | console             | Crashlytics fatal error               |
///
/// Calling [AppLogger.event] always logs to Firebase Analytics (release only).
///
/// ## Usage
///
/// ```dart
/// // Simple logs
/// AppLogger.verbose('WebView', 'Request: $url');
/// AppLogger.debug('TabBloc', 'Tab added: $tabId');
/// AppLogger.info('Search', 'Query: $q', params: {AnalyticsParam.engine: 'google'});
/// AppLogger.warning('Download', 'Slow network detected');
/// AppLogger.error('Storage', 'Save failed', error: e, stackTrace: s);
/// AppLogger.fatal('App', 'Unhandled crash', error: e, stackTrace: s);
///
/// // Analytics-only event
/// AppLogger.event(AnalyticsEvent.tabOpened, params: {
///   AnalyticsParam.isIncognito: false,
///   AnalyticsParam.tabCount: 3,
/// });
/// ```
abstract final class AppLogger {
  /// Minimum level printed to the console in debug mode. Change if needed.
  static LogLevel consoleMinLevel = LogLevel.VERBOSE;

  /// Whether Firebase is available (set to false before Firebase.initializeApp).
  static bool _firebaseReady = false;

  static FirebaseAnalytics? _analytics;
  static FirebaseCrashlytics? _crashlytics;

  /// Call this once Firebase.initializeApp() has completed.
  static void initFirebase() {
    _firebaseReady = true;
    _analytics = FirebaseAnalytics.instance;
    _crashlytics = FirebaseCrashlytics.instance;
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  static void verbose(String tag, String message, {Map<String, Object>? params}) =>
      _log(LogLevel.VERBOSE, tag, message, params: params);

  static void debug(String tag, String message, {Map<String, Object>? params}) =>
      _log(LogLevel.DEBUG, tag, message, params: params);

  static void info(
    String tag,
    String message, {
    Map<String, Object>? params,
  }) =>
      _log(LogLevel.INFO, tag, message, params: params);

  static void warning(
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object>? params,
  }) =>
      _log(LogLevel.WARNING, tag, message,
          error: error, stackTrace: stackTrace, params: params);

  static void error(
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object>? params,
  }) =>
      _log(LogLevel.ERROR, tag, message,
          error: error, stackTrace: stackTrace, params: params);

  static void fatal(
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object>? params,
  }) =>
      _log(LogLevel.FATAL, tag, message,
          error: error, stackTrace: stackTrace, params: params);

  /// Log a named Firebase Analytics event.
  ///
  /// In debug builds: prints to console only.
  /// In release builds: sent to Firebase Analytics.
  ///
  /// [name] must match a constant from [AnalyticsEvent].
  /// [params] keys must match constants from [AnalyticsParam].
  static void event(
    String name, {
    Map<String, Object>? params,
  }) {
    _printToConsole(LogRecord(
      level: LogLevel.INFO,
      tag: 'Analytics',
      message: 'EVENT: $name ${params ?? ''}',
      params: params,
    ));

    if (!kDebugMode && _firebaseReady) {
      _analytics?.logEvent(
        name: name,
        parameters: params?.map((k, v) => MapEntry(k, v)),
      );
    }
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  static void _log(
    LogLevel level,
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object>? params,
  }) {
    final record = LogRecord(
      level: level,
      tag: tag,
      message: message,
      error: error,
      stackTrace: stackTrace,
      params: params,
    );

    _printToConsole(record);
    _routeToFirebase(record);
  }

  static void _printToConsole(LogRecord record) {
    if (!kDebugMode && record.level < LogLevel.WARNING) return;
    if (record.level < consoleMinLevel) return;

    dev.log(
      record.toConsoleString(),
      name: record.tag,
      level: _dartLogLevel(record.level),
      error: record.error,
      stackTrace: record.stackTrace,
      time: record.timestamp,
    );
  }

  static void _routeToFirebase(LogRecord record) {
    if (!_firebaseReady) return;
    if (kDebugMode) return; // Only in release builds

    switch (record.level) {
      case LogLevel.VERBOSE:
      case LogLevel.DEBUG:
        break; // suppressed in release

      case LogLevel.INFO:
        // Breadcrumb only — helps reconstruct sequence before a crash
        _crashlytics?.log(record.toBreadcrumb());

      case LogLevel.WARNING:
        _crashlytics?.log(record.toBreadcrumb());
        if (record.error != null) {
          _crashlytics?.recordError(
            record.error,
            record.stackTrace,
            reason: '[WARNING][${ record.tag}] ${record.message}',
            fatal: false,
          );
        }

      case LogLevel.ERROR:
        _crashlytics?.log(record.toBreadcrumb());
        _crashlytics?.recordError(
          record.error ?? record.message,
          record.stackTrace,
          reason: '[${record.tag}] ${record.message}',
          fatal: false,
        );

      case LogLevel.FATAL:
        _crashlytics?.log(record.toBreadcrumb());
        _crashlytics?.recordError(
          record.error ?? record.message,
          record.stackTrace,
          reason: '[FATAL][${record.tag}] ${record.message}',
          fatal: true,
        );
    }
  }

  /// Maps [LogLevel] to dart:developer numeric level for IDE filtering.
  static int _dartLogLevel(LogLevel level) => switch (level) {
        LogLevel.VERBOSE => 300,
        LogLevel.DEBUG   => 500,
        LogLevel.INFO    => 800,
        LogLevel.WARNING => 900,
        LogLevel.ERROR   => 1000,
        LogLevel.FATAL   => 1200,
      };
}
