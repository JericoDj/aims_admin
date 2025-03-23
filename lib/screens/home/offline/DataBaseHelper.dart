import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const String tableName = 'offline_data';
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'offline_data.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            storageCode TEXT,
            serialNo TEXT,
            itemName TEXT,
            brand TEXT,
            expirationDate TEXT,
            unitMeasurement TEXT,
            specification TEXT,
            quantity INTEGER,
            timestamp TEXT
          )
        ''');
      },
    );
  }

  // ✅ Get single item by ID
  Future<Map<String, dynamic>?> getDataById(int id) async {
    final db = await database;
    final results = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<bool> updateData(int id, Map<String, dynamic> newData) async {
    final db = await database;
    final rowsAffected = await db.update(
      tableName, // ✅ now it's using 'offline_data'
      newData,
      where: 'id = ?',
      whereArgs: [id],
    );
    return rowsAffected > 0;
  }


  // ✅ Insert data and return generated ID
  Future<int> insertData(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(tableName, data);
  }

  // ✅ Update quantity specifically
  Future<void> updateQuantity(int id, int newQuantity) async {
    await updateData(id, {'quantity': newQuantity});
  }

  // ✅ Delete by ID with success status
  Future<bool> deleteDataById(int id) async {
    final db = await database;
    final count = await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    return count > 0;
  }

  Future<List<Map<String, dynamic>>> getAllData() async {
    final db = await database;
    return await db.query(tableName);
  }

  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete(tableName);
  }
}