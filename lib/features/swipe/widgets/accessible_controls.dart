import 'package:flutter/material.dart';
import '../../../core/constants/swipe_constants.dart';

class AccessibleVideoControls extends StatelessWidget {
  final bool isPlaying;
  final Duration currentPosition;
  final Duration totalDuration;
  final VoidCallback onPlayPause;
  final VoidCallback onSeekForward;
  final VoidCallback onSeekBackward;
  final VoidCallback onFullscreen;
  final Function(Duration) onSeek;

  const AccessibleVideoControls({
    Key? key,
    required this.isPlaying,
    required this.currentPosition,
    required this.totalDuration,
    required this.onPlayPause,
    required this.onSeekForward,
    required this.onSeekBackward,
    required this.onFullscreen,
    required this.onSeek,
  }) : super(key: key);

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Progress bar with accessibility
        Semantics(
          label:
              'Video pozisyonu: ${_formatDuration(currentPosition)} / ${_formatDuration(totalDuration)}',
          value:
              totalDuration.inMilliseconds > 0
                  ? '${(currentPosition.inMilliseconds / totalDuration.inMilliseconds * 100).round()}%'
                  : '0%',
          increasedValue: '10 saniye ileri',
          decreasedValue: '10 saniye geri',
          onIncrease: onSeekForward,
          onDecrease: onSeekBackward,
          child: Slider(
            value:
                totalDuration.inMilliseconds > 0
                    ? currentPosition.inMilliseconds.toDouble()
                    : 0.0,
            max: totalDuration.inMilliseconds.toDouble(),
            onChanged: (value) => onSeek(Duration(milliseconds: value.toInt())),
            activeColor: Theme.of(context).primaryColor,
            inactiveColor: Colors.white.withOpacity(0.3),
          ),
        ),

        // Control buttons row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Seek backward button
            Semantics(
              button: true,
              label: '10 saniye geri',
              onTap: onSeekBackward,
              child: IconButton(
                onPressed: onSeekBackward,
                icon: Icon(Icons.replay_10, color: Colors.white),
                iconSize: SwipeConstants.controlButtonSize,
                tooltip: '10 saniye geri',
              ),
            ),

            // Play/Pause button
            Semantics(
              button: true,
              label:
                  isPlaying
                      ? SwipeConstants.pauseButtonSemanticLabel
                      : SwipeConstants.playButtonSemanticLabel,
              onTap: onPlayPause,
              child: IconButton(
                onPressed: onPlayPause,
                icon: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                ),
                iconSize: SwipeConstants.controlButtonSize + 8,
                tooltip: isPlaying ? 'Duraklat' : 'Oynat',
              ),
            ),

            // Seek forward button
            Semantics(
              button: true,
              label: '10 saniye ileri',
              onTap: onSeekForward,
              child: IconButton(
                onPressed: onSeekForward,
                icon: Icon(Icons.forward_10, color: Colors.white),
                iconSize: SwipeConstants.controlButtonSize,
                tooltip: '10 saniye ileri',
              ),
            ),

            // Fullscreen button
            Semantics(
              button: true,
              label: SwipeConstants.fullscreenButtonSemanticLabel,
              onTap: onFullscreen,
              child: IconButton(
                onPressed: onFullscreen,
                icon: Icon(Icons.fullscreen, color: Colors.white),
                iconSize: SwipeConstants.controlButtonSize,
                tooltip: 'Tam ekran',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class AccessibleSwipeButtons extends StatelessWidget {
  final VoidCallback onLike;
  final VoidCallback onDislike;

  const AccessibleSwipeButtons({
    Key? key,
    required this.onLike,
    required this.onDislike,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Dislike button
          Semantics(
            button: true,
            label: SwipeConstants.dislikeButtonSemanticLabel,
            hint: 'Bu filmi beğenmiyorsanız dokunun',
            onTap: onDislike,
            child: ElevatedButton.icon(
              onPressed: onDislike,
              icon: Icon(Icons.close, color: Colors.red),
              label: Text('Beğenme'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ),

          // Like button
          Semantics(
            button: true,
            label: SwipeConstants.likeButtonSemanticLabel,
            hint: 'Bu filmi beğendiyseniz dokunun',
            onTap: onLike,
            child: ElevatedButton.icon(
              onPressed: onLike,
              icon: Icon(Icons.favorite, color: Colors.green),
              label: Text('Beğen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
