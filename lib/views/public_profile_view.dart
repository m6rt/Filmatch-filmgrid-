import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Bu import'u ekleyelim
import 'dart:convert'; // Bu import'u da ekleyelim
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import '../models/movie.dart';
import '../services/profile_service.dart';
import '../services/comments_service.dart';
import '../theme/app_theme.dart';
import '../widgets/movie_detail_modal.dart';

class PublicProfileView extends StatefulWidget {
  final String? username;
  final UserProfile? user;

  const PublicProfileView({Key? key, this.username, this.user})
    : super(key: key);

  @override
  State<PublicProfileView> createState() => _PublicProfileViewState();
}

class _PublicProfileViewState extends State<PublicProfileView> {
  final ProfileService _profileService = ProfileService();
  final CommentsService _commentsService = CommentsService();

  UserProfile? _userProfile;
  List<Movie> _userFavorites = [];
  List<Movie> _userWatchlist = [];
  List<Map<String, dynamic>> _userComments = [];
  bool _isLoading = true;
  String? _error;
  String _currentUsername = '';

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _loadUserData();
  }

  Future<void> _getCurrentUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        if (doc.exists && doc.data()?['username'] != null) {
          setState(() {
            _currentUsername = doc.data()!['username'];
          });
        }
      }
    } catch (e) {
      print('Error getting current user: $e');
    }
  }

  // Eksik metodu ekleyelim
  Future<void> _loadUserProfile() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    String? targetUsername;

    if (args is String) {
      targetUsername = args;
    } else if (args is Map<String, dynamic>) {
      targetUsername = args['username'] as String?;
    }

    if (targetUsername != null) {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      try {
        final userProfile = await _profileService.getUserProfileByUsername(
          targetUsername,
        );
        if (userProfile != null) {
          setState(() {
            _userProfile = userProfile;
          });
          await _loadUserData();
        } else {
          setState(() {
            _error = 'Kullanıcı bulunamadı';
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _error = 'Kullanıcı yüklenirken hata oluştu: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadUserData() async {
    if (_userProfile == null) {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      try {
        UserProfile? userProfile;

        if (widget.user != null) {
          userProfile = widget.user;
        } else if (widget.username != null) {
          userProfile = await _profileService.getUserProfileByUsername(
            widget.username!,
          );
        }

        if (userProfile == null) {
          setState(() {
            _error = 'Kullanıcı bulunamadı';
            _isLoading = false;
          });
          return;
        }

        setState(() {
          _userProfile = userProfile;
        });
      } catch (e) {
        setState(() {
          _error = 'Veri yüklenirken hata oluştu: $e';
          _isLoading = false;
        });
        return;
      }
    }

    try {
      // Favori filmleri yükle
      List<Movie> favorites = [];
      if (_userProfile!.isFavoritesPublic &&
          _userProfile!.favoriteMovies.isNotEmpty) {
        favorites = await _profileService.getMoviesByIds(
          _userProfile!.favoriteMovies,
        );
      }

      // İzleme listesini yükle
      List<Movie> watchlist = [];
      if (_userProfile!.watchlist.isNotEmpty) {
        watchlist = await _profileService.getMoviesByIds(
          _userProfile!.watchlist,
        );
      }

      // Kullanıcının yorumlarını film bilgileriyle birlikte yükle
      final comments = await _commentsService.getUserCommentsWithLikes(
        _userProfile!.username,
        _currentUsername.isNotEmpty ? _currentUsername : null,
      );

      // Her yorum için film bilgisini yükle
      final enrichedComments = await Future.wait(
        comments.map((comment) async {
          try {
            final movieId = comment['movieId'] as int;
            final movie = await _getMovieById(movieId);
            comment['movie'] = movie;
          } catch (e) {
            print('Error loading movie for comment: $e');
            comment['movie'] = null;
          }
          return comment;
        }).toList(),
      );

      setState(() {
        _userFavorites = favorites;
        _userWatchlist = watchlist;
        _userComments = enrichedComments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Veri yüklenirken hata oluştu: $e';
        _isLoading = false;
      });
    }
  }

  // Film bilgisini JSON'dan getir
  Future<Movie?> _getMovieById(int movieId) async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/movies_database.json',
      );
      final List<dynamic> jsonList = json.decode(jsonString);

      final movieJson = jsonList.firstWhere(
        (json) => json['id'] == movieId,
        orElse: () => null,
      );

      if (movieJson != null) {
        return Movie.fromJson(movieJson);
      }
      return null;
    } catch (e) {
      print('Error getting movie by id: $e');
      return null;
    }
  }

  void _showMovieDetails(Movie movie) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (context) => MovieDetailModal(
            movie: movie,
            profileService: _profileService,
            onAddToFavorites: (movie) => _addToFavorites(movie),
            onAddToWatchlist: (movie) => _addToWatchlist(movie),
            showActionButtons: false, // Public profile'da butonları gizle
          ),
    );
  }

  Future<void> _addToFavorites(Movie movie) async {
    try {
      await _profileService.addFavoriteMovie(movie.id.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${movie.title} favorilere eklendi'),
          backgroundColor: AppTheme.primaryRed,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Favorilere eklenirken hata oluştu'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addToWatchlist(Movie movie) async {
    try {
      await _profileService.addToWatchlist(movie.id.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${movie.title} listeye eklendi'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Listeye eklenirken hata oluştu'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildProfileHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.primaryRed, AppTheme.primaryRed.withOpacity(0.8)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // AppBar benzeri üst kısım
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      _userProfile!.username,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(
                    width: 48,
                  ), // IconButton genişliği kadar boşluk
                ],
              ),
            ),

            // Profil içeriği
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  // Profil fotoğrafı
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    backgroundImage:
                        _userProfile!.profileImageUrl.isNotEmpty
                            ? NetworkImage(_userProfile!.profileImageUrl)
                            : null,
                    child:
                        _userProfile!.profileImageUrl.isEmpty
                            ? Text(
                              _userProfile!.username
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryRed,
                              ),
                            )
                            : null,
                  ),
                  const SizedBox(height: 16),

                  // Full name (eğer farklıysa)
                  if (_userProfile!.fullName.isNotEmpty &&
                      _userProfile!.fullName != _userProfile!.username)
                    Text(
                      _userProfile!.fullName,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),

                  // Bio (varsa) - Güncellenmiş UI
                  if (_userProfile!.bio.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.25),
                            Colors.white.withOpacity(0.15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.4),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.person_outline,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Hakkında',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  fontFamily: "PlayfairDisplay",
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _userProfile!.bio,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.white,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // İstatistikler
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatCard(
                        'Favoriler',
                        _userFavorites.length.toString(),
                      ),
                      _buildStatCard(
                        'İzleme Listesi',
                        _userWatchlist.length.toString(),
                      ),
                      _buildStatCard(
                        'Yorumlar',
                        _userComments.length.toString(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Route arguments'ını al
    if (_userProfile == null &&
        widget.username == null &&
        widget.user == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        // Arguments Map olarak geldi
        final username = args['username'] as String?;
        final user = args['user'] as UserProfile?;

        if (user != null) {
          _userProfile = user;
        } else if (username != null) {
          // Username ile profil yükle
          _loadUserProfile();
        }
      } else if (args is String) {
        // Arguments String olarak geldi (eski versiyon)
        _loadUserProfile();
      }
    }

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.primaryRed,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppTheme.primaryRed,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.white.withOpacity(0.7),
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      body: Column(
        children: [
          _buildProfileHeader(),
          Expanded(
            child: DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  Container(
                    color: Colors.white,
                    child: TabBar(
                      labelColor: AppTheme.primaryRed,
                      unselectedLabelColor: AppTheme.secondaryGrey,
                      indicatorColor: AppTheme.primaryRed,
                      tabs: const [
                        Tab(text: 'Favoriler'),
                        Tab(text: 'İzleme Listesi'),
                        Tab(text: 'Yorumlar'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildMoviesGrid(_userFavorites),
                        _buildMoviesGrid(_userWatchlist),
                        _buildCommentsTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoviesGrid(List<Movie> movies) {
    if (movies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.movie_outlined, size: 64, color: AppTheme.secondaryGrey),
            const SizedBox(height: 16),
            Text(
              'Henüz film yok',
              style: TextStyle(fontSize: 16, color: AppTheme.secondaryGrey),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: movies.length,
      itemBuilder: (context, index) {
        final movie = movies[index];
        return GestureDetector(
          onTap: () => _showMovieDetails(movie),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child:
                  movie.posterUrl.isNotEmpty
                      ? Image.network(
                        movie.posterUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppTheme.getGenreColor(
                              movie.genre.isNotEmpty
                                  ? movie.genre.first
                                  : 'Unknown',
                            ),
                            child: const Icon(
                              Icons.movie,
                              color: Colors.white,
                              size: 40,
                            ),
                          );
                        },
                      )
                      : Container(
                        color: AppTheme.getGenreColor(
                          movie.genre.isNotEmpty
                              ? movie.genre.first
                              : 'Unknown',
                        ),
                        child: const Icon(
                          Icons.movie,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCommentsTab() {
    if (_userComments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.comment_outlined,
              size: 64,
              color: AppTheme.secondaryGrey,
            ),
            SizedBox(height: 16),
            Text(
              'Henüz yorum yapılmamış',
              style: TextStyle(
                fontSize: 18,
                color: AppTheme.secondaryGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Bu kullanıcı henüz hiçbir filme yorum yapmamış',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppTheme.secondaryGrey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _userComments.length,
      itemBuilder: (context, index) {
        final comment = _userComments[index];
        return _buildCommentCard(comment);
      },
    );
  }

  Widget _buildCommentCard(Map<String, dynamic> comment) {
    final Movie? movie = comment['movie'] as Movie?;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Film bilgisi ve rating - tıklanabilir
            GestureDetector(
              onTap: movie != null ? () => _showMovieDetails(movie) : null,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.primaryRed.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Film posteri (küçük)
                    if (movie?.posterUrl.isNotEmpty == true)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          movie!.posterUrl,
                          width: 40,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 40,
                              height: 60,
                              color: AppTheme.primaryRed,
                              child: Icon(
                                Icons.movie,
                                color: Colors.white,
                                size: 20,
                              ),
                            );
                          },
                        ),
                      )
                    else
                      Container(
                        width: 40,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryRed,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(Icons.movie, color: Colors.white, size: 20),
                      ),

                    SizedBox(width: 12),

                    // Film adı ve yıl
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            movie?.title ?? 'Film bulunamadı',
                            style: TextStyle(
                               fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkGrey,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          // BURADA releaseDate KISMI KALDIRILDI
                          SizedBox(height: 8),
                          // Rating
                          Row(
                            children: [
                              ...List.generate(
                                5,
                                (index) => Icon(
                                  index < (comment['rating'] / 2)
                                      ? Icons.star
                                      : Icons.star_border,
                                  size: 16,
                                  color: Colors.amber,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                '${comment['rating']}/10',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryRed,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Tıklanabilir göstergesi
                    if (movie != null)
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: AppTheme.primaryRed,
                      ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 12),

            // Yorum metni
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    comment['isSpoiler']
                        ? AppTheme.primaryRed.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border:
                    comment['isSpoiler']
                        ? Border.all(
                          color: AppTheme.primaryRed.withOpacity(0.3),
                        )
                        : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (comment['isSpoiler'])
                    Row(
                      children: [
                        Icon(
                          Icons.warning,
                          size: 16,
                          color: AppTheme.primaryRed,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'SPOILER',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryRed,
                          ),
                        ),
                      ],
                    ),
                  if (comment['isSpoiler']) SizedBox(height: 8),
                  Text(
                    comment['comment'],
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.darkGrey,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 12),

            // Alt bilgiler
            Row(
              children: [
                // Dil
                Text(
                  _getLanguageFlag(comment['language']),
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(width: 8),
                Text(
                  comment['date'],
                  style: TextStyle(fontSize: 12, color: AppTheme.secondaryGrey),
                ),
                Spacer(),
                // Beğeni sayısı
                if (comment['likesCount'] > 0)
                  Row(
                    children: [
                      Icon(
                        Icons.favorite,
                        size: 16,
                        color: AppTheme.primaryRed,
                      ),
                      SizedBox(width: 4),
                      Text(
                        comment['likesCount'].toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryRed,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

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
}
