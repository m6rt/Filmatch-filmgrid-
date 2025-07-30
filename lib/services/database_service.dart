import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;
  static const int _version = 3;

  // Tablo isimlerini tanımla
  static const String _commentsTable = 'comments';
  static const String _commentLikesTable = 'comment_likes';
  static const String _notificationsTable = 'notifications';

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'movie_database.db');
    return await openDatabase(
      path,
      version: _version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Yeni tablolar için upgrade metodu
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Yorum beğenileri tablosu
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $_commentLikesTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          commentId INTEGER NOT NULL,
          username TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          FOREIGN KEY (commentId) REFERENCES $_commentsTable (id) ON DELETE CASCADE,
          UNIQUE(commentId, username)
        )
      ''');

      // Bildirimler tablosu
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $_notificationsTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          toUsername TEXT NOT NULL,
          fromUsername TEXT NOT NULL,
          type TEXT NOT NULL,
          title TEXT NOT NULL,
          message TEXT NOT NULL,
          data TEXT,
          isRead INTEGER NOT NULL DEFAULT 0,
          createdAt TEXT NOT NULL
        )
      ''');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // Yorumlar tablosu
    await db.execute('''
      CREATE TABLE $_commentsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        movieId INTEGER NOT NULL,
        username TEXT NOT NULL,
        rating INTEGER NOT NULL,
        comment TEXT NOT NULL,
        isSpoiler INTEGER NOT NULL DEFAULT 0,
        language TEXT NOT NULL DEFAULT 'TR',
        createdAt TEXT NOT NULL,
        UNIQUE(movieId, username)
      )
    ''');

    // Eğer version 2 ise diğer tabloları da oluştur
    if (version >= 2) {
      await db.execute('''
        CREATE TABLE $_commentLikesTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          commentId INTEGER NOT NULL,
          username TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          FOREIGN KEY (commentId) REFERENCES $_commentsTable (id) ON DELETE CASCADE,
          UNIQUE(commentId, username)
        )
      ''');

      await db.execute('''
        CREATE TABLE $_notificationsTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          toUsername TEXT NOT NULL,
          fromUsername TEXT NOT NULL,
          type TEXT NOT NULL,
          title TEXT NOT NULL,
          message TEXT NOT NULL,
          data TEXT,
          isRead INTEGER NOT NULL DEFAULT 0,
          createdAt TEXT NOT NULL
        )
      ''');
    }
  }

  // Yorumları getir
  Future<List<Map<String, dynamic>>> getComments(int movieId) async {
    final db = await database;
    return await db.query(
      _commentsTable,
      where: 'movieId = ?',
      whereArgs: [movieId],
      orderBy: 'createdAt DESC',
    );
  }

  // Kullanıcının belirli film için yorumunu getir
  Future<Map<String, dynamic>?> getUserComment(
    int movieId,
    String username,
  ) async {
    final db = await database;
    final result = await db.query(
      _commentsTable,
      where: 'movieId = ? AND username = ?',
      whereArgs: [movieId, username],
    );
    return result.isNotEmpty ? result.first : null;
  }

  // Kullanıcının daha önce yorum yapıp yapmadığını kontrol et
  Future<bool> hasUserCommented(int movieId, String username) async {
    final comment = await getUserComment(movieId, username);
    return comment != null;
  }

  // Yorum ekle
  Future<int> addComment({
    required int movieId,
    required String username,
    required int rating,
    required String comment,
    required bool isSpoiler,
    required String language,
  }) async {
    final db = await database;

    // Önce kullanıcının daha önce yorum yapıp yapmadığını kontrol et
    final existingComment = await getUserComment(movieId, username);
    if (existingComment != null) {
      throw Exception(
        'Bu filme daha önce yorum yaptınız. Yorumunuzu düzenleyebilirsiniz.',
      );
    }

    return await db.insert(_commentsTable, {
      'movieId': movieId,
      'username': username,
      'rating': rating,
      'comment': comment,
      'isSpoiler': isSpoiler ? 1 : 0,
      'language': language,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  // Yorumu güncelle
  Future<int> updateComment({
    required int movieId,
    required String username,
    required int rating,
    required String comment,
    required bool isSpoiler,
    required String language,
  }) async {
    final db = await database;
    return await db.update(
      _commentsTable,
      {
        'rating': rating,
        'comment': comment,
        'isSpoiler': isSpoiler ? 1 : 0,
        'language': language,
        'createdAt': DateTime.now().toIso8601String(), // Güncelleme tarihi
      },
      where: 'movieId = ? AND username = ?',
      whereArgs: [movieId, username],
    );
  }

  // Yorum sil (ID ile)
  Future<int> deleteComment(int commentId) async {
    final db = await database;
    return await db.delete(
      _commentsTable,
      where: 'id = ?',
      whereArgs: [commentId],
    );
  }

  // Kullanıcının yorumunu sil (movieId ve username ile)
  Future<int> deleteUserComment(int movieId, String username) async {
    final db = await database;
    return await db.delete(
      _commentsTable,
      where: 'movieId = ? AND username = ?',
      whereArgs: [movieId, username],
    );
  }

  // Tüm yorumları sil (test için)
  Future<int> deleteAllComments() async {
    final db = await database;
    return await db.delete(_commentsTable);
  }

  // Veritabanını kapat
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  // Belirli bir kullanıcının tüm yorumlarını getir
  Future<List<Map<String, dynamic>>> getUserComments(String username) async {
    final db = await database;
    try {
      return await db.query(
        _commentsTable,
        where: 'username = ?',
        whereArgs: [username],
        orderBy: 'createdAt DESC',
      );
    } catch (e) {
      print('Error getting user comments: $e');
      return [];
    }
  }

  // Yorum beğenme metodları
  Future<bool> likeComment(int commentId, String username) async {
    final db = await database;
    try {
      await db.insert(_commentLikesTable, {
        'commentId': commentId,
        'username': username,
        'createdAt': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      return true;
    } catch (e) {
      print('Error liking comment: $e');
      return false;
    }
  }

  Future<bool> unlikeComment(int commentId, String username) async {
    final db = await database;
    try {
      final result = await db.delete(
        _commentLikesTable,
        where: 'commentId = ? AND username = ?',
        whereArgs: [commentId, username],
      );
      return result > 0;
    } catch (e) {
      print('Error unliking comment: $e');
      return false;
    }
  }

  Future<bool> isCommentLiked(int commentId, String username) async {
    final db = await database;
    try {
      final result = await db.query(
        _commentLikesTable,
        where: 'commentId = ? AND username = ?',
        whereArgs: [commentId, username],
      );
      return result.isNotEmpty;
    } catch (e) {
      print('Error checking if comment liked: $e');
      return false;
    }
  }

  Future<int> getCommentLikesCount(int commentId) async {
    final db = await database;
    try {
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $_commentLikesTable WHERE commentId = ?',
        [commentId],
      );
      return result.first['count'] as int;
    } catch (e) {
      print('Error getting comment likes count: $e');
      return 0;
    }
  }

  // Bildirim metodları
  Future<int> addNotification({
    required String toUsername,
    required String fromUsername,
    required String type,
    required String title,
    required String message,
    String? data,
  }) async {
    final db = await database;
    try {
      return await db.insert(_notificationsTable, {
        'toUsername': toUsername,
        'fromUsername': fromUsername,
        'type': type,
        'title': title,
        'message': message,
        'data': data,
        'isRead': 0,
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error adding notification: $e');
      return -1;
    }
  }

  Future<List<Map<String, dynamic>>> getNotifications(String username) async {
    final db = await database;
    try {
      return await db.query(
        _notificationsTable,
        where: 'toUsername = ?',
        whereArgs: [username],
        orderBy: 'createdAt DESC',
      );
    } catch (e) {
      print('Error getting notifications: $e');
      return [];
    }
  }

  Future<int> getUnreadNotificationsCount(String username) async {
    final db = await database;
    try {
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $_notificationsTable WHERE toUsername = ? AND isRead = 0',
        [username],
      );
      return result.first['count'] as int;
    } catch (e) {
      print('Error getting unread notifications count: $e');
      return 0;
    }
  }

  Future<bool> markNotificationAsRead(int notificationId) async {
    final db = await database;
    try {
      final result = await db.update(
        _notificationsTable,
        {'isRead': 1},
        where: 'id = ?',
        whereArgs: [notificationId],
      );
      return result > 0;
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }

  Future<bool> markAllNotificationsAsRead(String username) async {
    final db = await database;
    try {
      final result = await db.update(
        _notificationsTable,
        {'isRead': 1},
        where: 'toUsername = ?',
        whereArgs: [username],
      );
      return result > 0;
    } catch (e) {
      print('Error marking all notifications as read: $e');
      return false;
    }
  }

  // Debug metodu - tabloları kontrol et
  Future<void> debugDatabaseTables() async {
    try {
      final db = await database;

      // Tabloları listele
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'",
      );
      print('Mevcut tablolar:');
      for (final table in tables) {
        print('- ${table['name']}');
      }

      // Comment_likes tablosunu kontrol et
      try {
        final result = await db.rawQuery(
          'SELECT COUNT(*) as count FROM $_commentLikesTable',
        );
        print(
          'comment_likes tablosu mevcut, ${result.first['count']} kayıt var',
        );
      } catch (e) {
        print('comment_likes tablosu bulunamadı: $e');
      }

      // Notifications tablosunu kontrol et
      try {
        final result = await db.rawQuery(
          'SELECT COUNT(*) as count FROM $_notificationsTable',
        );
        print(
          'notifications tablosu mevcut, ${result.first['count']} kayıt var',
        );
      } catch (e) {
        print('notifications tablosu bulunamadı: $e');
      }
    } catch (e) {
      print('Debug kontrolü sırasında hata: $e');
    }
  }

  // Geliştirme aşamasında veritabanını sıfırla
  Future<void> resetDatabase() async {
    try {
      String path = join(await getDatabasesPath(), 'movie_database.db');
      await deleteDatabase(path);
      _database = null;
      await database; // Yeniden oluştur
      print('Veritabanı sıfırlandı ve yeniden oluşturuldu');
    } catch (e) {
      print('Reset database error: $e');
      rethrow;
    }
  }
}
