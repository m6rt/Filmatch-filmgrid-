import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/movie.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final ProfileService _profileService = ProfileService();

  UserProfile? _userProfile;
  List<Movie> _favoriteMovies = [];
  bool _isLoading = true;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      final profile = await _profileService.getUserProfile();
      if (profile != null) {
        setState(() {
          _userProfile = profile;
        });

        if (profile.favoriteMovieIds.isNotEmpty) {
          final movies = await _profileService.getFavoriteMovies(
            profile.favoriteMovieIds,
          );
          setState(() => _favoriteMovies = movies);
        }
      }
    } catch (e) {
      _showErrorSnackBar('Profil yüklenirken hata oluştu');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfileImage() async {
    if (_userProfile == null) return;

    setState(() => _isUpdating = true);

    try {
      final imageUrl = await _profileService.pickAndUploadProfileImage();
      if (imageUrl != null) {
        final updatedProfile = _userProfile!.copyWith(
          profileImageUrl: imageUrl,
        );

        final success = await _profileService.updateProfile(updatedProfile);
        if (success) {
          setState(() => _userProfile = updatedProfile);
          _showSuccessSnackBar('Profil fotoğrafı güncellendi');
        } else {
          _showErrorSnackBar('Profil fotoğrafı güncellenemedi');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Profil fotoğrafı yüklenirken hata oluştu');
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.lightGrey,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryRed),
        ),
      );
    }

    if (_userProfile == null) {
      return Scaffold(
        backgroundColor: AppTheme.lightGrey,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppTheme.secondaryGrey,
              ),
              const SizedBox(height: 16),
              Text(
                'Profil yüklenemedi',
                style: TextStyle(fontSize: 18, color: AppTheme.darkGrey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRed,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Profil',
          style: TextStyle(
            color: AppTheme.darkGrey,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [],
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final isSmallScreen = screenWidth < 600;
            final padding = isSmallScreen ? 16.0 : 24.0;

            return SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: Column(
                children: [
                  // Profil Fotoğrafı
                  _buildProfileImage(isSmallScreen),

                  SizedBox(height: isSmallScreen ? 12 : 16),

                  // Kullanıcı Bilgileri
                  _buildUserInfo(isSmallScreen),

                  SizedBox(height: isSmallScreen ? 20 : 24),

                  // Favori Filmler
                  _buildFavoriteMovies(isSmallScreen),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileImage(bool isSmallScreen) {
    final imageSize = isSmallScreen ? 100.0 : 120.0;
    final buttonSize = isSmallScreen ? 32.0 : 36.0;
    final iconSize = isSmallScreen ? 16.0 : 20.0;

    return Stack(
      children: [
        Container(
          width: imageSize,
          height: imageSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.primaryRed, width: 3),
          ),
          child: ClipOval(
            child:
                _userProfile!.profileImageUrl != null
                    ? Image.network(
                      _userProfile!.profileImageUrl!,
                      fit: BoxFit.cover,
                      width: imageSize,
                      height: imageSize,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const CircularProgressIndicator();
                      },
                      errorBuilder:
                          (context, error, stackTrace) =>
                              _buildDefaultAvatar(isSmallScreen),
                    )
                    : _buildDefaultAvatar(isSmallScreen),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _isUpdating ? null : _updateProfileImage,
            child: Container(
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                color: AppTheme.primaryRed,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child:
                  _isUpdating
                      ? SizedBox(
                        width: iconSize,
                        height: iconSize,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: iconSize,
                      ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultAvatar(bool isSmallScreen) {
    final avatarIconSize = isSmallScreen ? 50.0 : 60.0;
    return Container(
      color: AppTheme.secondaryGrey,
      child: Icon(Icons.person, size: avatarIconSize, color: Colors.white),
    );
  }

  Widget _buildUserInfo(bool isSmallScreen) {
    final titleFontSize = isSmallScreen ? 20.0 : 24.0;
    final emailFontSize = isSmallScreen ? 14.0 : 16.0;
    final dateFontSize = isSmallScreen ? 12.0 : 14.0;
    final spacing = isSmallScreen ? 6.0 : 8.0;

    return Column(
      children: [
        Text(
          _userProfile!.username,
          style: TextStyle(
            color: AppTheme.darkGrey,
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: spacing),

        Text(
          _userProfile!.email,
          style: TextStyle(
            color: AppTheme.secondaryGrey,
            fontSize: emailFontSize,
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: isSmallScreen ? 12.0 : 16.0),

        Text(
          'Üye olma tarihi: ${_formatDate(_userProfile!.createdAt)}',
          style: TextStyle(
            color: AppTheme.secondaryGrey,
            fontSize: dateFontSize,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFavoriteMovies(bool isSmallScreen) {
    final titleFontSize = isSmallScreen ? 18.0 : 20.0;
    final cardHeight = isSmallScreen ? 130.0 : 150.0;
    final spacing = isSmallScreen ? 12.0 : 16.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Favori Filmler',
          style: TextStyle(
            color: AppTheme.darkGrey,
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),

        SizedBox(height: spacing),

        SizedBox(
          height: cardHeight,
          child:
              _favoriteMovies.isEmpty
                  ? _buildEmptyFavorites(isSmallScreen)
                  : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 3,
                    itemBuilder: (context, index) {
                      if (index < _favoriteMovies.length) {
                        return _buildFavoriteMovieCard(
                          _favoriteMovies[index],
                          isSmallScreen,
                        );
                      } else {
                        return _buildAddFavoriteCard(isSmallScreen);
                      }
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildEmptyFavorites(bool isSmallScreen) {
    final iconSize = isSmallScreen ? 40.0 : 48.0;
    final fontSize = isSmallScreen ? 14.0 : 16.0;
    final spacing = isSmallScreen ? 6.0 : 8.0;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.movie_outlined,
            size: iconSize,
            color: AppTheme.secondaryGrey,
          ),
          SizedBox(height: spacing),
          Text(
            'Henüz favori film yok',
            style: TextStyle(color: AppTheme.secondaryGrey, fontSize: fontSize),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: spacing),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/swipe');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Film Keşfet',
              style: TextStyle(fontSize: isSmallScreen ? 12.0 : 14.0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteMovieCard(Movie movie, bool isSmallScreen) {
    final cardWidth = isSmallScreen ? 80.0 : 100.0;
    final margin = isSmallScreen ? 8.0 : 12.0;
    final fontSize = isSmallScreen ? 10.0 : 12.0;
    final spacing = isSmallScreen ? 6.0 : 8.0;

    return Container(
      width: cardWidth,
      margin: EdgeInsets.only(right: margin),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child:
                  movie.posterUrl.isNotEmpty
                      ? Image.network(
                        movie.posterUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: AppTheme.secondaryGrey,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.primaryRed,
                              ),
                            ),
                          );
                        },
                        errorBuilder:
                            (context, error, stackTrace) => Container(
                              color: AppTheme.secondaryGrey,
                              child: Icon(Icons.movie, color: Colors.white),
                            ),
                      )
                      : Container(
                        color: AppTheme.secondaryGrey,
                        child: Icon(Icons.movie, color: Colors.white),
                      ),
            ),
          ),
          SizedBox(height: spacing),
          Text(
            movie.title,
            style: TextStyle(
              color: AppTheme.darkGrey,
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAddFavoriteCard(bool isSmallScreen) {
    final cardWidth = isSmallScreen ? 80.0 : 100.0;
    final margin = isSmallScreen ? 8.0 : 12.0;
    final iconSize = isSmallScreen ? 24.0 : 32.0;
    final fontSize = isSmallScreen ? 10.0 : 12.0;
    final spacing = isSmallScreen ? 6.0 : 8.0;

    return Container(
      width: cardWidth,
      margin: EdgeInsets.only(right: margin),
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, '/swipe');
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.primaryRed, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: iconSize, color: AppTheme.primaryRed),
              SizedBox(height: spacing),
              Text(
                'Film Ekle',
                style: TextStyle(
                  color: AppTheme.primaryRed,
                  fontSize: fontSize,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
