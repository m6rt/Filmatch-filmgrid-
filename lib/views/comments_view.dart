import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../theme/app_theme.dart';
import '../services/comments_service.dart';

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
  String _selectedLanguage = 'TR'; // Varsayılan dil
  final TextEditingController _commentController = TextEditingController();

  // Service ve state
  final CommentsService _commentsService = CommentsService();
  final String _currentUsername =
      'Kullanıcı'; // TODO: Gerçek kullanıcı adını al

  List<Map<String, dynamic>> _comments = [];
  Map<String, dynamic>? _userComment; // Kullanıcının mevcut yorumu
  bool _isLoading = true;
  bool _isSending = false;
  bool _isEditMode = false;

  // Dil seçenekleri
  final Map<String, String> _languages = {
    'TR': '🇹🇷 Türkçe',
    'EN': '🇺🇸 English',
    'DE': '🇩🇪 Deutsch',
    'FR': '🇫🇷 Français',
    'ES': '🇪🇸 Español',
    'IT': '🇮🇹 Italiano',
    'RU': '🇷🇺 Русский',
    'JA': '🇯🇵 日本語',
    'KO': '🇰🇷 한국어',
    'ZH': '🇨🇳 中文',
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Tüm yorumları yükle
      final comments = await _commentsService.getComments(widget.movieId);

      // Kullanıcının yorumunu kontrol et
      final userComment = await _commentsService.getUserComment(
        widget.movieId,
        _currentUsername,
      );

      setState(() {
        _comments = comments;
        _userComment = userComment;
        _isLoading = false;

        // Eğer kullanıcının yorumu varsa form'u doldur
        if (userComment != null) {
          _commentController.text = userComment['comment'];
          _selectedRating = userComment['rating'];
          _isSpoiler = userComment['isSpoiler'];
          // Eğer dil bilgisi varsa, onu da yükle
          _selectedLanguage = userComment['language'] ?? 'TR';
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Yorumlar yüklenemedi: $e', isError: true);
    }
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
                      onRefresh: _loadData,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          // Film bilgisi
                          if (widget.movie != null) _buildMovieInfo(),

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
                            _buildEmptyComments()
                          else
                            ..._comments.map(
                              (comment) => Column(
                                children: [
                                  _buildCommentCard(comment),
                                  const SizedBox(height: 12),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
          ),

          // Yorum yap/düzenle formu (sadece yorum yoksa veya edit modeysa)
          if (_userComment == null || _isEditMode) _buildCommentForm(),
        ],
      ),
    );
  }

  Widget _buildMovieInfo() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Film posteri
        Container(
          width: 100,
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image:
                widget.movie!.posterUrl.isNotEmpty
                    ? DecorationImage(
                      image: NetworkImage(widget.movie!.posterUrl),
                      fit: BoxFit.cover,
                    )
                    : null,
            color: widget.movie!.posterUrl.isEmpty ? Colors.grey : null,
          ),
          child:
              widget.movie!.posterUrl.isEmpty
                  ? const Icon(Icons.movie, size: 50, color: Colors.white)
                  : null,
        ),
        const SizedBox(width: 16),
        // Film bilgileri
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                style: TextStyle(fontSize: 14, color: AppTheme.secondaryGrey),
              ),
              const SizedBox(height: 8),
              Text(
                'Yönetmen: ${widget.movie!.director}',
                style: TextStyle(fontSize: 14, color: AppTheme.darkGrey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyComments() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.comment_outlined, size: 48, color: AppTheme.secondaryGrey),
          const SizedBox(height: 16),
          Text(
            _userComment != null
                ? 'Başka kullanıcı yorumu bulunmuyor.'
                : 'Henüz yorum yapılmamış.\nİlk yorumu siz yapın!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: AppTheme.secondaryGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentCard(Map<String, dynamic> comment) {
    final isCurrentUser = comment['username'] == _currentUsername;

    return _SpoilerCommentCard(
      username: comment['username'],
      rating: comment['rating'],
      comment: comment['comment'],
      date: comment['date'],
      isSpoiler: comment['isSpoiler'],
      isCurrentUser: isCurrentUser,
      language: comment['language'] ?? 'TR',
      onEdit: isCurrentUser ? _enterEditMode : null,
      onDelete: isCurrentUser ? _showDeleteDialog : null,
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
          Row(
            children: [
              Text(
                _isEditMode
                    ? 'Yorumunuzu düzenleyin:'
                    : 'Film hakkında düşündüklerinizi yazın:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.darkGrey,
                ),
              ),
              if (_isEditMode) ...[
                const Spacer(),
                TextButton(onPressed: _cancelEdit, child: const Text('İptal')),
              ],
            ],
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

          // İlk satır: Spoiler ve Puan
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

              // Puan seçici
              Expanded(
                child: Row(
                  children: [
                    const Text('Puan:'),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButton<int>(
                        value: _selectedRating,
                        isExpanded: true,
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
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // İkinci satır: Dil ve Gönder butonu
          Row(
            children: [
              // Dil seçici
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.language,
                      size: 18,
                      color: AppTheme.secondaryGrey,
                    ),
                    const SizedBox(width: 8),
                    const Text('Dil:'),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedLanguage,
                        isExpanded: true,
                        items:
                            _languages.entries
                                .map(
                                  (entry) => DropdownMenuItem(
                                    value: entry.key,
                                    child: Text(
                                      entry.value,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            _isSending
                                ? null
                                : (value) {
                                  setState(() {
                                    _selectedLanguage = value ?? 'TR';
                                  });
                                },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Gönder butonu
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
                        : Text(_isEditMode ? 'Güncelle' : 'Gönder'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _enterEditMode() {
    setState(() {
      _isEditMode = true;
      if (_userComment != null) {
        _commentController.text = _userComment!['comment'];
        _selectedRating = _userComment!['rating'];
        _isSpoiler = _userComment!['isSpoiler'];
        _selectedLanguage = _userComment!['language'] ?? 'TR';
      }
    });
  }

  void _cancelEdit() {
    setState(() {
      _isEditMode = false;
      _commentController.clear();
      _selectedRating = 5;
      _isSpoiler = false;
      _selectedLanguage = 'TR';
    });
  }

  Future<void> _sendComment() async {
    if (_commentController.text.trim().isEmpty) {
      _showSnackBar('Lütfen yorum yazın', isError: true);
      return;
    }

    setState(() => _isSending = true);

    try {
      bool success;

      if (_isEditMode && _userComment != null) {
        // Yorumu güncelle
        success = await _commentsService.updateComment(
          movieId: widget.movieId,
          username: _currentUsername,
          rating: _selectedRating,
          comment: _commentController.text.trim(),
          isSpoiler: _isSpoiler,
          language: _selectedLanguage,
        );
      } else {
        // Yeni yorum ekle
        success = await _commentsService.addComment(
          movieId: widget.movieId,
          username: _currentUsername,
          rating: _selectedRating,
          comment: _commentController.text.trim(),
          isSpoiler: _isSpoiler,
          language: _selectedLanguage,
        );
      }

      if (success) {
        _showSnackBar(
          _isEditMode ? 'Yorumunuz güncellendi!' : 'Yorumunuz kaydedildi!',
        );

        // Form'u temizle
        _commentController.clear();
        setState(() {
          _isSpoiler = false;
          _selectedRating = 5;
          _selectedLanguage = 'TR';
          _isEditMode = false;
        });

        // Verileri yenile
        await _loadData();
      }
    } catch (e) {
      _showSnackBar(e.toString(), isError: true);
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _showDeleteDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Yorumu Sil'),
            content: const Text(
              'Bu yorumu silmek istediğinizden emin misiniz?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('İptal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Sil'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      final success = await _commentsService.deleteUserComment(
        widget.movieId,
        _currentUsername,
      );

      if (success) {
        _showSnackBar('Yorumunuz silindi');
        await _loadData();
      } else {
        _showSnackBar('Yorum silinirken hata oluştu', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
}

// Spoiler özellikli yorum kartı - language parametresi eklendi
class _SpoilerCommentCard extends StatefulWidget {
  final String username;
  final int rating;
  final String comment;
  final String date;
  final bool isSpoiler;
  final bool isCurrentUser;
  final String language;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _SpoilerCommentCard({
    required this.username,
    required this.rating,
    required this.comment,
    required this.date,
    required this.isSpoiler,
    required this.isCurrentUser,
    required this.language,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<_SpoilerCommentCard> createState() => _SpoilerCommentCardState();
}

class _SpoilerCommentCardState extends State<_SpoilerCommentCard> {
  bool _isRevealed = false;

  // Dil kodlarını emoji'ye çevir
  String _getLanguageFlag(String langCode) {
    const languageFlags = {
      'TR': '🇹🇷',
      'EN': '🇺🇸',
      'DE': '🇩🇪',
      'FR': '🇫🇷',
      'ES': '🇪🇸',
      'IT': '🇮🇹',
      'RU': '🇷🇺',
      'JA': '🇯🇵',
      'KO': '🇰🇷',
      'ZH': '🇨🇳',
    };
    return languageFlags[langCode] ?? '🌍';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color:
            widget.isCurrentUser
                ? AppTheme.primaryRed.withOpacity(0.05)
                : AppTheme.lightGrey,
        border: Border.all(
          color:
              widget.isCurrentUser
                  ? AppTheme.primaryRed
                  : widget.isSpoiler && !_isRevealed
                  ? AppTheme.primaryRed.withOpacity(0.3)
                  : AppTheme.secondaryGrey.withOpacity(0.3),
          width: widget.isCurrentUser ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kullanıcı bilgisi ve rating
          Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    widget.isCurrentUser
                        ? AppTheme.primaryRed
                        : AppTheme.secondaryGrey,
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
                        if (widget.isCurrentUser) ...[
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
                              'SİZ',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
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
                        const Spacer(),
                        // Edit/Delete butonları (sadece kendi yorumu için)
                        if (widget.isCurrentUser) ...[
                          IconButton(
                            onPressed: widget.onEdit,
                            icon: Icon(
                              Icons.edit,
                              size: 18,
                              color: AppTheme.primaryRed,
                            ),
                            tooltip: 'Yorumu düzenle',
                            visualDensity: VisualDensity.compact,
                          ),
                          IconButton(
                            onPressed: widget.onDelete,
                            icon: const Icon(
                              Icons.delete,
                              size: 18,
                              color: Colors.red,
                            ),
                            tooltip: 'Yorumu sil',
                            visualDensity: VisualDensity.compact,
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
                        const SizedBox(width: 8),
                        // Dil göstergesi
                        Text(
                          _getLanguageFlag(widget.language),
                          style: const TextStyle(fontSize: 14),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.isSpoiler && _isRevealed) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.visibility,
                          color: AppTheme.primaryRed,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Spoiler içeriği gösteriliyor',
                          style: TextStyle(
                            color: AppTheme.primaryRed,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isRevealed = false;
                            });
                          },
                          child: Text(
                            'Gizle',
                            style: TextStyle(
                              color: AppTheme.primaryRed,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
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
        ],
      ),
    );
  }
}
