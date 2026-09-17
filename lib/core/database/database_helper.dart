import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../features/expenses/models/expense_model.dart';
import '../../features/expenses/models/repayment_model.dart';

class DatabaseHelper {
  // Singleton instance
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // Open the database (or return an existing connection)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('hostel_expenses.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,         // ← bumped from 2 → 3
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  // ── Schema creation (fresh install) ──────────────────────────────────────
  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE expenses (
      id TEXT PRIMARY KEY,
      date TEXT NOT NULL,
      label TEXT NOT NULL,
      amount REAL NOT NULL,
      category TEXT NOT NULL,
      isCleared INTEGER NOT NULL,
      amountPaid REAL NOT NULL DEFAULT 0
    )
    ''');

    await db.execute('''
    CREATE TABLE repayments (
      id TEXT PRIMARY KEY,
      parentId TEXT NOT NULL,
      category TEXT NOT NULL,
      amount REAL NOT NULL,
      date TEXT NOT NULL,
      FOREIGN KEY (parentId) REFERENCES expenses(id) ON DELETE CASCADE
    )
    ''');
  }

  // ── Migrations (upgrade existing installs) ───────────────────────────────
  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // v1 → v2: Add amountPaid column
      await db.execute(
        'ALTER TABLE expenses ADD COLUMN amountPaid REAL NOT NULL DEFAULT 0',
      );
    }
    if (oldVersion < 3) {
      // v2 → v3: Add repayments table
      await db.execute('''
      CREATE TABLE IF NOT EXISTS repayments (
        id TEXT PRIMARY KEY,
        parentId TEXT NOT NULL,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        FOREIGN KEY (parentId) REFERENCES expenses(id) ON DELETE CASCADE
      )
      ''');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  EXPENSE CRUD
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> insertExpense(ExpenseModel expense) async {
    final db = await instance.database;
    await db.insert(
      'expenses',
      expense.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ExpenseModel>> getAllExpenses() async {
    final db = await instance.database;
    final result = await db.query('expenses', orderBy: 'date DESC');
    return result.map((json) => ExpenseModel.fromMap(json)).toList();
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    final db = await instance.database;
    await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<void> deleteExpense(String id) async {
    final db = await instance.database;
    // Also delete all repayments for this expense
    await db.delete('repayments', where: 'parentId = ?', whereArgs: [id]);
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  REPAYMENT CRUD
  // ═══════════════════════════════════════════════════════════════════════════

  /// Save a new repayment event (the day cash physically moved).
  Future<void> insertRepayment(RepaymentModel repayment) async {
    final db = await instance.database;
    await db.insert(
      'repayments',
      repayment.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Load every repayment for one parent expense.
  Future<List<RepaymentModel>> getRepaymentsForParent(String parentId) async {
    final db = await instance.database;
    final result = await db.query(
      'repayments',
      where: 'parentId = ?',
      whereArgs: [parentId],
      orderBy: 'date ASC',
    );
    return result.map((m) => RepaymentModel.fromMap(m)).toList();
  }

  /// Load ALL repayments (used to build the full cash-flow picture).
  Future<List<RepaymentModel>> getAllRepayments() async {
    final db = await instance.database;
    final result = await db.query('repayments', orderBy: 'date DESC');
    return result.map((m) => RepaymentModel.fromMap(m)).toList();
  }

  /// Remove all repayments for a parent expense (e.g., when parent is deleted).
  Future<void> deleteRepaymentsForParent(String parentId) async {
    final db = await instance.database;
    await db.delete('repayments', where: 'parentId = ?', whereArgs: [parentId]);
  }

  /// Delete a single repayment by its own ID.
  Future<void> deleteRepayment(String id) async {
    final db = await instance.database;
    await db.delete('repayments', where: 'id = ?', whereArgs: [id]);
  }
}