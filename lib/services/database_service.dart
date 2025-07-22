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
      version: 1,
      onCreate: _onCreate,
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
        createdAt TEXT NOT NULL
      )
    ''');
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

  // Yorum ekle
  Future<int> addComment({
    required int movieId,
    required String username,
    required int rating,
    required String comment,
    required bool isSpoiler,
  }) async {
    final db = await database;
    return await db.insert(
      _commentsTable,
      {
        'movieId': movieId,
        'username': username,
        'rating': rating,
        'comment': comment,
        'isSpoiler': isSpoiler ? 1 : 0,
        'createdAt': DateTime.now().toIso8601String(),
      },
    );
  }

  // Yorum sil
  Future<int> deleteComment(int commentId) async {
    final db = await database;
    return await db.delete(
      _commentsTable,
      where: 'id = ?',
      whereArgs: [commentId],
    );
  }

  // Tüm yorumları sil (test için)
  Future<int> deleteAllComments() async {
    final db = await database;
    return await db.delete(_commentsTable);
  }

  // Veritabanını kapat
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}