import 'package:flutter/material.dart';
import '../../../widgets/optimized_video_player.dart';
import '../../../core/constants/swipe_constants.dart';

class VideoController extends ChangeNotifier {
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isPlaying = false;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  GlobalKey<OptimizedVideoPlayerState>? _playerKey;

  // Getters
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;

  void setPlayerKey(GlobalKey<OptimizedVideoPlayerState> key) {
    _playerKey = key;
  }

  void updatePosition(Duration position) {
    if (_currentPosition != position) {
      _currentPosition = position;
      notifyListeners();
    }
  }

  void updateDuration(Duration duration) {
    if (_totalDuration != duration) {
      _totalDuration = duration;
      notifyListeners();
    }
  }

  void updatePlayingState(bool playing) {
    if (_isPlaying != playing) {
      _isPlaying = playing;
      notifyListeners();
    }
  }

  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void setError(String? error) {
    _hasError = error != null;
    _errorMessage = error;
    notifyListeners();
  }

  Future<void> play() async {
    try {
      _playerKey?.currentState?.play();
      updatePlayingState(true);
      setError(null);
    } catch (e) {
      setError('Video oynatılırken hata: $e');
    }
  }

  Future<void> pause() async {
    try {
      _playerKey?.currentState?.pause();
      updatePlayingState(false);
    } catch (e) {
      setError('Video duraklatılırken hata: $e');
    }
  }

  Future<void> seekTo(Duration position) async {
    try {
      _playerKey?.currentState?.seekTo(position);
      updatePosition(position);
    } catch (e) {
      setError('Video konumu değiştirilirken hata: $e');
    }
  }

  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> seekForward() async {
    final newPosition = _currentPosition + SwipeConstants.seekStepDuration;
    final clampedPosition =
        newPosition > _totalDuration ? _totalDuration : newPosition;
    await seekTo(clampedPosition);
  }

  Future<void> seekBackward() async {
    final newPosition = _currentPosition - SwipeConstants.seekStepDuration;
    final clampedPosition =
        newPosition < Duration.zero ? Duration.zero : newPosition;
    await seekTo(clampedPosition);
  }

  void reset() {
    _currentPosition = Duration.zero;
    _totalDuration = Duration.zero;
    _isPlaying = false;
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
