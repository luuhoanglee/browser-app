import 'dart:math';

import 'package:browser_app/core/api/api_client.dart';
import 'package:dio/dio.dart';

class MediaMetadata {
  final int? sizeBytes;
  final bool isEstimated;
  final bool isHls;

  const MediaMetadata({
    this.sizeBytes,
    this.isEstimated = false,
    this.isHls = false,
  });

  String get displaySize {
    final bytes = sizeBytes;
    if (bytes == null) {
      return isHls ? 'HLS stream' : 'Size unavailable';
    }

    const units = ['B', 'KB', 'MB', 'GB'];
    var value = bytes.toDouble();
    var unitIndex = 0;
    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024;
      unitIndex++;
    }

    final formatted = value >= 10 || unitIndex == 0
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
    return '${isEstimated ? '≈ ' : ''}$formatted ${units[unitIndex]}';
  }
}

class MediaMetadataService {
  MediaMetadataService._();

  static final Map<String, Future<MediaMetadata>> _cache = {};

  static Future<MediaMetadata> load(String url) {
    return _cache.putIfAbsent(url, () => _load(url));
  }

  static Future<MediaMetadata> _load(String url) async {
    if (Uri.tryParse(url)?.path.toLowerCase().endsWith('.m3u8') == true) {
      return _loadHls(url);
    }

    try {
      final response = await APIClient.shared.instance.head<void>(
        url,
        options: Options(
          followRedirects: true,
          maxRedirects: 5,
          receiveTimeout: const Duration(seconds: 8),
          sendTimeout: const Duration(seconds: 8),
        ),
      );
      return MediaMetadata(
        sizeBytes: int.tryParse(response.headers.value('content-length') ?? ''),
      );
    } catch (_) {
      return const MediaMetadata();
    }
  }

  static Future<MediaMetadata> _loadHls(String url) async {
    try {
      var playlistUrl = url;
      var playlist = await _getText(playlistUrl);
      var bandwidth = _masterBandwidth(playlist);
      final variant = _masterVariant(playlist, playlistUrl);
      if (variant != null) {
        playlistUrl = variant;
        playlist = await _getText(playlistUrl);
      }

      final durations = _segmentDurations(playlist);
      if (durations.isEmpty) {
        return const MediaMetadata(isHls: true);
      }

      if (bandwidth != null) {
        final seconds = durations.fold<double>(0, (sum, item) => sum + item);
        return MediaMetadata(
          sizeBytes: (bandwidth * seconds / 8).round(),
          isEstimated: true,
          isHls: true,
        );
      }

      final segments = _segmentUrls(playlist, playlistUrl);
      final sampleCount = min(3, min(segments.length, durations.length));
      var sampleBytes = 0;
      var sampleSeconds = 0.0;
      for (var index = 0; index < sampleCount; index++) {
        final size = await _headSize(segments[index]);
        if (size != null) {
          sampleBytes += size;
          sampleSeconds += durations[index];
        }
      }

      if (sampleBytes == 0 || sampleSeconds == 0) {
        return const MediaMetadata(isHls: true);
      }

      final totalSeconds = durations.fold<double>(0, (sum, item) => sum + item);
      return MediaMetadata(
        sizeBytes: (sampleBytes / sampleSeconds * totalSeconds).round(),
        isEstimated: true,
        isHls: true,
      );
    } catch (_) {
      return const MediaMetadata(isHls: true);
    }
  }

  static Future<String> _getText(String url) async {
    final response = await APIClient.shared.instance.get<String>(
      url,
      options: Options(
        responseType: ResponseType.plain,
        receiveTimeout: const Duration(seconds: 8),
        sendTimeout: const Duration(seconds: 8),
      ),
    );
    return response.data ?? '';
  }

  static Future<int?> _headSize(String url) async {
    try {
      final response = await APIClient.shared.instance.head<void>(
        url,
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        ),
      );
      return int.tryParse(response.headers.value('content-length') ?? '');
    } catch (_) {
      return null;
    }
  }

  static int? _masterBandwidth(String playlist) {
    final matches = RegExp(r'BANDWIDTH=(\d+)').allMatches(playlist);
    if (matches.isEmpty) return null;
    return matches
        .map((match) => int.tryParse(match.group(1) ?? '') ?? 0)
        .reduce(max);
  }

  static String? _masterVariant(String playlist, String baseUrl) {
    final lines = playlist.split(RegExp(r'\r?\n'));
    int bestBandwidth = -1;
    String? bestUrl;
    for (var index = 0; index < lines.length - 1; index++) {
      if (!lines[index].startsWith('#EXT-X-STREAM-INF:')) continue;
      final bandwidth =
          int.tryParse(
            RegExp(r'BANDWIDTH=(\d+)').firstMatch(lines[index])?.group(1) ?? '',
          ) ??
          0;
      final candidate = lines[index + 1].trim();
      if (candidate.isNotEmpty &&
          !candidate.startsWith('#') &&
          bandwidth > bestBandwidth) {
        bestBandwidth = bandwidth;
        bestUrl = Uri.parse(baseUrl).resolve(candidate).toString();
      }
    }
    return bestUrl;
  }

  static List<double> _segmentDurations(String playlist) {
    return RegExp(r'#EXTINF:([\d.]+)')
        .allMatches(playlist)
        .map((match) => double.tryParse(match.group(1) ?? '') ?? 0)
        .where((duration) => duration > 0)
        .toList();
  }

  static List<String> _segmentUrls(String playlist, String baseUrl) {
    return playlist
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty && !line.startsWith('#'))
        .map((line) => Uri.parse(baseUrl).resolve(line).toString())
        .toList();
  }
}
