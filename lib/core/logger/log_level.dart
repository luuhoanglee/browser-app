// ignore_for_file: constant_identifier_names

/// Log levels ordered by severity (lowest → highest).
///
/// - [VERBOSE] : Granular trace, dev-only.
/// - [DEBUG]   : Debug info, filtered out in release builds.
/// - [INFO]    : Notable app events — also sent to Firebase Analytics.
/// - [WARNING] : Unexpected but recoverable — sent as Crashlytics breadcrumb.
/// - [ERROR]   : Caught exceptions — sent to Crashlytics as non-fatal.
/// - [FATAL]   : Unrecoverable failures — sent to Crashlytics as fatal.
enum LogLevel {
  VERBOSE(0, 'VERBOSE', '🔍'),
  DEBUG(1, 'DEBUG', '🐛'),
  INFO(2, 'INFO', '💡'),
  WARNING(3, 'WARNING', '⚠️'),
  ERROR(4, 'ERROR', '🔴'),
  FATAL(5, 'FATAL', '💀');

  final int value;
  final String label;
  final String emoji;

  const LogLevel(this.value, this.label, this.emoji);

  bool operator >=(LogLevel other) => value >= other.value;
  bool operator >(LogLevel other) => value > other.value;
  bool operator <(LogLevel other) => value < other.value;
}
