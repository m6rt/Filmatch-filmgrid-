import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static Database? _database;
  static const String _commentsTable = 'comments';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'filmgrid.db');

    return await openDatabase(
      path,
      version: 3, // Version'ı artır
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_commentsTable(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        movieId INTEGER NOT NULL,
        username TEXT NOT NULL,
        rating INTEGER NOT NULL,
        comment TEXT NOT NULL,
        isSpoiler INTEGER NOT NULL,
        language TEXT NOT NULL DEFAULT 'TR',
        createdAt TEXT NOT NULL,
        UNIQUE(movieId, username)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      // Language kolonu ekle
      await db.execute(
        'ALTER TABLE $_commentsTable ADD COLUMN language TEXT NOT NULL DEFAULT "TR"',
      );
    }

    if (oldVersion < 2) {
      // Eski tabloyu backup al
      await db.execute(
        'ALTER TABLE $_commentsTable RENAME TO ${_commentsTable}_backup',
      );

      // Yeni tabloyu oluştur
      await _onCreate(db, newVersion);

      // Eski verileri aktar (unique constraint hatalarını ignore et)
      await db.execute('''
        INSERT OR IGNORE INTO $_commentsTable (movieId, username, rating, comment, isSpoiler, language, createdAt)
        SELECT movieId, username, rating, comment, isSpoiler, "TR", createdAt 
        FROM ${_commentsTable}_backup
      ''');

      // Backup tablosunu sil
      await db.execute('DROP TABLE ${_commentsTable}_backup');
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
    return await db.query(
      _commentsTable,
      where: 'username = ?',
      whereArgs: [username],
      orderBy: 'createdAt DESC',
    );
  }
}
