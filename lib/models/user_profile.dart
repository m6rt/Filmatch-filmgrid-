class UserProfile {
  final String uid;
  final String username;
  final String email;
  final String? profileImageUrl;
  final List<String> favoriteMovieIds;
  final DateTime createdAt;
  final DateTime lastUpdated;

  UserProfile({
    required this.uid,
    required this.username,
    required this.email,
    this.profileImageUrl,
    this.favoriteMovieIds = const [],
    required this.createdAt,
    required this.lastUpdated,
  });

  factory UserProfile.fromFirestore(Map<String, dynamic> data, String uid) {
    return UserProfile(
      uid: uid,
      username: data['username'] ?? '',
      email: data['email'] ?? '',
      profileImageUrl: data['profileImageUrl'],
      favoriteMovieIds: List<String>.from(data['favoriteMovieIds'] ?? []),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        data['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(
        data['lastUpdated'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'username': username,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'favoriteMovieIds': favoriteMovieIds,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
    };
  }

  UserProfile copyWith({
    String? username,
    String? email,
    String? profileImageUrl,
    List<String>? favoriteMovieIds,
    DateTime? lastUpdated,
  }) {
    return UserProfile(
      uid: uid,
      username: username ?? this.username,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      favoriteMovieIds: favoriteMovieIds ?? this.favoriteMovieIds,
      createdAt: createdAt,
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }
}
