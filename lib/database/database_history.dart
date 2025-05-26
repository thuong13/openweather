import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseHistory {
  static final DatabaseHistory instance = DatabaseHistory._init();

  static Database? _database;

  DatabaseHistory._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('air_quality.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        city TEXT NOT NULL,
        aqi INTEGER NOT NULL,
        pm25 REAL NOT NULL,
        pm10 REAL NOT NULL,
        co REAL NOT NULL,
        so2 REAL NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE user_cities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        city TEXT NOT NULL,
        lat REAL NOT NULL,
        lon REAL NOT NULL
      )
    ''');
  }

  Future<bool> _tableExists(Database db, String tableName) async {
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [tableName],
    );
    return result.isNotEmpty;
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Đảm bảo thêm cột city nếu chưa có
      final tableInfo = await db.rawQuery('PRAGMA table_info(history)');
      final hasCityColumn = tableInfo.any((column) => column['name'] == 'city');
      if (!hasCityColumn) {
        await db.execute('ALTER TABLE history ADD COLUMN city TEXT NOT NULL DEFAULT "Hanoi"');
      }
    }

    if (oldVersion < 3) {
      final exists = await _tableExists(db, 'user_cities');
      if (!exists) {
        await db.execute('''
          CREATE TABLE user_cities (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            city TEXT NOT NULL,
            lat REAL NOT NULL,
            lon REAL NOT NULL
          )
        ''');
      }
    }
  }

  Future<void> insertAirQuality(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('history', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getHistory(String city) async {
    final db = await database;
    return await db.query(
      'history',
      where: 'city = ?',
      whereArgs: [city],
      orderBy: 'timestamp DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getAllHistory() async {
    final db = await database;
    return await db.query('history', orderBy: 'timestamp DESC');
  }

  Future<void> clearHistory(String city) async {
    final db = await database;
    await db.delete('history', where: 'city = ?', whereArgs: [city]);
  }

  Future<void> clearAllHistory() async {
    final db = await database;
    await db.delete('history');
  }

  Future<void> addCity(String city, double lat, double lon) async {
    final db = await database;
    await db.insert(
      'user_cities',
      {'city': city, 'lat': lat, 'lon': lon},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getUserCities() async {
    final db = await database;
    return await db.query('user_cities');
  }

  Future<void> clearUserCities() async {
    final db = await database;
    await db.delete('user_cities');
  }

  Future<void> backupDataToSharedPreferences(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final db = await database;

    final history = await db.query('history');
    final cities = await db.query('user_cities');

    await prefs.setString('history_$userId', jsonEncode(history));
    await prefs.setString('cities_$userId', jsonEncode(cities));
  }

  Future<void> restoreDataFromSharedPreferences(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final db = await database;

    final historyJson = prefs.getString('history_$userId');
    if (historyJson != null) {
      final historyList = jsonDecode(historyJson) as List;
      for (var item in historyList) {
        await db.insert('history', Map<String, dynamic>.from(item),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }

    final citiesJson = prefs.getString('cities_$userId');
    if (citiesJson != null) {
      final cityList = jsonDecode(citiesJson) as List;
      for (var item in cityList) {
        await db.insert('user_cities', Map<String, dynamic>.from(item),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }
  }

  Future<void> clearAllLocalData() async {
    final db = await database;
    await db.delete('history');
    await db.delete('user_cities');
  }
}
