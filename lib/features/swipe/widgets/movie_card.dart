import 'package:flutter/material.dart';
import 'dart:async';
import '../../../models/movie.dart';
import '../../../core/constants/swipe_constants.dart';
import '../../../widgets/optimized_video_player.dart';
import '../controllers/video_controller.dart';
import 'accessible_controls.dart';
import 'error_widgets.dart';

class MovieCard extends StatefulWidget {
  final Movie movie;
  final VideoController videoController;
  final VoidCallback onLike;
  final VoidCallback onDislike;
  final VoidCallback onFullscreen;

  const MovieCard({
    Key? key,
    required this.movie,
    required this.videoController,
    required this.onLike,
    required this.onDislike,
    required this.onFullscreen,
  }) : super(key: key);

  @override
  State<MovieCard> createState() => _MovieCardState();
}

class _MovieCardState extends State<MovieCard> {
  bool _showControls = true;
  Timer? _hideControlsTimer;
  GlobalKey<OptimizedVideoPlayerState>? _playerKey;

  @override
  void initState() {
    super.initState();
    _playerKey = GlobalKey<OptimizedVideoPlayerState>();
    widget.videoController.setPlayerKey(_playerKey!);
    _startHideControlsTimer();
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    super.dispose();
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(SwipeConstants.hideControlsDuration, () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _showControlsTemporarily() {
    setState(() {
      _showControls = true;
    });
    _startHideControlsTimer();
  }

  String _formatMovieInfo() {
    return 'Film: ${widget.movie.title}, Türler: ${widget.movie.genre.join(', ')}, Yıl: ${widget.movie.year}';
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Semantics(
      label: _formatMovieInfo(),
      child: Stack(
        children: [
          // Video player
          Container(
            height: screenSize.height * SwipeConstants.videoHeightRatio,
            child: VideoErrorBoundary(
              error:
                  widget.videoController.hasError
                      ? widget.videoController.errorMessage
                      : null,
              onRetry: () {
                widget.videoController.setError(null);
                // Video yeniden yükleme logic'i burada olacak
              },
              child: Stack(
                children: [
                  OptimizedVideoPlayer(
                    key: _playerKey,
                    trailerUrl: widget.movie.trailerUrl,
                    backgroundColor: Colors.black,
                  ),

                  // Loading overlay
                  if (widget.videoController.isLoading)
                    LoadingOverlay(message: 'Video yükleniyor...'),

                  // Touch area to show controls
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: _showControlsTemporarily,
                      behavior: HitTestBehavior.translucent,
                      child: Container(),
                    ),
                  ),

                  // Video controls
                  if (_showControls && !widget.videoController.hasError)
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: ListenableBuilder(
                          listenable: widget.videoController,
                          builder: (context, child) {
                            return AccessibleVideoControls(
                              isPlaying: widget.videoController.isPlaying,
                              currentPosition:
                                  widget.videoController.currentPosition,
                              totalDuration:
                                  widget.videoController.totalDuration,
                              onPlayPause:
                                  widget.videoController.togglePlayPause,
                              onSeekForward: widget.videoController.seekForward,
                              onSeekBackward:
                                  widget.videoController.seekBackward,
                              onFullscreen: widget.onFullscreen,
                              onSeek: widget.videoController.seekTo,
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Movie info section
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: screenSize.height * SwipeConstants.infoSectionHeightRatio,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Movie title
                    Semantics(
                      label: 'Film başlığı: ${widget.movie.title}',
                      child: Text(
                        widget.movie.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    SizedBox(height: 8),

                    // Movie details
                    Semantics(
                      label:
                          'Film detayları: ${widget.movie.year} yılı, ${widget.movie.genre.join(", ")} türünde',
                      child: Row(
                        children: [
                          Text(
                            '${widget.movie.year}',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              widget.movie.genre.join(' • '),
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 4),

                    // Language and TMDB Rating
                    Semantics(
                      label:
                          'Dil: ${widget.movie.originalLanguage.toUpperCase()}, TMDB Puanı: ${widget.movie.voteAverage.toStringAsFixed(1)}',
                      child: Row(
                        children: [
                          // Language
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.movie.originalLanguage.toUpperCase(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          // TMDB Rating
                          Row(
                            children: [
                              Icon(Icons.star, color: Colors.amber, size: 16),
                              SizedBox(width: 4),
                              Text(
                                widget.movie.voteAverage.toStringAsFixed(1),
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    if (widget.movie.overview.isNotEmpty) ...[
                      SizedBox(height: 12),
                      Expanded(
                        child: Semantics(
                          label: 'Film açıklaması: ${widget.movie.overview}',
                          child: SingleChildScrollView(
                            child: Text(
                              widget.movie.overview,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],

                    SizedBox(height: 16),

                    // Action buttons
                    AccessibleSwipeButtons(
                      onLike: widget.onLike,
                      onDislike: widget.onDislike,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
