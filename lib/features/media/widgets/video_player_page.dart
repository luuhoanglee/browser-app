import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:video_player/video_player.dart';

/// Video player page with playback controls
class VideoPlayerPage extends StatefulWidget {
  final String videoUrl;
  final String title;

  const VideoPlayerPage({
    super.key,
    required this.videoUrl,
    this.title = '',
  });

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  InAppWebViewController? _webViewController;

  // Quản lý trạng thái
  bool _hasError = false;
  bool _useWebView = false;
  bool _isInitializing = true;

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
        Uri.parse(widget.videoUrl),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
          allowBackgroundPlayback: false,
        ),
        // Thêm headers cần thiết
        httpHeaders: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          'Accept': '*/*',
          'Accept-Language': 'en-US,en;q=0.9',
          'Connection': 'keep-alive',
          'Origin': origin,
          'Referer': '$origin/',
        },
      );

      _videoPlayerController!.addListener(() {
        if (_videoPlayerController!.value.hasError) {
          print('Video player error: ${_videoPlayerController!.value.errorDescription}');

          if (!_useWebView && mounted) {
            setState(() {
              _hasError = true;
              _useWebView = true;
              _isInitializing = false;
            });
          }
        }
      });

      await _videoPlayerController!.initialize();
      _createChewieController();
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    } catch (e) {
      print('Video player initialization error: $e');

      if (!_useWebView && mounted) {
        setState(() {
          _hasError = true;
          _useWebView = true;
          _isInitializing = false;
        });
      }
    }
  }

  void _createChewieController() {
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController!,
      autoPlay: true,
      looping: false,
      showControls: true,
      materialProgressColors: ChewieProgressColors(
        playedColor: Colors.blue,
        handleColor: Colors.white,
        backgroundColor: Colors.grey,
        bufferedColor: Colors.lightBlue,
      ),
      placeholder: Container(
        color: Colors.black,
      ),
      autoInitialize: true,
    );
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
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
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: Colors.white),
    );
  }

  Widget _buildWebViewPlayer() {
    final uri = Uri.parse(widget.videoUrl);
    final origin = '${uri.scheme}://${uri.host}';

    return InAppWebView(
      initialSettings: InAppWebViewSettings(
        mediaPlaybackRequiresUserGesture: false,
        allowsInlineMediaPlayback: true,
        allowsPictureInPictureMediaPlayback: true,
      ),
      initialData: InAppWebViewInitialData(data: '''
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
<meta name="referrer" content="origin">
<title>Video Player</title>
<style>
  * {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
  }

  html, body {
    width: 100%;
    height: 100%;
    background: #000;
    overflow: hidden;
  }

  #video-container {
    position: relative;
    width: 100%;
    height: 100%;
    background: #000;
  }

  video {
    width: 100%;
    height: 100%;
    object-fit: contain;
  }
</style>
</head>
<body>
<div id="video-container">
  <video id="video" playsinline webkit-playsinline autoplay controls preload="metadata" style="background: #000;"></video>
</div>

<script>
(function() {
  'use strict';
  const video = document.getElementById('video');

  // Fetch video với proper headers
  fetch("${widget.videoUrl}", {
    headers: {
      'Referer': '$origin/',
    }
  })
  .then(response => {
    if (response.ok) {
      return response.blob();
    }
    throw new Error('Network response was not ok');
  })
  .then(blob => {
    const videoURL = URL.createObjectURL(blob);
    video.src = videoURL;
    console.log('Video loaded from blob');
  })
  .catch(error => {
    console.error('Error loading video:', error);
    // Fallback: set src directly
    video.src = "${widget.videoUrl}";
  });

  video.addEventListener('loadedmetadata', function() {
    console.log('Video loaded: duration=' + video.duration);
    video.play().catch(e => console.error('Play error:', e));
  });

  video.addEventListener('error', function(e) {
    console.error('Video error:', e);
  });

  console.log('Video player initialized');
})();
</script>

</body>
</html>
'''),
    );
  }
}
