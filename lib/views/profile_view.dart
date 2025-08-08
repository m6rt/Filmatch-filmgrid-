import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/user_profile.dart';
import '../models/movie.dart';
import '../services/profile_service.dart';
import '../services/auth_service.dart';
import '../services/comments_service.dart';
import '../services/batch_optimized_movie_service.dart';
import '../theme/app_theme.dart';
import '../widgets/movie_detail_modal.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView>
    with WidgetsBindingObserver, RouteAware {
  final ProfileService _profileService = ProfileService();
  final CommentsService _commentsService =
      CommentsService(); // CommentsService ekleyin
  final AuthService _authService = AuthService();

  UserProfile? _userProfile;
  List<Movie> _favoriteMovies = [];
  List<Movie> _watchlistMovies = [];
  List<Map<String, dynamic>> _userComments = []; // Kullanıcı yorumları
  bool _isLoading = true;
  bool _isUpdating = false;
  DateTime? _lastRefresh;
  String _currentUsername = 'Kullanıcı'; // Gerçek kullanıcı adı
  int _followersCount = 0;
  int _followingCount = 0;

  // Profil kurulum için gerekli alanlar
  File? _tempProfilePicture;
  String _newUsername = '';
  final ImagePicker _picker = ImagePicker();
  final firebase_storage.FirebaseStorage _storage =
      firebase_storage.FirebaseStorage.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAndSetupProfile();
  }

  Future<void> _checkAndSetupProfile() async {
    // Önce username var mı kontrol et
    final hasUsername = await _authService.hasUsername();

    if (!hasUsername) {
      // Username yoksa kurulum dialog'unu göster
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showProfileSetupDialog();
      });
    } else {
      // Username varsa normal profil yükleme işlemini yap
      await _getCurrentUser();
      _loadProfile();
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(child: CircularProgressIndicator());
      },
    );
  }

  Future<void> _saveUserCredentials(
    String username,
    File? profilePhoto,
    String uid,
  ) async {
    try {
      String? profileImageURL;

      if (profilePhoto != null) {
        firebase_storage.Reference ref = _storage
            .ref()
            .child('profile_pictures')
            .child('${uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');
        firebase_storage.UploadTask uploadTask = ref.putFile(profilePhoto);
        await uploadTask;
        profileImageURL = await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'profilePictureURL': profileImageURL,
        'username': username.toLowerCase(),
        'dateTime': DateTime.now(),
      });

      Navigator.pop(context); // Loading dialog'unu kapat
      Navigator.pop(context); // Setup dialog'unu kapat

      // Profil kurulduktan sonra normal profil yükleme işlemini yap
      await _getCurrentUser();
      _loadProfile();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Profil başarıyla oluşturuldu!')));
    } catch (e) {
      Navigator.pop(context); // Loading dialog'unu kapat
      print("Profile save error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Bir hata oluştu: $e")));
    }
  }

  Future<void> _showProfileSetupDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'Profil Bilgilerinizi Girin',
                style: TextStyle(
                  fontFamily: "PlayfairDisplay",
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SizedBox(
                height: 250,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Profil fotoğrafı seçici
                      GestureDetector(
                        onTap: () async {
                          try {
                            final XFile? pickedFile = await _picker.pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 50,
                              maxWidth: 800,
                              maxHeight: 800,
                            );
                            if (pickedFile != null) {
                              setState(() {
                                _tempProfilePicture = File(pickedFile.path);
                              });
                            }
                          } catch (e) {
                            print("Image picker error: $e");
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Fotoğraf seçilemedi")),
                            );
                          }
                        },
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.primaryRed),
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            radius: 48,
                            backgroundColor: Colors.grey[100],
                            backgroundImage:
                                _tempProfilePicture != null
                                    ? FileImage(_tempProfilePicture!)
                                    : null,
                            child:
                                _tempProfilePicture == null
                                    ? Icon(
                                      Icons.add_a_photo,
                                      size: 40,
                                      color: AppTheme.primaryRed,
                                    )
                                    : null,
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      // Username girişi
                      TextField(
                        decoration: InputDecoration(
                          labelText: "Kullanıcı Adı",
                          labelStyle: TextStyle(
                            color: AppTheme.secondaryGrey,
                            fontFamily: 'PlayfairDisplay',
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppTheme.primaryRed),
                          ),
                        ),
                        onChanged: (value) {
                          _newUsername = value;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  child: Text(
                    'Kaydet',
                    style: TextStyle(
                      fontFamily: "PlayfairDisplay",
                      color: AppTheme.primaryRed,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lütfen giriş yapın!')),
                      );
                      return;
                    }

                    if (_newUsername.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Lütfen bir kullanıcı adı girin'),
                        ),
                      );
                      return;
                    }

                    if (await _authService.isUsernameTaken(
                      _newUsername.toLowerCase(),
                    )) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Kullanıcı ismi zaten kullanılıyor"),
                        ),
                      );
                      return;
                    }

                    if (_tempProfilePicture == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Lütfen bir profil fotoğrafı seçin"),
                        ),
                      );
                      return;
                    }

                    _showLoadingDialog();
                    await _saveUserCredentials(
                      _newUsername,
                      _tempProfilePicture,
                      user.uid,
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _getCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _getUsernameFromFirestore(user.uid);
    }
  }

  Future<void> _getUsernameFromFirestore(String uid) async {
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (doc.exists && doc.data()?['username'] != null) {
        setState(() {
          _currentUsername = doc.data()!['username'];
        });
      } else {
        // Eğer Firestore'da username yoksa fallback olarak email kullan
        final user = FirebaseAuth.instance.currentUser;
        setState(() {
          _currentUsername = user?.email?.split('@')[0] ?? 'Kullanıcı';
        });
      }
    } catch (e) {
      print('Error getting username from Firestore: $e');
      // Hata durumunda fallback
      final user = FirebaseAuth.instance.currentUser;
      setState(() {
        _currentUsername = user?.email?.split('@')[0] ?? 'Kullanıcı';
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sadece 2 saniyeden fazla süre geçtiyse yenile (çok sık yenilemeyi önler)
    final now = DateTime.now();
    if (_lastRefresh == null || now.difference(_lastRefresh!).inSeconds > 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isLoading) {
          _refreshFollowCounts(); // Sadece takip sayılarını yenile
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      // Uygulama ön plana geçtiğinde profili yenile
      _loadProfile();
    }
  }

  // Takip sayılarını yenile (diğer sayfalardan dönüldüğünde)
  Future<void> _refreshFollowCounts() async {
    if (_userProfile == null) return;

    try {
      final updatedProfile = await _profileService.getUserProfile();
      if (updatedProfile != null) {
        setState(() {
          _followersCount = updatedProfile.followers.length;
          _followingCount = updatedProfile.following.length;
        });
      }
    } catch (e) {
      print('Error refreshing follow counts: $e');
    }
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    _lastRefresh = DateTime.now();

    try {
      final profile = await _profileService.getUserProfile();
      if (profile != null) {
        setState(() {
          _userProfile = profile;
        });

        // Takip sayılarını profile'dan direkt al (Firestore'dan ayrı sorgu yapmak yerine)
        setState(() {
          _followersCount = _userProfile!.followers.length;
          _followingCount = _userProfile!.following.length;
        });

        // Load favorite movies
        if (profile.favoriteMovies.isNotEmpty) {
          final movies = await _profileService.getFavoriteMovies(
            profile.favoriteMovies,
          );
          setState(() => _favoriteMovies = movies);
        } else {
          setState(() => _favoriteMovies = []);
        }

        // Load watchlist movies
        if (profile.watchlist.isNotEmpty) {
          final watchlistMovies = await _profileService.getWatchlistMovies(
            profile.watchlist,
          );
          setState(() => _watchlistMovies = watchlistMovies);
        } else {
          setState(() => _watchlistMovies = []);
        }

        // Load user comments - Kullanıcının tüm yorumlarını yükle
        await _loadUserComments();
      }
    } catch (e) {
      print('Error loading profile: $e');
      _showErrorSnackBar('Profil yüklenirken hata oluştu');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUserComments() async {
    try {
      // Direkt kullanıcının yorumlarını al
      final userComments = await _commentsService.getUserComments(
        _currentUsername,
      );

      // Her yoruma film bilgisini ekle
      final enrichedComments = await Future.wait(
        userComments.map((comment) async {
          try {
            final movieId = comment['movieId'];

            // Önce favorite ve watchlist'ten film ara
            Movie? movie =
                [
                  ..._favoriteMovies,
                  ..._watchlistMovies,
                ].where((m) => m.id == movieId).firstOrNull;

            // Bulunamazsa movie service'den al
            if (movie == null) {
              // BatchOptimizedMovieService'den film al
              final movieService = BatchOptimizedMovieService();
              movie = await movieService.getMovieById(movieId);
            }

            // Hala bulunamazsa default movie oluştur
            movie ??= Movie(
              id: movieId,
              title: 'Bilinmeyen Film',
              adult: false,
              genre: [],
              genreIds: [],
              originalLanguage: 'tr',
              originalTitle: 'Bilinmeyen Film',
              overview: 'Film bilgisi bulunamadı',
              popularity: 0.0,
              posterPath: '',
              releaseDate: '2024-01-01',
              voteAverage: 0.0,
              voteCount: 0,
            );

            comment['movie'] = movie;
            return comment;
          } catch (e) {
            print('Error loading movie for comment: $e');
            // Hata durumunda default movie ekle
            comment['movie'] = Movie(
              id: comment['movieId'] ?? 0,
              title: 'Film Bulunamadı',
              adult: false,
              genre: [],
              genreIds: [],
              originalLanguage: 'tr',
              originalTitle: 'Film Bulunamadı',
              overview: 'Film bilgisi bulunamadı',
              popularity: 0.0,
              posterPath: '',
              releaseDate: '2024-01-01',
              voteAverage: 0.0,
              voteCount: 0,
            );
            return comment;
          }
        }),
      );

      // Yorumları tarihe göre sırala (en yeni önce)
      enrichedComments.sort(
        (a, b) => DateTime.parse(
          b['createdAt'],
        ).compareTo(DateTime.parse(a['createdAt'])),
      );

      setState(() {
        _userComments = enrichedComments;
      });
    } catch (e) {
      print('Error loading user comments: $e');
      setState(() {
        _userComments = [];
      });
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

  Future<void> _editBio() async {
    if (_userProfile == null) return;

    final TextEditingController bioController = TextEditingController(
      text: _userProfile!.bio,
    );

    final result = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Biografi Düzenle',
              style: TextStyle(
                fontFamily: "PlayfairDisplay",
                fontWeight: FontWeight.bold,
              ),
            ),
            content: TextField(
              controller: bioController,
              maxLines: 3,
              maxLength: 150,
              decoration: InputDecoration(
                hintText: 'Kendini tanıt...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.primaryRed),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, bioController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRed,
                  foregroundColor: Colors.white,
                ),
                child: Text('Kaydet'),
              ),
            ],
          ),
    );

    if (result != null) {
      setState(() => _isUpdating = true);

      try {
        final updatedProfile = _userProfile!.copyWith(bio: result);
        final success = await _profileService.updateProfile(updatedProfile);

        if (success) {
          setState(() => _userProfile = updatedProfile);
          _showSuccessSnackBar('Biografi güncellendi');
        } else {
          _showErrorSnackBar('Biografi güncellenemedi');
        }
      } catch (e) {
        _showErrorSnackBar('Biografi güncellenirken hata oluştu');
      } finally {
        setState(() => _isUpdating = false);
      }
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
        backgroundColor: AppTheme.primaryRed,
        elevation: 0,
        title: Text(
          "Profil",
          style: TextStyle(fontFamily: "Caveat Brush", fontSize: 40),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _loadProfile,
            icon: Icon(Icons.refresh, color: AppTheme.darkGrey),
            tooltip: 'Profili Yenile',
          ),
          IconButton(onPressed: AuthService().logout, icon: Icon(Icons.logout)),
        ],
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

                  SizedBox(height: isSmallScreen ? 20 : 24),

                  // İzleme Listesi
                  _buildWatchlistMovies(isSmallScreen),

                  SizedBox(height: isSmallScreen ? 20 : 24),

                  // Yorumlarım Bölümü - YENİ!
                  _buildUserComments(isSmallScreen),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Yeni yorum bölümü widget'ı
  Widget _buildUserComments(bool isSmallScreen) {
    final titleFontSize = isSmallScreen ? 18.0 : 20.0;
    final cardHeight =
        isSmallScreen ? 200.0 : 220.0; // 160'tan 200'e, 180'den 220'ye artır
    final spacing = isSmallScreen ? 12.0 : 16.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Yorumlarım (${_userComments.length})',
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
              _userComments.isEmpty
                  ? _buildEmptyComments(isSmallScreen)
                  : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _userComments.length,
                    itemBuilder: (context, index) {
                      return _SpoilerCommentCard(
                        comment: _userComments[index],
                        isSmallScreen: isSmallScreen,
                      );
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildEmptyComments(bool isSmallScreen) {
    final iconSize = isSmallScreen ? 40.0 : 48.0;
    final fontSize = isSmallScreen ? 14.0 : 16.0;
    final spacing = isSmallScreen ? 6.0 : 8.0;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.comment_outlined,
            size: iconSize,
            color: AppTheme.secondaryGrey,
          ),
          SizedBox(height: spacing),
          Text(
            'Henüz yorum yapmadınız',
            style: TextStyle(color: AppTheme.secondaryGrey, fontSize: fontSize),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: spacing),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/browse');
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
                _userProfile!.profileImageUrl.isNotEmpty
                    ? Image.network(
                      _userProfile!.profileImageUrl,
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
    final bioFontSize = isSmallScreen ? 13.0 : 15.0;
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

        if (_userProfile!.fullName.isNotEmpty &&
            _userProfile!.fullName != _userProfile!.username)
          Text(
            _userProfile!.fullName,
            style: const TextStyle(fontSize: 16, color: Colors.white70),
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

        SizedBox(height: spacing * 2), // Takip sayıları için daha fazla boşluk
        // Takipçi ve takip edilen sayıları
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildFollowCount('Takipçi', _followersCount),
            SizedBox(width: 32),
            _buildFollowCount('Takip', _followingCount),
          ],
        ),

        SizedBox(height: spacing * 2), // Bio'dan önce daha fazla boşluk
        // Biografi bölümü - Güncellenmiş UI
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(isSmallScreen ? 16.0 : 20.0),
          margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 20.0 : 32.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.95),
                Colors.white.withOpacity(0.85),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: AppTheme.primaryRed.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Icon(
                      Icons.edit_note,
                      size: isSmallScreen ? 18.0 : 20.0,
                      color: AppTheme.primaryRed,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Biografi',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16.0 : 18.0,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryRed,
                      fontFamily: "PlayfairDisplay",
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.touch_app,
                    size: isSmallScreen ? 16.0 : 18.0,
                    color: AppTheme.secondaryGrey,
                  ),
                ],
              ),
              SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: GestureDetector(
                  onTap: _editBio,
                  child: Text(
                    _userProfile!.bio.isEmpty
                        ? 'Kendini tanıt...\nFilm zevkini, hobilerini veya ilgi alanlarını paylaş! 🎬'
                        : _userProfile!.bio,
                    style: TextStyle(
                      fontSize: bioFontSize,
                      color:
                          _userProfile!.bio.isEmpty
                              ? AppTheme.secondaryGrey
                              : AppTheme.darkGrey,
                      fontStyle:
                          _userProfile!.bio.isEmpty
                              ? FontStyle.italic
                              : FontStyle.normal,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: isSmallScreen ? 16.0 : 20.0),

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
                    itemCount:
                        _favoriteMovies.length + 1, // Add 1 for the "add" card
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
              Navigator.pushNamed(context, '/browse');
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
      child: GestureDetector(
        onTap: () => _showMovieDetails(movie),
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
          Navigator.pushNamed(context, '/browse');
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

  Widget _buildWatchlistMovies(bool isSmallScreen) {
    final titleFontSize = isSmallScreen ? 18.0 : 20.0;
    final cardHeight = isSmallScreen ? 130.0 : 150.0;
    final spacing = isSmallScreen ? 12.0 : 16.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'İzleme Listesi',
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
              _watchlistMovies.isEmpty
                  ? _buildEmptyWatchlist(isSmallScreen)
                  : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount:
                        _watchlistMovies.length + 1, // Add 1 for the "add" card
                    itemBuilder: (context, index) {
                      if (index < _watchlistMovies.length) {
                        return _buildWatchlistMovieCard(
                          _watchlistMovies[index],
                          isSmallScreen,
                        );
                      } else {
                        return _buildAddWatchlistCard(isSmallScreen);
                      }
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildEmptyWatchlist(bool isSmallScreen) {
    final iconSize = isSmallScreen ? 40.0 : 48.0;
    final fontSize = isSmallScreen ? 14.0 : 16.0;
    final spacing = isSmallScreen ? 6.0 : 8.0;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.playlist_add,
            size: iconSize,
            color: AppTheme.secondaryGrey,
          ),
          SizedBox(height: spacing),
          Text(
            'İzleme listesi boş',
            style: TextStyle(color: AppTheme.secondaryGrey, fontSize: fontSize),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: spacing),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/browse');
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

  Widget _buildWatchlistMovieCard(Movie movie, bool isSmallScreen) {
    final cardWidth = isSmallScreen ? 80.0 : 100.0;
    final margin = isSmallScreen ? 8.0 : 12.0;
    final fontSize = isSmallScreen ? 10.0 : 12.0;
    final spacing = isSmallScreen ? 6.0 : 8.0;

    return Container(
      width: cardWidth,
      margin: EdgeInsets.only(right: margin),
      child: GestureDetector(
        onTap: () => _showMovieDetails(movie),
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
      ),
    );
  }

  Widget _buildAddWatchlistCard(bool isSmallScreen) {
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
          Navigator.pushNamed(context, '/browse');
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
              Icon(
                Icons.playlist_add,
                size: iconSize,
                color: AppTheme.primaryRed,
              ),
              SizedBox(height: spacing),
              Text(
                'Liste Ekle',
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

  Widget _buildStatsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.95),
            Colors.white.withOpacity(0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppTheme.primaryRed.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatCard(
            'Favoriler',
            _userProfile?.favoriteMovies.length.toString() ?? '0',
          ),
          Container(
            width: 1,
            height: 40,
            color: AppTheme.secondaryGrey.withOpacity(0.3),
          ),
          _buildStatCard(
            'İzleme Listesi',
            _userProfile?.watchlist.length.toString() ?? '0',
          ),
          Container(
            width: 1,
            height: 40,
            color: AppTheme.secondaryGrey.withOpacity(0.3),
          ),
          _buildStatCard('Yorumlar', _userComments.length.toString()),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryRed,
            fontFamily: "PlayfairDisplay",
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.secondaryGrey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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

  Widget _buildFollowCount(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryRed,
            fontFamily: "PlayfairDisplay",
          ),
        ),
        SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.secondaryGrey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _SpoilerCommentCard extends StatefulWidget {
  final Map<String, dynamic> comment;
  final bool isSmallScreen;

  const _SpoilerCommentCard({
    required this.comment,
    required this.isSmallScreen,
  });

  @override
  State<_SpoilerCommentCard> createState() => _SpoilerCommentCardState();
}

class _SpoilerCommentCardState extends State<_SpoilerCommentCard> {
  bool _isRevealed = false;

  @override
  Widget build(BuildContext context) {
    final cardWidth = widget.isSmallScreen ? 250.0 : 280.0;
    final margin = widget.isSmallScreen ? 8.0 : 12.0;
    final fontSize = widget.isSmallScreen ? 12.0 : 14.0;
    final spacing = widget.isSmallScreen ? 6.0 : 8.0;
    final movie = widget.comment['movie'] as Movie;
    final isSpoiler = widget.comment['isSpoiler'] == true;

    return Container(
      width: cardWidth,
      margin: EdgeInsets.only(right: margin),
      child: GestureDetector(
        onTap: () {
          // Filmin yorum sayfasına git
          Navigator.pushNamed(
            context,
            '/comments',
            arguments: {'movieId': movie.id, 'movie': movie},
          );
        },
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMovieHeader(movie, fontSize, isSpoiler),
                SizedBox(height: spacing),
                Expanded(child: _buildCommentContent(isSpoiler, fontSize)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMovieHeader(Movie movie, double fontSize, bool isSpoiler) {
    return Row(
      children: [
        // Film posteri (küçük)
        Container(
          width: 40,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
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
                  ? const Icon(Icons.movie, size: 20, color: Colors.white)
                  : null,
        ),

        const SizedBox(width: 8),

        // Film adı ve rating
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                movie.title,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  ...List.generate(
                    5,
                    (index) => Icon(
                      index < ((widget.comment['rating'] ?? 0) / 2)
                          ? Icons.star
                          : Icons.star_border,
                      size: 12,
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(width: 4),
                  if (isSpoiler)
                    Icon(
                      Icons.visibility_off,
                      size: 12,
                      color: AppTheme.primaryRed,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommentContent(bool isSpoiler, double fontSize) {
    if (isSpoiler && !_isRevealed) {
      return GestureDetector(
        onTap: () {
          setState(() {
            _isRevealed = true;
          });
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.primaryRed.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.visibility_off, color: AppTheme.primaryRed, size: 24),
              const SizedBox(height: 8),
              Text(
                'Spoiler İçerik\nGörmek için tıklayın',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.primaryRed,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            widget.comment['comment']?.toString() ?? '',
            style: TextStyle(fontSize: fontSize, height: 1.4),
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              widget.comment['date']?.toString() ?? '',
              style: TextStyle(
                fontSize: fontSize - 2,
                color: AppTheme.secondaryGrey,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.secondaryGrey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.comment['language'] ?? 'TR',
                style: TextStyle(fontSize: fontSize - 2),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
