import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../theme/app_theme.dart';
import '../services/comments_services.dart';

class CommentsView extends StatefulWidget {
  final int movieId;
  final Movie? movie;

  const CommentsView({Key? key, required this.movieId, this.movie})
    : super(key: key);

  @override
  State<CommentsView> createState() => _CommentsViewState();
}

class _CommentsViewState extends State<CommentsView> {
  bool _isSpoiler = false;
  int _selectedRating = 5;
  final TextEditingController _commentController = TextEditingController();

  // Service ve state
  final CommentsService _commentsService = CommentsService();
  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoading = true;
    });

    final comments = await _commentsService.getComments(widget.movieId);

    setState(() {
      _comments = comments;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.movie?.title ?? 'Film Yorumları',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppTheme.primaryRed,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Film posteri ve yorumlar
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                      onRefresh: _loadComments,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (widget.movie != null)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Film posteri
                                Container(
                                  width: 100,
                                  height: 150,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: NetworkImage(
                                        widget.movie!.posterUrl,
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Film bilgileri
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.movie!.title,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.darkGrey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${widget.movie!.year} • ${widget.movie!.genre.join(', ')}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppTheme.secondaryGrey,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Yönetmen: ${widget.movie!.director}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppTheme.darkGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                          const SizedBox(height: 24),

                          // Yorumlar başlığı
                          Text(
                            'Kullanıcı Yorumları (${_comments.length})',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkGrey,
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Yorumlar listesi
                          if (_comments.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.comment_outlined,
                                    size: 48,
                                    color: AppTheme.secondaryGrey,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Henüz yorum yapılmamış.\nİlk yorumu siz yapın!',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: AppTheme.secondaryGrey,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            ..._comments.map(
                              (comment) => Column(
                                children: [
                                  _buildCommentCard(
                                    username: comment['username'],
                                    rating: comment['rating'],
                                    comment: comment['comment'],
                                    date: comment['date'],
                                    isSpoiler: comment['isSpoiler'],
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
          ),
          // Yorum yap widget'ı
          _buildCommentForm(),
        ],
      ),
    );
  }

  Widget _buildCommentCard({
    required String username,
    required int rating,
    required String comment,
    required String date,
    required bool isSpoiler,
  }) {
    return _SpoilerCommentCard(
      username: username,
      rating: rating,
      comment: comment,
      date: date,
      isSpoiler: isSpoiler,
    );
  }

  Widget _buildCommentForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Film hakkında düşündüklerinizi yazın:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppTheme.darkGrey,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _commentController,
            decoration: InputDecoration(
              hintText: 'Yorumunuzu buraya yazın...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppTheme.primaryRed),
              ),
            ),
            maxLines: 3,
            enabled: !_isSending,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Spoiler switch'i
              GestureDetector(
                onTap:
                    _isSending
                        ? null
                        : () {
                          setState(() {
                            _isSpoiler = !_isSpoiler;
                          });
                        },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _isSpoiler ? AppTheme.primaryRed : Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          _isSpoiler ? AppTheme.primaryRed : Colors.grey[400]!,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.visibility_off,
                        size: 16,
                        color: _isSpoiler ? Colors.white : Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Spoiler',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _isSpoiler ? Colors.white : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Text('Puan:'),
              const SizedBox(width: 12),
              DropdownButton<int>(
                value: _selectedRating,
                items: List.generate(
                  10,
                  (index) => DropdownMenuItem(
                    value: index + 1,
                    child: Text('${index + 1}/10'),
                  ),
                ),
                onChanged:
                    _isSending
                        ? null
                        : (value) {
                          setState(() {
                            _selectedRating = value ?? 5;
                          });
                        },
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _isSending ? null : _sendComment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child:
                    _isSending
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : const Text('Gönder'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _sendComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() {
      _isSending = true;
    });

    final success = await _commentsService.addComment(
      movieId: widget.movieId,
      username: 'Kullanıcı', // TODO: Gerçek kullanıcı adını al
      rating: _selectedRating,
      comment: _commentController.text.trim(),
      isSpoiler: _isSpoiler,
    );

    setState(() {
      _isSending = false;
    });

    if (success) {
      // Form'u temizle
      _commentController.clear();
      setState(() {
        _isSpoiler = false;
        _selectedRating = 5;
      });

      // Yorumları yenile
      await _loadComments();

      // Başarı mesajı
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Yorumunuz kaydedildi!')));
    } else {
      // Hata mesajı
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yorum kaydedilemedi. Tekrar deneyin.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Spoiler özellikli yorum kartı
class _SpoilerCommentCard extends StatefulWidget {
  final String username;
  final int rating;
  final String comment;
  final String date;
  final bool isSpoiler;

  const _SpoilerCommentCard({
    required this.username,
    required this.rating,
    required this.comment,
    required this.date,
    required this.isSpoiler,
  });

  @override
  State<_SpoilerCommentCard> createState() => _SpoilerCommentCardState();
}

class _SpoilerCommentCardState extends State<_SpoilerCommentCard> {
  bool _isRevealed = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppTheme.lightGrey,
        border: Border.all(
          color:
              widget.isSpoiler && !_isRevealed
                  ? AppTheme.primaryRed.withOpacity(0.3)
                  : AppTheme.secondaryGrey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kullanıcı bilgisi ve rating
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryRed,
                radius: 20,
                child: Text(
                  widget.username.substring(0, 1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.username,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppTheme.darkGrey,
                          ),
                        ),
                        if (widget.isSpoiler) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryRed,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'SPOILER',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (index) => Icon(
                            index < (widget.rating / 2)
                                ? Icons.star
                                : Icons.star_border,
                            size: 16,
                            color: Colors.amber,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.rating}/10',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryRed,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          widget.date,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.secondaryGrey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Yorum metni (spoiler kontrolü ile)
          if (widget.isSpoiler && !_isRevealed)
            GestureDetector(
              onTap: () {
                setState(() {
                  _isRevealed = true;
                });
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.primaryRed),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.visibility_off,
                      color: AppTheme.primaryRed,
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bu yorum spoiler içeriyor\nGörmek için tıklayın',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.darkGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Text(
              widget.comment,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.darkGrey,
                height: 1.4,
              ),
            ),
        ],
      ),
    );
  }
}
