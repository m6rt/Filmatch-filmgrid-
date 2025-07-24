import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/movie.dart';
import '../services/profile_service.dart';
import '../services/comments_service.dart';
import '../theme/app_theme.dart';

class MovieDetailsDialog extends StatefulWidget {
  final Movie movie;
  final Function(Movie)? onAddToFavorites;
  final Function(Movie)? onAddToWatchlist;

  const MovieDetailsDialog({
    Key? key,
    required this.movie,
    this.onAddToFavorites,
    this.onAddToWatchlist,
  }) : super(key: key);

  @override
  State<MovieDetailsDialog> createState() => _MovieDetailsDialogState();
}

class _MovieDetailsDialogState extends State<MovieDetailsDialog> {
  final ProfileService _profileService = ProfileService();
  final CommentsService _commentsService = CommentsService();

  bool _isAddingToFavorites = false;
  bool _isAddingToWatchlist = false;
  bool _isInFavorites = false;
  bool _isInWatchlist = false;
  bool _isLoading = true;

  List<Map<String, dynamic>> _comments = [];
  bool _isLoadingComments = true;

  @override
  void initState() {
    super.initState();
    _checkMovieStatus();
    _loadComments();
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoadingComments = true;
    });

    final comments = await _commentsService.getComments(widget.movie.id);

    // Her yorum için kullanıcının profil fotoğrafını yükle
    final enrichedComments = await Future.wait(
      comments.map((comment) async {
        try {
          final username = comment['username'];
          if (username != null && username != 'Kullanıcı') {
            // Username'e göre Firestore'dan kullanıcı bilgilerini al
            final userQuery =
                await FirebaseFirestore.instance
                    .collection('users')
                    .where('username', isEqualTo: username)
                    .limit(1)
                    .get();

            if (userQuery.docs.isNotEmpty) {
              final userData = userQuery.docs.first.data();
              comment['profileImageUrl'] = userData['profilePictureURL'];
            }
          }
        } catch (e) {
          print(
            'Error loading profile image for user ${comment['username']}: $e',
          );
        }
        return comment;
      }).toList(),
    );

    setState(() {
      _comments = enrichedComments;
      _isLoadingComments = false;
    });
  }

  Future<void> _checkMovieStatus() async {
    final movieId = widget.movie.id.toString();
    try {
      final inFavorites = await _profileService.isMovieInFavorites(movieId);
      final inWatchlist = await _profileService.isMovieInWatchlist(movieId);

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
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addToFavorites() async {
    if (_isAddingToFavorites) return;

    setState(() {
      _isAddingToFavorites = true;
    });

    try {
      if (_isInFavorites) {
        await _profileService.removeFavoriteMovie(widget.movie.id.toString());
      } else {
        await _profileService.addFavoriteMovie(widget.movie.id.toString());
      }

      setState(() {
        _isInFavorites = !_isInFavorites;
      });

      if (widget.onAddToFavorites != null) {
        widget.onAddToFavorites!(widget.movie);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isInFavorites ? 'Favorilere eklendi' : 'Favorilerden çıkarıldı',
          ),
          backgroundColor: _isInFavorites ? AppTheme.primaryRed : Colors.grey,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata oluştu: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isAddingToFavorites = false;
      });
    }
  }

  Future<void> _addToWatchlist() async {
    if (_isAddingToWatchlist) return;

    setState(() {
      _isAddingToWatchlist = true;
    });

    try {
      if (_isInWatchlist) {
        await _profileService.removeFromWatchlist(widget.movie.id.toString());
      } else {
        await _profileService.addToWatchlist(widget.movie.id.toString());
      }

      setState(() {
        _isInWatchlist = !_isInWatchlist;
      });

      if (widget.onAddToWatchlist != null) {
        widget.onAddToWatchlist!(widget.movie);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isInWatchlist
                ? 'İzleme listesine eklendi'
                : 'İzleme listesinden çıkarıldı',
          ),
          backgroundColor: _isInWatchlist ? Colors.green : Colors.grey,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata oluştu: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isAddingToWatchlist = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Dialog(
      alignment: Alignment.center,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isTablet ? 60 : 20,
        vertical: 40,
      ),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.85,
          maxWidth: isTablet ? 600 : double.infinity,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with poster and close button
                Container(
                  height: isTablet ? 200 : 160,
                  child: Stack(
                    children: [
                      // Gradient background
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.primaryRed.withOpacity(0.8),
                              AppTheme.primaryRed.withOpacity(0.6),
                            ],
                          ),
                        ),
                      ),

                      // Close button
                      Positioned(
                        top: isTablet ? 16 : 12,
                        right: isTablet ? 16 : 12,
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: isTablet ? 28 : 24,
                          ),
                        ),
                      ),

                      // Movie title and year
                      Positioned(
                        bottom: isTablet ? 20 : 16,
                        left: isTablet ? 20 : 16,
                        right: isTablet ? 60 : 50,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.movie.title,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isTablet ? 24 : 20,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: isTablet ? 8 : 4),
                            Text(
                              '${widget.movie.year} • ${widget.movie.genre.join(", ")}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: isTablet ? 16 : 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isTablet ? 24 : 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Movie info
                        _buildInfoRow('Yönetmen', widget.movie.director),
                        if (widget.movie.cast.isNotEmpty)
                          _buildInfoRow(
                            'Oyuncular',
                            widget.movie.cast.take(3).join(', '),
                          ),

                        SizedBox(height: isTablet ? 20 : 16),

                        // Description
                        if (widget.movie.description.isNotEmpty) ...[
                          Text(
                            'Açıklama',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isTablet ? 18 : 16,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: isTablet ? 12 : 8),
                          Text(
                            widget.movie.description,
                            style: TextStyle(
                              fontSize: isTablet ? 16 : 14,
                              color: Colors.black87,
                              height: 1.5,
                            ),
                          ),
                          SizedBox(height: isTablet ? 24 : 20),
                        ],

                        // Action buttons
                        if (!_isLoading) ...[
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed:
                                      _isAddingToFavorites
                                          ? null
                                          : _addToFavorites,
                                  icon:
                                      _isAddingToFavorites
                                          ? SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          )
                                          : Icon(
                                            _isInFavorites
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            color: Colors.white,
                                          ),
                                  label: Text(
                                    _isInFavorites
                                        ? 'Favorilerden Çıkar'
                                        : 'Favorilere Ekle',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        _isInFavorites
                                            ? AppTheme.primaryRed
                                            : Colors.grey,
                                    padding: EdgeInsets.symmetric(
                                      vertical: isTablet ? 16 : 12,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed:
                                      _isAddingToWatchlist
                                          ? null
                                          : _addToWatchlist,
                                  icon:
                                      _isAddingToWatchlist
                                          ? SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          )
                                          : Icon(
                                            _isInWatchlist
                                                ? Icons.check
                                                : Icons.add,
                                            color: Colors.white,
                                          ),
                                  label: Text(
                                    _isInWatchlist
                                        ? 'Listeden Çıkar'
                                        : 'İzleme Listesi',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        _isInWatchlist
                                            ? Colors.green
                                            : Colors.blue,
                                    padding: EdgeInsets.symmetric(
                                      vertical: isTablet ? 16 : 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isTablet ? 24 : 20),
                        ],

                        // Comments section
                        _buildCommentsSection(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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
                fontWeight: FontWeight.w500,
                color: Colors.black54,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.black87, fontSize: 14),
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
        Text(
          'Yorumlar (${_comments.length})',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12),
        if (_isLoadingComments)
          Center(child: CircularProgressIndicator())
        else if (_comments.isEmpty)
          Text(
            'Henüz yorum yapılmamış.',
            style: TextStyle(
              color: Colors.black54,
              fontStyle: FontStyle.italic,
            ),
          )
        else
          ...List.generate(
            _comments.length.clamp(0, 3), // Maximum 3 yorum göster
            (index) => _buildCommentCard(_comments[index]),
          ),
        if (_comments.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Ve ${_comments.length - 3} yorum daha...',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCommentCard(Map<String, dynamic> comment) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Profil fotoğrafı
              CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.secondaryGrey,
                backgroundImage:
                    comment['profileImageUrl'] != null &&
                            comment['profileImageUrl'].toString().isNotEmpty
                        ? NetworkImage(comment['profileImageUrl'])
                        : null,
                child:
                    (comment['profileImageUrl'] == null ||
                            comment['profileImageUrl'].toString().isEmpty)
                        ? Text(
                          (comment['username'] ?? 'A')
                              .substring(0, 1)
                              .toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        )
                        : null,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  comment['username'] ?? 'Anonim',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < (comment['rating'] ?? 0)
                        ? Icons.star
                        : Icons.star_border,
                    color: Colors.amber,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            comment['comment'] ?? '',
            style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4),
          Text(
            comment['date'] ?? '',
            style: TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
