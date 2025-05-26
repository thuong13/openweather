import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      final path = join(await getDatabasesPath(), 'app_database.db');
      return await openDatabase(
        path,
        version: 2, // Tăng version lên 2 để chạy onUpgrade
        onCreate: _onCreate,
        onUpgrade: _onUpgrade, // Thêm onUpgrade để xử lý migration
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
      );
    } catch (e) {
      print('Error initializing database: $e');
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    try {
      await db.execute('''
        CREATE TABLE users(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          email TEXT UNIQUE,
          password TEXT,
          name TEXT,
          phone TEXT,
          address TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE account_suggestions(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          email TEXT UNIQUE,
          name TEXT,
          last_accessed INTEGER
        )
      ''');
    } catch (e) {
      print('Error creating tables: $e');
      rethrow;
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    try {
      if (oldVersion < 2) {
        // Thêm cột name, phone, address vào bảng users nếu chưa có
        await db.execute('ALTER TABLE users ADD COLUMN name TEXT');
        await db.execute('ALTER TABLE users ADD COLUMN phone TEXT');
        await db.execute('ALTER TABLE users ADD COLUMN address TEXT');
      }
    } catch (e) {
      print('Error upgrading database: $e');
      rethrow;
    }
  }

  Future<bool> saveAccountSuggestion(String email, String name) async {
    final db = await database;
    try {
      await db.insert(
        'account_suggestions',
        {
          'email': email,
          'name': name,
          'last_accessed': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return true;
    } catch (e) {
      print('Error saving account suggestion: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getAccountSuggestions() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> result = await db.query(
        'account_suggestions',
        orderBy: 'last_accessed DESC',
        limit: 5,
      );
      return result;
    } catch (e) {
      print('Error getting account suggestions: $e');
      return [];
    }
  }

  Future<void> removeAccountSuggestion(String email) async {
    final db = await database;
    try {
      await db.delete(
        'account_suggestions',
        where: 'email = ?',
        whereArgs: [email],
      );
    } catch (e) {
      print('Error removing account suggestion for email $email: $e');
    }
  }

  Future<bool> registerUser(String email, String password, String name, String phone, String address) async {
    final db = await database;
    try {
      // Kiểm tra xem email đã tồn tại chưa
      final existingUser = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
      );
      if (existingUser.isNotEmpty) {
        return false; // Email đã tồn tại
      }

      await db.insert(
        'users',
        {
          'email': email,
          'password': password,
          'name': name,
          'phone': phone,
          'address': address,
        },
        conflictAlgorithm: ConflictAlgorithm.fail,
      );
      await saveAccountSuggestion(email, name);
      return true;
    } catch (e) {
      print('Error registering user: $e');
      return false;
    }
  }

  Future<bool> loginUser(String email, String password) async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> result = await db.query(
        'users',
        where: 'email = ? AND password = ?',
        whereArgs: [email, password],
      );
      if (result.isNotEmpty) {
        await saveAccountSuggestion(email, result.first['name']);
        return true;
      }
      return false;
    } catch (e) {
      print('Error logging in user: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getUserInfo(String email) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> result = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
      );
      return result.isNotEmpty ? result.first : null;
    } catch (e) {
      print('Error getting user info for email $email: $e');
      return null;
    }
  }
}