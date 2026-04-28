import 'package:browser_app/core/logger/log_level.dart';

/// A single structured log entry.
class LogRecord {
  final LogLevel level;

  /// The class or feature tag, e.g. 'TabBloc', 'WebView', 'Download'.
  final String tag;

  /// Human-readable message.
  final String message;

  final DateTime timestamp;

  /// Optional structured data — forwarded to Firebase Analytics params.
  final Map<String, Object>? params;

  final Object? error;
  final StackTrace? stackTrace;

  LogRecord({
    required this.level,
    required this.tag,
    required this.message,
    Map<String, Object>? params,
    this.error,
    this.stackTrace,
  })  : timestamp = DateTime.now(),
        params = params;

  /// Formatted one-line string for console output.
  String toConsoleString() {
    final ts = _formatTime(timestamp);
    final base = '${level.emoji} [$ts][${level.label}][$tag] $message';
    if (error != null) return '$base\n  error: $error';
    return base;
  }

  /// Short breadcrumb for Crashlytics `.log()`.
  String toBreadcrumb() =>
      '[${level.label}][$tag] $message${error != null ? ' | $error' : ''}';

  String _formatTime(DateTime dt) =>
      '${_pad(dt.hour)}:${_pad(dt.minute)}:${_pad(dt.second)}.${dt.millisecond.toString().padLeft(3, '0')}';

  String _pad(int n) => n.toString().padLeft(2, '0');
}
