class UserProfile {
  final String uid;
  final String username;
  final String displayName;
  final String email;
  final String profilePictureURL;
  final DateTime createdAt;
  final DateTime lastUpdated;
  final List<String> favoriteMovieIds;
  final List<String> watchlistMovieIds;
  final bool isWatchlistPublic;
  final bool isCommentsPublic;

  UserProfile({
    required this.uid,
    required this.username,
    this.displayName = '',
    required this.email,
    this.profilePictureURL = '',
    required this.createdAt,
    required this.lastUpdated,
    this.favoriteMovieIds = const [],
    this.watchlistMovieIds = const [],
    this.isWatchlistPublic = true,
    this.isCommentsPublic = true,
  });

  factory UserProfile.fromFirestore(Map<String, dynamic> data, String uid) {
    return UserProfile(
      uid: uid,
      username: data['username'] ?? '',
      displayName: data['displayName'] ?? '',
      email: data['email'] ?? '',
      profilePictureURL: data['profilePictureURL'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] ?? 0),
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(
        data['lastUpdated'] ?? 0,
      ),
      favoriteMovieIds: List<String>.from(data['favoriteMovieIds'] ?? []),
      watchlistMovieIds: List<String>.from(data['watchlistMovieIds'] ?? []),
      isWatchlistPublic: data['isWatchlistPublic'] ?? true,
      isCommentsPublic: data['isCommentsPublic'] ?? true,
    );
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] ?? '',
      username: map['username'] ?? '',
      displayName: map['displayName'] ?? '',
      email: map['email'] ?? '',
      profilePictureURL: map['profilePictureURL'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(map['lastUpdated'] ?? 0),
      favoriteMovieIds: List<String>.from(map['favoriteMovieIds'] ?? []),
      watchlistMovieIds: List<String>.from(map['watchlistMovieIds'] ?? []),
      isWatchlistPublic: map['isWatchlistPublic'] ?? true,
      isCommentsPublic: map['isCommentsPublic'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'username': username,
      'displayName': displayName,
      'email': email,
      'profilePictureURL': profilePictureURL,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
      'favoriteMovieIds': favoriteMovieIds,
      'watchlistMovieIds': watchlistMovieIds,
      'isWatchlistPublic': isWatchlistPublic,
      'isCommentsPublic': isCommentsPublic,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'displayName': displayName,
      'email': email,
      'profilePictureURL': profilePictureURL,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
      'favoriteMovieIds': favoriteMovieIds,
      'watchlistMovieIds': watchlistMovieIds,
      'isWatchlistPublic': isWatchlistPublic,
      'isCommentsPublic': isCommentsPublic,
    };
  }

  UserProfile copyWith({
    String? uid,
    String? username,
    String? displayName,
    String? email,
    String? profilePictureURL,
    DateTime? createdAt,
    DateTime? lastUpdated,
    List<String>? favoriteMovieIds,
    List<String>? watchlistMovieIds,
    bool? isWatchlistPublic,
    bool? isCommentsPublic,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      profilePictureURL: profilePictureURL ?? this.profilePictureURL,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      favoriteMovieIds: favoriteMovieIds ?? this.favoriteMovieIds,
      watchlistMovieIds: watchlistMovieIds ?? this.watchlistMovieIds,
      isWatchlistPublic: isWatchlistPublic ?? this.isWatchlistPublic,
      isCommentsPublic: isCommentsPublic ?? this.isCommentsPublic,
    );
  }
}
