import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../models/movie.dart';
import '../theme/app_theme.dart';
import '../services/profile_service.dart';
import '../services/comments_service.dart';
import 'optimized_video_player.dart';

class MovieDetailModal extends StatefulWidget {
  final Movie movie;
  final ProfileService profileService;
  final Function(Movie)? onAddToFavorites;
  final Function(Movie)? onAddToWatchlist;
  final bool showActionButtons;

  const MovieDetailModal({
    Key? key,
    required this.movie,
    required this.profileService,
    this.onAddToFavorites,
    this.onAddToWatchlist,
    this.showActionButtons = true,
  }) : super(key: key);

  @override
  State<MovieDetailModal> createState() => _MovieDetailModalState();
}

class _MovieDetailModalState extends State<MovieDetailModal> {
  bool _isAddingToFavorites = false;
  bool _isAddingToWatchlist = false;
  bool _isInFavorites = false;
  bool _isInWatchlist = false;
  bool _isLoading = true;

  // Yorumlar için state'ler
  final CommentsService _commentsService = CommentsService();
  List<Map<String, dynamic>> _comments = [];
  bool _isLoadingComments = true;
  Map<String, dynamic> _ratingInfo = {
    'averageRating': 0.0,
    'commentCount': 0,
    'formattedRating': '0.0',
  };

  @override
  void initState() {
    super.initState();
    if (widget.showActionButtons) {
      _checkMovieStatus();
    } else {
      setState(() => _isLoading = false);
    }
    _loadComments();
  }

  Future<void> _loadComments() async {
    setState(() => _isLoadingComments = true);
    final comments = await _commentsService.getComments(widget.movie.id);
    final ratingInfo = await _commentsService.getMovieRatingInfo(
      widget.movie.id,
    );
    setState(() {
      _comments = comments;
      _ratingInfo = ratingInfo;
      _isLoadingComments = false;
    });
  }

