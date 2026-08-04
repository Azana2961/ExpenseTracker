import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../features/expenses/models/expense_model.dart';

class DatabaseHelper {
  // Create a Singleton instance
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // Open the database or return the existing connection
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('hostel_expenses.db');
    return _database!;
  }

  // Initialize the database file on the physical phone storage
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  // Create the actual SQL tables on the very first install
  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE expenses (
      id TEXT PRIMARY KEY,
      date TEXT NOT NULL,
      label TEXT NOT NULL,
      amount REAL NOT NULL,
      category TEXT NOT NULL,
      isCleared INTEGER NOT NULL
    )
    ''');
  }

  // --- CRUD OPERATIONS (Create, Read, Update, Delete) ---

  // 1. ADD: Save a new transaction to the phone
  Future<void> insertExpense(ExpenseModel expense) async {
    final db = await instance.database;
    await db.insert('expenses', expense.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // 2. READ: Get every single past transaction (sorted newest to oldest)
  Future<List<ExpenseModel>> getAllExpenses() async {
    final db = await instance.database;
    final result = await db.query('expenses', orderBy: 'date DESC');
    
    return result.map((json) => ExpenseModel.fromMap(json)).toList();
  }

  // 3. UPDATE: Change an existing transaction (e.g., mark Loan as cleared)
  Future<void> updateExpense(ExpenseModel expense) async {
    final db = await instance.database;
    await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  // 4. DELETE: Remove a transaction if a mistake was made
  Future<void> deleteExpense(String id) async {
    final db = await instance.database;
    await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}