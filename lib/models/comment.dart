class Comment {
  final String id;
  final String userId;
  final String username;
  final String? userProfileImageUrl;
  final String movieId;
  final String movieTitle;
  final String moviePosterUrl;
  final String content;
  final double? rating;
  final DateTime createdAt;
  final DateTime updatedAt;

  Comment({
    required this.id,
    required this.userId,
    required this.username,
    this.userProfileImageUrl,
    required this.movieId,
    required this.movieTitle,
    required this.moviePosterUrl,
    required this.content,
    this.rating,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      userId: json['userId'],
      username: json['username'],
      userProfileImageUrl: json['userProfileImageUrl'],
      movieId: json['movieId'],
      movieTitle: json['movieTitle'],
      moviePosterUrl: json['moviePosterUrl'],
      content: json['content'],
      rating: json['rating']?.toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'userProfileImageUrl': userProfileImageUrl,
      'movieId': movieId,
      'movieTitle': movieTitle,
      'moviePosterUrl': moviePosterUrl,
      'content': content,
      'rating': rating,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Comment copyWith({
    String? id,
    String? userId,
    String? username,
    String? userProfileImageUrl,
    String? movieId,
    String? movieTitle,
    String? moviePosterUrl,
    String? content,
    double? rating,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Comment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userProfileImageUrl: userProfileImageUrl ?? this.userProfileImageUrl,
      movieId: movieId ?? this.movieId,
      movieTitle: movieTitle ?? this.movieTitle,
      moviePosterUrl: moviePosterUrl ?? this.moviePosterUrl,
      content: content ?? this.content,
      rating: rating ?? this.rating,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
