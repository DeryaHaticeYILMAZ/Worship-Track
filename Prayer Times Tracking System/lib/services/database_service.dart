import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseService {
  static DatabaseService? _instance;
  static Database? _database;

  DatabaseService._();

  static DatabaseService get instance {
    _instance ??= DatabaseService._();
    return _instance!;
  }

  Future<void> initializeDatabase() async {
    if (kIsWeb) {
      throw UnsupportedError('SQLite web platformunda desteklenmemektedir. Lütfen mobil platform kullanın.');
    }

    // SQLite FFI'yı başlat
    sqfliteFfiInit();
    // Veritabanı factory'sini ayarla
    databaseFactory = databaseFactoryFfi;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    await initializeDatabase();
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      String path = join(await getDatabasesPath(), 'prayer_tracker.db');
      return await openDatabase(
        path,
        version: 1,
        onCreate: _createDb,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      print('Veritabanı başlatma hatası: $e');
      rethrow;
    }
  }

  Future<void> _createDb(Database db, int version) async {
    try {
      // Users tablosu
      await db.execute('''
        CREATE TABLE users(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT NOT NULL UNIQUE,
          email TEXT NOT NULL UNIQUE,
          password TEXT NOT NULL,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
      ''');

      // Fasting records tablosu
      await db.execute('''
        CREATE TABLE fasting_records(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          date DATE NOT NULL,
          completed BOOLEAN DEFAULT 0,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (user_id) REFERENCES users (id)
        )
      ''');
      
      print('Veritabanı tabloları başarıyla oluşturuldu');
    } catch (e) {
      print('Tablo oluşturma hatası: $e');
      rethrow;
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < newVersion) {
      await db.execute('DROP TABLE IF EXISTS fasting_records');
      await db.execute('DROP TABLE IF EXISTS users');
      await _createDb(db, newVersion);
    }
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<bool> registerUser(String username, String email, String password) async {
    try {
      if (kIsWeb) {
        throw UnsupportedError('SQLite web platformunda desteklenmemektedir. Lütfen mobil platform kullanın.');
      }

      final db = await database;
      final hashedPassword = _hashPassword(password);
      
      // Kullanıcı adı ve email kontrolü
      final existingUser = await db.query(
        'users',
        where: 'username = ? OR email = ?',
        whereArgs: [username, email],
      );

      if (existingUser.isNotEmpty) {
        print('Kullanıcı zaten mevcut: $username veya $email');
        return false;
      }

      // Yeni kullanıcı kaydı
      final result = await db.insert(
        'users',
        {
          'username': username,
          'email': email,
          'password': hashedPassword,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      if (result > 0) {
        print('Kullanıcı başarıyla kaydedildi: $username (ID: $result)');
        return true;
      } else {
        print('Kullanıcı kaydı başarısız oldu: $username');
        return false;
      }
    } catch (e, stackTrace) {
      print('Kullanıcı kayıt hatası detayı: $e');
      print('Hata stack trace: $stackTrace');
      print('Kullanıcı bilgileri: username=$username, email=$email');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    try {
      if (kIsWeb) {
        throw UnsupportedError('SQLite web platformunda desteklenmemektedir. Lütfen mobil platform kullanın.');
      }

      final db = await database;
      final hashedPassword = _hashPassword(password);
      
      final results = await db.query(
        'users',
        where: 'email = ? AND password = ?',
        whereArgs: [email, hashedPassword],
      );

      if (results.isEmpty) {
        return null;
      }

      final user = results.first;
      return {
        'id': user['id'],
        'username': user['username'],
        'email': user['email'],
      };
    } catch (e) {
      print('Giriş hatası: $e');
      rethrow;
    }
  }

  // Oruç kayıtları için yeni metodlar
  Future<List<Map<String, dynamic>>> getFastingRecords() async {
    try {
      final db = await database;
      return await db.query(
        'fasting_records',
        orderBy: 'date DESC',
      );
    } catch (e) {
      print('Oruç kayıtları getirme hatası: $e');
      rethrow;
    }
  }

  Future<void> updateFastingRecord(int id, bool completed) async {
    try {
      final db = await database;
      await db.update(
        'fasting_records',
        {'completed': completed ? 1 : 0},
        where: 'id = ?',
        whereArgs: [id],
      );
      print('Oruç kaydı güncellendi: id=$id, completed=$completed');
    } catch (e) {
      print('Oruç kaydı güncelleme hatası: $e');
      rethrow;
    }
  }

  Future<void> addFastingRecord(DateTime date) async {
    try {
      final db = await database;
      await db.insert(
        'fasting_records',
        {
          'date': date.toIso8601String().split('T')[0],
          'completed': 0,
        },
      );
      print('Yeni oruç kaydı eklendi: ${date.toIso8601String().split('T')[0]}');
    } catch (e) {
      print('Oruç kaydı ekleme hatası: $e');
      rethrow;
    }
  }

  Future<void> close() async {
    try {
      final db = await database;
      await db.close();
      _database = null;
    } catch (e) {
      print('Veritabanı kapatma hatası: $e');
      rethrow;
    }
  }
} 