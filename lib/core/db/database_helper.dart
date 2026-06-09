import 'package:path/path.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:nexus/core/models/payment.dart';
import 'package:nexus/core/models/document.dart';

class DatabaseHelper {
  // Patrón Singleton para evitar múltiples conexiones abiertas en la memoria
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> databaseWithPassword(String password) async {
    if (_database != null) return _database!;

    _database = await _initDB(password);
    return _database!;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    throw Exception(
      'Database has not been initialized with a password yet. Unlock the app first.',
    );
  }

  Future<Database> _initDB(String password) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'mikes_admin_secure.db');

    return await openDatabase(
      path,
      version: 1,
      password: password,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        nextPaymentDate TEXT NOT NULL, 
        frequency TEXT NOT NULL,
        isUrgent INTEGER NOT NULL,
        isAutoPay INTEGER NOT NULL,
        iconKey TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE documents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        documentType TEXT NOT NULL,
        encryptedFilePath TEXT,
        expirationDate TEXT,
        notes TEXT
      )
    ''');
  }

  Future<int> insertPayment(Payment payment) async {
    final db = await database;
    return await db.insert(
      'payments',
      payment.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Payment>> getPayments() async {
    final db = await database;
    final result = await db.query('payments', orderBy: 'nextPaymentDate ASC');
    return result.map((json) => Payment.fromMap(json)).toList();
  }

  Future<int> updatePayment(Payment payment) async {
    final db = await database;
    return await db.update(
      'payments',
      payment.toMap(),
      where: 'id = ?',
      whereArgs: [payment.id],
    );
  }

  Future<int> deletePayment(int id) async {
    final db = await database;
    return await db.delete('payments', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertDocument(Document doc) async {
    final db = await database;
    return await db.insert('documents', doc.toMap());
  }

  Future<List<Document>> getDocuments() async {
    final db = await database;
    final maps = await db.query('documents');
    return maps.map((map) => Document.fromMap(map)).toList();
  }

  Future close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
