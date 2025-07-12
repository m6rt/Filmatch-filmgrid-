import 'dart:async';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class OptimizedVideoPlayer extends StatefulWidget {
  final String? trailerUrl;
  final Color backgroundColor;
  final bool autoPlay;
  final bool enableFullscreenControls;
  final Duration? initialPosition;

  const OptimizedVideoPlayer({
    super.key,
    this.trailerUrl,
    required this.backgroundColor,
    this.autoPlay = false,
    this.enableFullscreenControls = false,
    this.initialPosition,
  });

  @override
  State<OptimizedVideoPlayer> createState() => OptimizedVideoPlayerState();
}

class OptimizedVideoPlayerState extends State<OptimizedVideoPlayer> {
  YoutubePlayerController? _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String? _videoId;
  bool _showControls = false; // Kontrol görünürlüğü için
  Timer? _hideControlsTimer; // Kontrolleri gizlemek için timer

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() {
    if (widget.trailerUrl != null) {
      _videoId = YoutubePlayer.convertUrlToId(widget.trailerUrl!);

      if (_videoId != null) {
        _controller = YoutubePlayerController(
          initialVideoId: _videoId!,
          flags: YoutubePlayerFlags(
            autoPlay: widget.autoPlay,
            mute: false, // Ses her zaman açık
            loop: false,
            enableCaption: widget.enableFullscreenControls,
            showLiveFullscreenButton: widget.enableFullscreenControls,
            controlsVisibleAtStart: widget.enableFullscreenControls,
            hideControls: false, // Kontrolleri her zaman göster
            disableDragSeek: false, // Seek'i her zaman aktif
            forceHD: false,
            startAt: 0,
            useHybridComposition: true, // Performans için
          ),
        );

        _controller!.addListener(_onPlayerStateChanged);

        // Loading'i daha hızlı bitir
        setState(() {
          _isLoading = false;
        });

        // Initial position varsa seek et
        if (widget.initialPosition != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _controller!.seekTo(widget.initialPosition!);
          });
        }
      } else {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onPlayerStateChanged() {
    if (_controller!.value.hasError) {
      setState(() {
        _hasError = true;
      });
    }
  }

  void _resetHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  Duration? get currentPosition => _controller?.value.position;

  void seekTo(Duration position) {
    _controller?.seekTo(position);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              widget.backgroundColor,
              widget.backgroundColor.withOpacity(0.7),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Daha hızlı yükleme göstergesi
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Yükleniyor...',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    if (_hasError || _controller == null) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              widget.backgroundColor,
              widget.backgroundColor.withOpacity(0.7),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: Colors.white70),
              SizedBox(height: 16),
              Text(
                'Video yüklenemedi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Trailer mevcut değil',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(0),
      child: Stack(
        children: [
          // YouTube Player - Aspect ratio korunmuş
          Positioned.fill(
            child: YoutubePlayerBuilder(
              player: YoutubePlayer(
                controller: _controller!,
                showVideoProgressIndicator: true,
                progressIndicatorColor: Colors.red,
                progressColors: ProgressBarColors(
                  playedColor: Colors.red,
                  handleColor: Colors.redAccent,
                ),
                aspectRatio: 16 / 9,
              ),
              builder: (context, player) {
                return FittedBox(
                  fit: BoxFit.cover, // Video'yu yanlardan kesmeden tam doldur
                  child: player,
                );
              },
            ),
          ),

          // Play/Pause overlay - Sadece tam ekran değilse
          if (!widget.enableFullscreenControls)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showControls = !_showControls;
                  });
                  if (_showControls) {
                    if (_controller!.value.isPlaying) {
                      _controller!.pause();
                    } else {
                      _controller!.play();
                    }
                    _resetHideControlsTimer();
                  }
                },
                child: Container(
                  color: Colors.transparent,
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: _showControls ? 0.8 : 0.0,
                      duration: Duration(milliseconds: 300),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          shape: BoxShape.circle,
                        ),
                        padding: EdgeInsets.all(16),
                        child: Icon(
                          _controller!.value.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Önbellek yönetimi için
class VideoCache {
  static final VideoCache _instance = VideoCache._internal();
  factory VideoCache() => _instance;
  VideoCache._internal();

  final Map<String, YoutubePlayerController> _cache = {};
  final int _maxCacheSize = 5; // Maksimum 5 video cache'le

  YoutubePlayerController? getController(String videoId) {
    return _cache[videoId];
  }

  void cacheController(String videoId, YoutubePlayerController controller) {
    if (_cache.length >= _maxCacheSize) {
      // En eski controller'ı temizle
      final oldestKey = _cache.keys.first;
      _cache[oldestKey]?.dispose();
      _cache.remove(oldestKey);
    }

    _cache[videoId] = controller;
  }

  void clearCache() {
    for (var controller in _cache.values) {
      controller.dispose();
    }
    _cache.clear();
  }
}
