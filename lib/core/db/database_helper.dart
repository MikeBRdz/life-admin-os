import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/payment.dart';

class DatabaseHelper {
  // Patrón Singleton para evitar múltiples conexiones abiertas en la memoria
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('life_admin.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
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
  }

  Future<int> insertPayment(Payment payment) async {
    final db = await instance.database;
    return await db.insert('payments', payment.toMap());
  }

  Future<List<Payment>> getPayments() async {
    final db = await instance.database;
    final result = await db.query('payments', orderBy: 'nextPaymentDate ASC');
    return result.map((json) => Payment.fromMap(json)).toList();
  }

  Future<int> updatePayment(Payment payment) async {
    final db = await instance.database;
    return await db.update(
      'payments',
      payment.toMap(),
      where: 'id = ?',
      whereArgs: [payment.id],
    );
  }

  Future<int> deletePayment(int id) async {
    final db = await instance.database;
    return await db.delete('payments', where: 'id = ?', whereArgs: [id]);
  }
}
