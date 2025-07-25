import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/movie.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import '../widgets/movie_detail_modal.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class PublicProfileView extends StatefulWidget {
  final String username;

  const PublicProfileView({Key? key, required this.username}) : super(key: key);

  @override
  State<PublicProfileView> createState() => _PublicProfileViewState();
}

class _PublicProfileViewState extends State<PublicProfileView>
    with TickerProviderStateMixin {
  final ProfileService _profileService = ProfileService();

  UserProfile? _userProfile;
  List<Map<String, dynamic>> _userComments = [];
  List<Movie> _userWatchlist = [];
  List<Movie> _userFavorites = []; // Favoriler listesi ekleyelim
  bool _isLoading = true;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // 3 tab olacak
    _loadUserProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);

    try {
      // Kullanıcı profilini yükle
      final userProfile = await _profileService.getUserProfileByUsername(
        widget.username,
      );

      if (userProfile == null) {
        _showErrorAndGoBack('Kullanıcı bulunamadı');
        return;
      }

      // Yorumları yükle (eğer public ise)
      List<Map<String, dynamic>> comments = [];
      if (userProfile.isCommentsPublic) {
        comments = await _profileService.getUserPublicComments(widget.username);
      }

      // Watchlist'i yükle (eğer public ise)
      List<Movie> watchlist = [];
      if (userProfile.isWatchlistPublic) {
        watchlist = await _profileService.getUserPublicWatchlist(
          widget.username,
        );
      }

      // Favoriler'i yükle (eğer public ise)
      List<Movie> favorites = [];
      if (userProfile.isFavoritesPublic) {
        // Bu field'ı User Profile'a eklemek gerekecek
        favorites = await _profileService.getUserPublicFavorites(
          widget.username,
        );
      }

      setState(() {
        _userProfile = userProfile;
        _userComments = comments;
        _userWatchlist = watchlist;
        _userFavorites = favorites;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading public profile: $e');
      _showErrorAndGoBack('Profil yüklenirken hata oluştu');
    }
  }

  void _showErrorAndGoBack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Profil Yükleniyor...'),
          backgroundColor: AppTheme.primaryRed,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_userProfile == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Kullanıcı Bulunamadı'),
          backgroundColor: AppTheme.primaryRed,
        ),
        body: const Center(child: Text('Bu kullanıcı mevcut değil.')),
      );
    }

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 300,
              floating: false,
              pinned: true,
              backgroundColor: AppTheme.primaryRed,
              flexibleSpace: FlexibleSpaceBar(
                background: _buildProfileHeader(),
              ),
              bottom: TabBar(
                controller: _tabController,
                tabs: [
                  Tab(
                    icon: Icon(Icons.comment),
                    text: 'Yorumlar (${_userComments.length})',
                  ),
                  Tab(
                    icon: Icon(Icons.movie),
                    text: 'İzleme Listesi (${_userWatchlist.length})',
                  ),
                  Tab(
                    icon: Icon(Icons.favorite),
                    text: 'Favoriler (${_userFavorites.length})',
                  ),
                ],
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildCommentsTab(),
            _buildWatchlistTab(),
            _buildFavoritesTab(), // Yeni tab
          ],
        ),
      ),
    );
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
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Profil fotoğrafı
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white,
                backgroundImage:
                    _userProfile!.profilePictureURL.isNotEmpty
                        ? NetworkImage(_userProfile!.profilePictureURL)
                        : null,
                child:
                    _userProfile!.profilePictureURL.isEmpty
                        ? Text(
                          _userProfile!.username.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryRed,
                          ),
                        )
                        : null,
              ),
              const SizedBox(height: 16),

              // Kullanıcı adı
              Text(
                _userProfile!.username,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 8),

              // Display name (eğer farklıysa)
              if (_userProfile!.displayName.isNotEmpty &&
                  _userProfile!.displayName != _userProfile!.username)
                Text(
                  _userProfile!.displayName,
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),

              const SizedBox(height: 16),

              // İstatistikler - 3 kart olacak
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatCard('Yorum', _userComments.length.toString()),
                  _buildStatCard('Film', _userWatchlist.length.toString()),
                  _buildStatCard('Favori', _userFavorites.length.toString()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsTab() {
    if (!_userProfile!.isCommentsPublic) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Bu kullanıcının yorumları gizli',
                style: TextStyle(fontSize: 18, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_userComments.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.comment_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Henüz yorum yapılmamış',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _userComments.length,
      itemBuilder: (context, index) {
        final comment = _userComments[index];
        final movie = comment['movie'] as Movie?;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (movie != null) ...[
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 75,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image:
                              movie.posterUrl.isNotEmpty
                                  ? DecorationImage(
                                    image: NetworkImage(movie.posterUrl),
                                    fit: BoxFit.cover,
                                  )
                                  : null,
                          color: movie.posterUrl.isEmpty ? Colors.grey : null,
                        ),
                        child:
                            movie.posterUrl.isEmpty
                                ? const Icon(Icons.movie, color: Colors.white)
                                : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              movie.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                ...List.generate(
                                  5,
                                  (starIndex) => Icon(
                                    starIndex < (comment['rating'] / 2)
                                        ? Icons.star
                                        : Icons.star_border,
                                    size: 16,
                                    color: Colors.amber,
                                  ),
                                ),
                                const SizedBox(width: 8),
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
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/comments',
                            arguments: {'movieId': movie.id, 'movie': movie},
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Yorumları Gör',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.primaryRed,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                // Yorum metni
                if (comment['isSpoiler']) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.primaryRed.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.visibility_off,
                          color: AppTheme.primaryRed,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Bu yorum spoiler içeriyor',
                          style: TextStyle(
                            color: AppTheme.primaryRed,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Text(
                    comment['comment'],
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                ],

                const SizedBox(height: 8),

                // Tarih ve dil
                Row(
                  children: [
                    Text(
                      comment['date'],
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.secondaryGrey,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryGrey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getLanguageFlag(comment['language'] ?? 'TR'),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWatchlistTab() {
    if (!_userProfile!.isWatchlistPublic) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Bu kullanıcının izleme listesi gizli',
                style: TextStyle(fontSize: 18, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_userWatchlist.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.movie_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'İzleme listesi boş',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _userWatchlist.length,
      itemBuilder: (context, index) {
        final movie = _userWatchlist[index];

        return GestureDetector(
          onTap: () {
            _showMovieDetails(movie);
          },
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      image:
                          movie.posterUrl.isNotEmpty
                              ? DecorationImage(
                                image: NetworkImage(movie.posterUrl),
                                fit: BoxFit.cover,
                              )
                              : null,
                      color: movie.posterUrl.isEmpty ? Colors.grey : null,
                    ),
                    child:
                        movie.posterUrl.isEmpty
                            ? const Center(
                              child: Icon(
                                Icons.movie,
                                size: 50,
                                color: Colors.white,
                              ),
                            )
                            : null,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          movie.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          movie.year.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.secondaryGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFavoritesTab() {
    if (!_userProfile!.isFavoritesPublic) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Bu kullanıcının favorileri gizli',
                style: TextStyle(fontSize: 18, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_userFavorites.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Favori film yok',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _userFavorites.length,
      itemBuilder: (context, index) {
        final movie = _userFavorites[index];

        return GestureDetector(
          onTap: () {
            _showMovieDetails(movie);
          },
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      image:
                          movie.posterUrl.isNotEmpty
                              ? DecorationImage(
                                image: NetworkImage(movie.posterUrl),
                                fit: BoxFit.cover,
                              )
                              : null,
                      color: movie.posterUrl.isEmpty ? Colors.grey : null,
                    ),
                    child:
                        movie.posterUrl.isEmpty
                            ? const Center(
                              child: Icon(
                                Icons.movie,
                                size: 50,
                                color: Colors.white,
                              ),
                            )
                            : null,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                movie.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(
                              Icons.favorite,
                              size: 16,
                              color: AppTheme.primaryRed,
                            ),
                          ],
                        ),
                        Text(
                          movie.year.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.secondaryGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
}
