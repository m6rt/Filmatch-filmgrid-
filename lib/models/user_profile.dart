class UserProfile {
  final String uid;
  final String username;
  final String email;
  final String fullName;
  final String bio;
  final String profileImageUrl;
   final List<String> favoriteMovies;
  final List<String> watchlist;
  final List<String> followers;
  final List<String> following;
  final DateTime createdAt;
  final DateTime lastUpdated;
  final bool isFavoritesPublic;
  final bool isWatchlistPublic;

  UserProfile({
    this.uid = '',
    required this.username,
    this.email = '',
    this.fullName = '',
    this.bio = '',
    this.profileImageUrl = '',
    this.favoriteMovies = const [],
    this.watchlist = const [],
    this.followers = const [],
    this.following = const [],
    DateTime? createdAt,
    DateTime? lastUpdated,
    this.isFavoritesPublic = true,
    this.isWatchlistPublic = true,
  }) : createdAt = createdAt ?? DateTime.now(),
       lastUpdated = lastUpdated ?? DateTime.now();

  // Firestore'dan UserProfile oluştur
  factory UserProfile.fromFirestore(Map<String, dynamic> data, String uid) {
    return UserProfile(
      uid: uid,
      username: data['username'] ?? '',
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? data['displayName'] ?? '',
      bio: data['bio'] ?? '',
      profileImageUrl:
          data['profileImageUrl'] ?? data['profilePictureURL'] ?? '',
      favoriteMovies: List<String>.from(
        data['favoriteMovieIds'] ?? data['favoriteMovies'] ?? [],
      ),
      watchlist: List<String>.from(
        data['watchlistMovieIds'] ?? data['watchlist'] ?? [],
      ),
      followers: List<String>.from(data['followers'] ?? []),
      following: List<String>.from(data['following'] ?? []),
      createdAt:
          data['createdAt'] != null
              ? (data['createdAt'] is int
                  ? DateTime.fromMillisecondsSinceEpoch(data['createdAt'])
                  : DateTime.tryParse(data['createdAt'].toString()) ??
                      DateTime.now())
              : DateTime.now(),
      lastUpdated:
          data['lastUpdated'] != null
              ? (data['lastUpdated'] is int
                  ? DateTime.fromMillisecondsSinceEpoch(data['lastUpdated'])
                  : DateTime.tryParse(data['lastUpdated'].toString()) ??
                      DateTime.now())
              : DateTime.now(),
      isFavoritesPublic: data['isFavoritesPublic'] ?? true,
      isWatchlistPublic: data['isWatchlistPublic'] ?? true,
    );
  }

  // Firestore'a gönderilecek format
  Map<String, dynamic> toFirestore() {
    return {
      'username': username,
      'email': email,
      'fullName': fullName,
      'displayName': fullName, // Eski uyumluluk
      'bio': bio,
      'profileImageUrl': profileImageUrl,
      'profilePictureURL': profileImageUrl, // Eski uyumluluk
      'favoriteMovieIds': favoriteMovies,
      'favoriteMovies': favoriteMovies, // Eski uyumluluk
      'watchlistMovieIds': watchlist,
      'watchlist': watchlist, // Eski uyumluluk
      'followers': followers,
      'following': following,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
      'isFavoritesPublic': isFavoritesPublic,
      'isWatchlistPublic': isWatchlistPublic,
    };
  }

  // Copy with metodu
  UserProfile copyWith({
    String? uid,
    String? username,
    String? email,
    String? fullName,
    String? bio,
    String? profileImageUrl,
    List<String>? favoriteMovies,
    List<String>? watchlist,
    List<String>? followers,
    List<String>? following,
    DateTime? createdAt,
    DateTime? lastUpdated,
    bool? isFavoritesPublic,
    bool? isWatchlistPublic,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      bio: bio ?? this.bio,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      favoriteMovies: favoriteMovies ?? this.favoriteMovies,
      watchlist: watchlist ?? this.watchlist,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isFavoritesPublic: isFavoritesPublic ?? this.isFavoritesPublic,
      isWatchlistPublic: isWatchlistPublic ?? this.isWatchlistPublic,
    );
  }

  @override
  String toString() {
    return 'UserProfile{uid: $uid, username: $username, fullName: $fullName}';
  }
}
