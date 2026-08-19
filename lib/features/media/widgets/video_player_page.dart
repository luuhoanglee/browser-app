import 'dart:async';
import 'dart:convert';

import 'package:cast/cast.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:video_player/video_player.dart';

import '../../../core/logger/app_logger.dart';

/// Plays an extracted web video locally or on a Cast-enabled device.
class VideoPlayerPage extends StatefulWidget {
  final String videoUrl;
  final String title;

  const VideoPlayerPage({super.key, required this.videoUrl, this.title = ''});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  static const _defaultReceiverAppId = 'CC1AD845';

  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  InAppWebViewController? _webViewController;
  CastSession? _castSession;
  StreamSubscription<CastSessionState>? _castStateSubscription;
  StreamSubscription<Map<String, dynamic>>? _castMessageSubscription;

  bool _useWebView = false;
  bool _isInitializing = true;
  bool _isDiscovering = false;
  bool _isConnecting = false;
  bool _isCasting = false;
  String? _castDeviceName;
  int _castRequestId = 1;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      final uri = Uri.parse(widget.videoUrl);
      final origin = '${uri.scheme}://${uri.host}';

      _videoPlayerController = VideoPlayerController.networkUrl(
        uri,
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: false,
          allowBackgroundPlayback: false,
        ),
        httpHeaders: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
              'AppleWebKit/537.36 (KHTML, like Gecko) '
              'Chrome/91.0.4472.124 Safari/537.36',
          'Accept': '*/*',
          'Accept-Language': 'en-US,en;q=0.9',
          'Connection': 'keep-alive',
          'Origin': origin,
          'Referer': '$origin/',
        },
      );

      _videoPlayerController!.addListener(_handleLocalPlayerState);
      await _videoPlayerController!.initialize();
      _createChewieController();
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    } catch (error, stackTrace) {
      AppLogger.warning(
        'AppPlayer',
        'Native video player initialization failed; using WebView fallback',
        error: error,
        stackTrace: stackTrace,
      );
      if (mounted) {
        setState(() {
          _useWebView = true;
          _isInitializing = false;
        });
      }
    }
  }

  void _handleLocalPlayerState() {
    final controller = _videoPlayerController;
    if (controller == null || !controller.value.hasError || _useWebView) return;

    AppLogger.warning(
      'AppPlayer',
      'Native playback failed; using WebView fallback',
      error: controller.value.errorDescription,
    );
    if (mounted) {
      setState(() {
        _useWebView = true;
        _isInitializing = false;
      });
    }
  }

  void _createChewieController() {
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController!,
      autoPlay: true,
      looping: false,
      allowFullScreen: false,
      showControls: true,
      materialProgressColors: ChewieProgressColors(
        playedColor: Colors.blue,
        handleColor: Colors.white,
        backgroundColor: Colors.grey,
        bufferedColor: Colors.lightBlue,
      ),
      placeholder: Container(color: Colors.black),
      autoInitialize: true,
    );
  }

  Future<void> _showCastDevices() async {
    if (_isConnecting || _isDiscovering) return;
    if (_castSession != null) {
      await _showCastSessionActions();
      return;
    }

    setState(() => _isDiscovering = true);
    final search = CastDiscoveryService().search();
    try {
      if (!mounted) return;
      final device = await showModalBottomSheet<CastDevice>(
        context: context,
        backgroundColor: const Color(0xFF202124),
        builder: (context) => SafeArea(
          child: FutureBuilder<List<CastDevice>>(
            future: search,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _CastMessage(
                  icon: Icons.cast_connected,
                  title: 'Unable to search for Cast devices',
                  subtitle: snapshot.error.toString(),
                );
              }
              if (!snapshot.hasData) {
                return const _CastMessage(
                  icon: Icons.cast,
                  title: 'Looking for devices…',
                  showProgress: true,
                );
              }
              final devices = snapshot.data!;
              if (devices.isEmpty) {
                return const _CastMessage(
                  icon: Icons.cast,
                  title: 'No Cast devices found',
                  subtitle: 'Connect this phone and TV to the same Wi-Fi.',
                );
              }
              return ListView(
                shrinkWrap: true,
                children: [
                  const ListTile(
                    leading: Icon(Icons.cast, color: Colors.white),
                    title: Text(
                      'Cast to',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  for (final device in devices)
                    ListTile(
                      leading: const Icon(Icons.tv, color: Colors.white70),
                      title: Text(
                        device.name,
                        style: const TextStyle(color: Colors.white),
                      ),
                      onTap: () => Navigator.pop(context, device),
                    ),
                ],
              );
            },
          ),
        ),
      );
      if (device != null && mounted) {
        await _connectAndCast(device);
      }
    } finally {
      if (mounted) setState(() => _isDiscovering = false);
    }
  }

  Future<void> _connectAndCast(CastDevice device) async {
    setState(() {
      _isConnecting = true;
      _castDeviceName = device.name;
    });
    await _pauseLocalPlayback();

    try {
      final session = await CastSessionManager().startSession(
        device,
        const Duration(seconds: 10),
      );
      _castSession = session;
      _castStateSubscription = session.stateStream.listen(
        (state) {
          if (state == CastSessionState.connected) {
            _handleCastConnected(session);
          } else if (state == CastSessionState.closed) {
            _handleCastClosed();
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          _handleCastError(error, stackTrace);
        },
      );
      _castMessageSubscription = session.messageStream.listen(
        (message) => AppLogger.verbose(
          'AppPlayerCast',
          'Receiver message',
          params: {'type': message['type']?.toString() ?? 'unknown'},
        ),
        onError: (Object error, StackTrace stackTrace) {
          _handleCastError(error, stackTrace);
        },
      );
      session.sendMessage(CastSession.kNamespaceReceiver, {
        'type': 'LAUNCH',
        'appId': _defaultReceiverAppId,
        'requestId': _nextCastRequestId(),
      });
    } catch (error, stackTrace) {
      _handleCastError(error, stackTrace);
      await _resumeLocalPlayback();
    }
  }

  void _handleCastConnected(CastSession session) {
    if (!mounted || session != _castSession) return;
    setState(() {
      _isConnecting = false;
      _isCasting = true;
    });
    _loadRemoteMedia(session);
  }

  void _loadRemoteMedia(CastSession session) {
    final position = _videoPlayerController?.value.position.inMilliseconds ?? 0;
    session.sendMessage(CastSession.kNamespaceMedia, {
      'type': 'LOAD',
      'requestId': _nextCastRequestId(),
      'autoplay': true,
      'currentTime': position / 1000,
      'media': {
        'contentId': widget.videoUrl,
        'contentType': castContentTypeForUrl(widget.videoUrl),
        'streamType': 'BUFFERED',
        'metadata': {
          'metadataType': 0,
          'title': widget.title.isEmpty ? 'Pardix video' : widget.title,
        },
      },
    });
    AppLogger.info(
      'AppPlayerCast',
      'Sent media to Cast receiver',
      params: {'device': _castDeviceName ?? 'unknown'},
    );
  }

  Future<void> _showCastSessionActions() async {
    final shouldDisconnect = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Casting to ${_castDeviceName ?? 'device'}'),
        content: const Text('Stop casting and continue on this phone?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Stop casting'),
          ),
        ],
      ),
    );
    if (shouldDisconnect == true) {
      await _disconnectCast(stopRemote: true, resumeLocal: true);
    }
  }

  Future<void> _pauseLocalPlayback() async {
    await _videoPlayerController?.pause();
    await _webViewController?.evaluateJavascript(
      source: "document.querySelector('video')?.pause();",
    );
  }

  Future<void> _resumeLocalPlayback() async {
    if (!mounted) return;
    if (_useWebView) {
      await _webViewController?.evaluateJavascript(
        source: "document.querySelector('video')?.play().catch(() => {});",
      );
    } else {
      await _videoPlayerController?.play();
    }
  }

  Future<void> _disconnectCast({
    required bool stopRemote,
    required bool resumeLocal,
  }) async {
    final session = _castSession;
    _castSession = null;
    if (session != null) {
      if (stopRemote && session.state == CastSessionState.connected) {
        session.sendMessage(CastSession.kNamespaceMedia, {
          'type': 'STOP',
          'requestId': _nextCastRequestId(),
        });
      }
      await _castStateSubscription?.cancel();
      await _castMessageSubscription?.cancel();
      _castStateSubscription = null;
      _castMessageSubscription = null;
      await CastSessionManager().endSession(session.sessionId);
    }
    if (mounted) {
      setState(() {
        _isCasting = false;
        _isConnecting = false;
        _castDeviceName = null;
      });
    }
    if (resumeLocal) await _resumeLocalPlayback();
  }

  void _handleCastClosed() {
    if (!mounted) return;
    setState(() {
      _castSession = null;
      _isCasting = false;
      _isConnecting = false;
      _castDeviceName = null;
    });
  }

  void _handleCastError(Object error, StackTrace stackTrace) {
    AppLogger.warning(
      'AppPlayerCast',
      'Cast session failed',
      error: error,
      stackTrace: stackTrace,
    );
    if (!mounted) return;
    setState(() {
      _isCasting = false;
      _isConnecting = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not connect to the Cast device.')),
    );
  }

  int _nextCastRequestId() => _castRequestId++;

  @override
  void dispose() {
    _videoPlayerController?.removeListener(_handleLocalPlayerState);
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    unawaited(_disconnectCast(stopRemote: true, resumeLocal: false));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            if (!_useWebView && _chewieController != null)
              Chewie(controller: _chewieController!)
            else if (_useWebView)
              _buildWebViewPlayer()
            else if (_isInitializing)
              _buildLoading(),
            Positioned(
              top: 0,
              left: 0,
              child: IconButton(
                tooltip: 'Close App Player',
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                tooltip: _isCasting
                    ? 'Casting to $_castDeviceName'
                    : 'Cast video',
                onPressed: _isConnecting || _isDiscovering
                    ? null
                    : _showCastDevices,
                icon: _isConnecting || _isDiscovering
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        _isCasting ? Icons.cast_connected : Icons.cast,
                        color: _isCasting ? Colors.blue : Colors.white,
                      ),
              ),
            ),
            if (_isCasting)
              Positioned(
                top: 48,
                left: 48,
                right: 48,
                child: Text(
                  'Casting to $_castDeviceName',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator(color: Colors.white));
  }

  Widget _buildWebViewPlayer() {
    final uri = Uri.parse(widget.videoUrl);
    final origin = '${uri.scheme}://${uri.host}';
    final encodedUrl = jsonEncode(widget.videoUrl);
    final encodedReferer = jsonEncode('$origin/');

    return InAppWebView(
      initialSettings: InAppWebViewSettings(
        mediaPlaybackRequiresUserGesture: false,
        allowsInlineMediaPlayback: true,
        allowsPictureInPictureMediaPlayback: true,
      ),
      onWebViewCreated: (controller) => _webViewController = controller,
      initialData: InAppWebViewInitialData(
        data:
            '''
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
<meta name="referrer" content="origin">
<title>Video Player</title>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  html, body, #video-container { width: 100%; height: 100%; background: #000; overflow: hidden; }
  video { width: 100%; height: 100%; object-fit: contain; }
</style>
</head>
<body>
<div id="video-container">
  <video id="video" playsinline webkit-playsinline autoplay controls preload="metadata"></video>
</div>
<script>
(() => {
  const video = document.getElementById('video');
  const source = $encodedUrl;
  fetch(source, {headers: {'Referer': $encodedReferer}})
    .then(response => {
      if (!response.ok) throw new Error('HTTP ' + response.status);
      return response.blob();
    })
    .then(blob => {
      video.src = URL.createObjectURL(blob);
    })
    .catch(() => {
      video.src = source;
    });
  video.addEventListener('loadedmetadata', () => video.play().catch(() => {}));
})();
</script>
</body>
</html>
''',
      ),
    );
  }
}

String castContentTypeForUrl(String url) {
  final path = Uri.tryParse(url)?.path.toLowerCase() ?? url.toLowerCase();
  if (path.endsWith('.m3u8')) return 'application/x-mpegURL';
  if (path.endsWith('.webm')) return 'video/webm';
  if (path.endsWith('.mov')) return 'video/quicktime';
  return 'video/mp4';
}

class _CastMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool showProgress;

  const _CastMessage({
    required this.icon,
    required this.title,
    this.subtitle,
    this.showProgress = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showProgress)
                const CircularProgressIndicator(color: Colors.white)
              else
                Icon(icon, color: Colors.white70, size: 36),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white60),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