  Future<void> _checkMovieStatus() async {
    final movieId = widget.movie.id.toString();
    try {
      final inFavorites = await widget.profileService.isMovieInFavorites(
        movieId,
      );
      final inWatchlist = await widget.profileService.isMovieInWatchlist(
        movieId,
      );

      if (mounted) {
        setState(() {
          _isInFavorites = inFavorites;
          _isInWatchlist = inWatchlist;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error checking movie status: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showFullscreenVideo() {
    if (widget.movie.trailerUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bu film için trailer mevcut değil'),
          backgroundColor: AppTheme.secondaryGrey,
        ),
      );
      return;
    }

    // Tam ekrana geçerken otomatik yatay çevir
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    showDialog(
      context: context,
      barrierDismissible: true,
      useSafeArea: false,
      builder: (context) {
        return _CustomFullscreenVideoPlayer(
          trailerUrl: widget.movie.trailerUrl!,
          onClose: () {
            // Dikey moda geri dön
            SystemChrome.setPreferredOrientations([
              DeviceOrientation.portraitUp,
              DeviceOrientation.portraitDown,
            ]);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Dialog(
      alignment: Alignment.center,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isTablet ? 96 : 16,
        vertical: 40,
      ),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: screenHeight * 0.3,
          maxHeight: screenHeight * 0.85,
          maxWidth: isTablet ? 600 : double.infinity,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with close button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.movie.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Column(
                  children: [
                    // Scrollable content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Trailer Video
                            if (widget.movie.trailerUrl != null)
                              Container(
                                height: isTablet ? 220 : 180,
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Stack(
                                    children: [
                                      OptimizedVideoPlayer(
                                        trailerUrl: widget.movie.trailerUrl!,
                                        backgroundColor: AppTheme.getGenreColor(
                                          widget.movie.genre.isNotEmpty
                                              ? widget.movie.genre.first
                                              : 'Unknown',
                                        ),
                                        autoPlay: true,
                                      ),
                                      // Tam ekran butonu
                                      Positioned(
                                        top: 12,
                                        right: 12,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(
                                              0.7,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: IconButton(
                                            onPressed: _showFullscreenVideo,
                                            icon: Icon(
                                              Icons.fullscreen,
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                            tooltip: 'Tam Ekran',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            // Movie Info
                            _buildInfoRow('Yönetmen', widget.movie.director),
                            _buildInfoRow('Tür', widget.movie.genre.join(', ')),
                            _buildInfoRow('Yıl', widget.movie.year.toString()),
                            _buildInfoRow(
                              'Oyuncular',
                              widget.movie.cast.take(3).join(', '),
                            ),

                            const SizedBox(height: 12),

                            // Description
                            Text(
                              'Açıklama',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.darkGrey,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.movie.description,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.darkGrey,
                                height: 1.4,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),

                            const SizedBox(height: 24),
                            // Yorumlar Bölümü
                            _buildCommentsSection(),

                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),

                    // Action Buttons - Sadece showActionButtons true ise göster
                    if (widget.showActionButtons)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child:
                            _isLoading
                                ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                                : Row(
                                  children: [
                                    // Favorilere Ekle/Çıkar
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed:
                                            _isAddingToFavorites
                                                ? null
                                                : () async {
                                                  setState(
                                                    () =>
                                                        _isAddingToFavorites =
                                                            true,
                                                  );

                                                  if (_isInFavorites) {
                                                    final success = await widget
                                                        .profileService
                                                        .removeFavoriteMovie(
                                                          widget.movie.id
                                                              .toString(),
                                                        );
                                                    if (success && mounted) {
                                                      setState(
                                                        () =>
                                                            _isInFavorites =
                                                                false,
                                                      );
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            '${widget.movie.title} favorilerden çıkarıldı',
                                                          ),
                                                          backgroundColor:
                                                              Colors.orange,
                                                        ),
                                                      );
                                                    }
                                                  } else {
                                                    if (widget
                                                            .onAddToFavorites !=
                                                        null) {
                                                      await widget
                                                          .onAddToFavorites!(
                                                        widget.movie,
                                                      );
                                                      if (mounted) {
                                                        setState(
                                                          () =>
                                                              _isInFavorites =
                                                                  true,
                                                        );
                                                      }
                                                    }
                                                  }

                                                  setState(
                                                    () =>
                                                        _isAddingToFavorites =
                                                            false,
                                                  );
                                                },
                                        icon:
                                            _isAddingToFavorites
                                                ? const SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.white,
                                                      ),
                                                )
                                                : Icon(
                                                  _isInFavorites
                                                      ? Icons.favorite
                                                      : Icons.favorite_border,
                                                  size: 18,
                                                ),
                                        label: Text(
                                          _isAddingToFavorites
                                              ? (_isInFavorites
                                                  ? 'Çıkarılıyor...'
                                                  : 'Ekleniyor...')
                                              : (_isInFavorites
                                                  ? 'Favorilerden Çıkar'
                                                  : 'Favorilere Ekle'),
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              _isInFavorites
                                                  ? Colors.orange
                                                  : AppTheme.primaryRed,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                            horizontal: 6,
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 8),

                                    // Listeye Ekle/Çıkar
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed:
                                            _isAddingToWatchlist
                                                ? null
                                                : () async {
                                                  setState(
                                                    () =>
                                                        _isAddingToWatchlist =
                                                            true,
                                                  );

                                                  if (_isInWatchlist) {
                                                    final success = await widget
                                                        .profileService
                                                        .removeFromWatchlist(
                                                          widget.movie.id
                                                              .toString(),
                                                        );
                                                    if (success && mounted) {
                                                      setState(
                                                        () =>
                                                            _isInWatchlist =
                                                                false,
                                                      );
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            '${widget.movie.title} izleme listesinden çıkarıldı',
                                                          ),
                                                          backgroundColor:
                                                              Colors.orange,
                                                        ),
                                                      );
                                                    }
                                                  } else {
                                                    if (widget
                                                            .onAddToWatchlist !=
                                                        null) {
                                                      await widget
                                                          .onAddToWatchlist!(
                                                        widget.movie,
                                                      );
                                                      if (mounted) {
                                                        setState(
                                                          () =>
                                                              _isInWatchlist =
                                                                  true,
                                                        );
                                                      }
                                                    }
                                                  }

                                                  setState(
                                                    () =>
                                                        _isAddingToWatchlist =
                                                            false,
                                                  );
                                                },
                                        icon:
                                            _isAddingToWatchlist
                                                ? const SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.white,
                                                      ),
                                                )
                                                : Icon(
                                                  _isInWatchlist
                                                      ? Icons.playlist_remove
                                                      : Icons.playlist_add,
                                                  size: 18,
                                                ),
                                        label: Text(
                                          _isAddingToWatchlist
                                              ? (_isInWatchlist
                                                  ? 'Çıkarılıyor...'
                                                  : 'Ekleniyor...')
                                              : (_isInWatchlist
                                                  ? 'Listeden Çıkar'
                                                  : 'Listeye Ekle'),
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              _isInWatchlist
                                                  ? Colors.orange
                                                  : AppTheme.primaryRed,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                            horizontal: 6,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.secondaryGrey,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14, color: AppTheme.darkGrey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Sol taraf: Puan ve yorum sayısı
            Row(
              children: [
                // Yıldız ikonu
                Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                // Ortalama puan
                Text(
                  _ratingInfo['formattedRating'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGrey,
                  ),
                ),
                const SizedBox(width: 8),
                // Yorumlar yazısı ve sayısı
                Text(
                  'Yorumlar (${_ratingInfo['commentCount']})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGrey,
                  ),
                ),
              ],
            ),
            // Sağ taraf: Tümünü gör butonu
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/comments',
                  arguments: {
                    'movieId': widget.movie.id,
                    'movie': widget.movie,
                  },
                ).then((_) => _loadComments());
              },
              child: Text(
                'Tümünü Gör',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.primaryRed,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 130,
          child:
              _isLoadingComments
                  ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryRed,
                    ),
                  )
                  : _comments.isEmpty
                  ? Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.lightGrey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'Henüz yorum yapılmamış.\nİlk yorumu sen yap!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.secondaryGrey,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                  : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _comments.length,
                    itemBuilder: (context, index) {
                      return _buildCommentCard(_comments[index]);
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildCommentCard(Map<String, dynamic> comment) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/comments',
          arguments: {'movieId': widget.movie.id, 'movie': widget.movie},
        ).then((_) => _loadComments());
      },
      child: Container(
        width: 300,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.lightGrey,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.secondaryGrey.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppTheme.primaryRed,
                  child: Text(
                    (comment['username']?.toString() ?? 'U')
                        .substring(0, 1)
                        .toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment['username']?.toString() ?? 'Kullanıcı',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.darkGrey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          ...List.generate(
                            5,
                            (starIndex) => Icon(
                              starIndex < ((comment['rating'] ?? 0) / 2)
                                  ? Icons.star
                                  : Icons.star_border,
                              size: 10,
                              color: Colors.amber,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              comment['date']?.toString() ?? '',
                              style: TextStyle(
                                fontSize: 9,
                                color: AppTheme.secondaryGrey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Expanded(
              child:
                  (comment['isSpoiler'] == true)
                      ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppTheme.primaryRed.withOpacity(0.5),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.visibility_off,
                              color: AppTheme.primaryRed,
                              size: 14,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Spoiler içerik\nTıklayın',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 9,
                                color: AppTheme.darkGrey,
                                fontWeight: FontWeight.w500,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      )
                      : Text(
                        comment['comment']?.toString() ?? '',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.darkGrey,
                          height: 1.3,
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

// Swipe view'daki _CustomFullscreenVideoPlayer widget'ını buraya da ekleyin
class _CustomFullscreenVideoPlayer extends StatefulWidget {
  final String trailerUrl;
  final VoidCallback onClose;

  const _CustomFullscreenVideoPlayer({
    required this.trailerUrl,
    required this.onClose,
  });

  @override
  State<_CustomFullscreenVideoPlayer> createState() =>
      _CustomFullscreenVideoPlayerState();
}

class _CustomFullscreenVideoPlayerState
    extends State<_CustomFullscreenVideoPlayer> {
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isPlaying = false;
  bool _showControls = true;
  Timer? _controlsTimer;

  @override
  void initState() {
    super.initState();
    _hideControlsAfterDelay();
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    super.dispose();
  }

  void _hideControlsAfterDelay() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _hideControlsAfterDelay();
    }
  }

  void _seekTo(Duration position) {
    // Seek implementasyonu - şimdilik boş bırakın
    setState(() => _currentPosition = position);
  }

  void _skip(int seconds) {
    final newPosition = Duration(
      seconds: (_currentPosition.inSeconds + seconds).clamp(
        0,
        _totalDuration.inSeconds,
      ),
    );
    _seekTo(newPosition);
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            // Video Player
            Container(
              width: double.infinity,
              height: double.infinity,
              child: OptimizedVideoPlayer(
                trailerUrl: widget.trailerUrl,
                backgroundColor: Colors.black,
                autoPlay: true,
              ),
            ),

            // Kontroller (sadece showControls true ise)
            if (_showControls) ...[
              // Üst bar - Close butonu
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                left: 20,
                child: GestureDetector(
                  onTap: () {
                    widget.onClose();
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: EdgeInsets.all(isTablet ? 16 : 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: isTablet ? 28 : 24,
                    ),
                  ),
                ),
              ),

              // Alt kontroller
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 20,
                left: 20,
                right: 20,
                child: Column(
                  children: [
                    // Progress bar
                    Slider(
                      value:
                          _totalDuration.inSeconds > 0
                              ? (_currentPosition.inSeconds /
                                      _totalDuration.inSeconds)
                                  .clamp(0.0, 1.0)
                              : 0.0,
                      min: 0.0,
                      max: 1.0,
                      activeColor: AppTheme.primaryRed,
                      inactiveColor: Colors.white.withOpacity(0.3),
                      onChanged: (value) {
                        final newPosition = Duration(
                          seconds: (_totalDuration.inSeconds * value).round(),
                        );
                        _seekTo(newPosition);
                      },
                    ),

                    const SizedBox(height: 10),

                    // Kontrol butonları
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // 10 saniye geri
                        GestureDetector(
                          onTap: () => _skip(-10),
                          child: Container(
                            padding: EdgeInsets.all(isTablet ? 16 : 12),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.replay_10,
                              color: Colors.white,
                              size: isTablet ? 28 : 24,
                            ),
                          ),
                        ),

                        // Play/Pause butonu
                        GestureDetector(
                          onTap: () {
                            setState(() => _isPlaying = !_isPlaying);
                            // Video player'a play/pause komutu gönder
                          },
                          child: Container(
                            padding: EdgeInsets.all(isTablet ? 20 : 16),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: isTablet ? 36 : 32,
                            ),
                          ),
                        ),

                        // 10 saniye ileri
                        GestureDetector(
                          onTap: () => _skip(10),
                          child: Container(
                            padding: EdgeInsets.all(isTablet ? 16 : 12),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.forward_10,
                              color: Colors.white,
                              size: isTablet ? 28 : 24,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Zaman göstergesi
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_formatDuration(_currentPosition)}',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        Text(
                          '${_formatDuration(_totalDuration)}',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
