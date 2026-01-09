import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../models/transaction.dart' as model; 

class DatabaseService {
  static Database? _database;
  
  final _accountStreamController = StreamController<List<Account>>.broadcast();
  final _categoryStreamController = StreamController<List<Category>>.broadcast();
  final _transactionStreamController = StreamController<List<model.Transaction>>.broadcast();

  Future<void> initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'expensex.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // 1. Create Accounts Table
        await db.execute('''
          CREATE TABLE accounts(
            id INTEGER PRIMARY KEY,
            name TEXT,
            balance REAL,
            type TEXT,
            currency TEXT
          )
        ''');

        // 2. Create Categories Table
        await db.execute('''
          CREATE TABLE categories(
            id INTEGER PRIMARY KEY,
            name TEXT,
            iconName TEXT,
            colorValue INTEGER,
            isExpense INTEGER,
            budget REAL
          )
        ''');

        // 3. Create Transactions Table
        await db.execute('''
          CREATE TABLE transactions(
            id INTEGER PRIMARY KEY,
            amount REAL,
            note TEXT,
            date INTEGER,
            type INTEGER,
            accountName TEXT,
            categoryName TEXT,
            destinationAccountName TEXT
          )
        ''');

        // 4. Insert Defaults
        await _insertDefaultCategories(db);
        await _insertDefaultAccounts(db); 
      },
    );
    
    // Initial fetch
    _refreshAccounts();
    _refreshCategories();
    _refreshTransactions();
  }

  // --- STREAMS ---
  Stream<List<Account>> streamAccounts() {
    _refreshAccounts(); 
    return _accountStreamController.stream;
  }

  Stream<List<Category>> streamCategories() {
    _refreshCategories();
    return _categoryStreamController.stream;
  }

  Stream<List<model.Transaction>> streamRecentTransactions() {
    _refreshTransactions();
    return _transactionStreamController.stream;
  }

  // --- HELPERS to refresh Streams ---
  Future<void> _refreshAccounts() async {
    if (_database == null) return;
    final data = await _database!.query('accounts');
    final accounts = data.map((e) => Account.fromMap(e)).toList();
    _accountStreamController.add(accounts);
  }

  Future<void> _refreshCategories() async {
    if (_database == null) return;
    final data = await _database!.query('categories');
    final categories = data.map((e) => Category.fromMap(e)).toList();
    _categoryStreamController.add(categories);
  }

  Future<void> _refreshTransactions() async {
    if (_database == null) return;
    final data = await _database!.query('transactions', orderBy: 'date DESC');
    final txs = data.map((e) => model.Transaction.fromMap(e)).toList();
    _transactionStreamController.add(txs);
  }

  // --- ACCOUNT METHODS ---
  Future<void> saveAccount(Account account) async {
    await _database!.insert('accounts', account.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    _refreshAccounts();
  }

  Future<void> deleteAccount(int id) async {
    await _database!.delete('accounts', where: 'id = ?', whereArgs: [id]);
    _refreshAccounts();
  }

  Future<double> getBalance(String accountName) async {
    final result = await _database!.query('accounts', where: 'name = ?', whereArgs: [accountName]);
    if (result.isNotEmpty) return result.first['balance'] as double;
    return 0.0;
  }

  // --- CATEGORY METHODS ---
  Future<void> saveCategory(Category category) async {
    await _database!.insert('categories', category.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    _refreshCategories();
  }
  
  Future<void> deleteCategory(int id) async {
     await _database!.delete('categories', where: 'id = ?', whereArgs: [id]);
     _refreshCategories();
  }

  Future<void> updateCategoryBudget(int id, double newBudget) async {
    await _database!.update('categories', {'budget': newBudget}, where: 'id = ?', whereArgs: [id]);
    _refreshCategories();
  }

  // --- TRANSACTION METHODS ---
  Future<void> saveTransaction({
    required double amount,
    required String note,
    required int type,
    required String accountName,
    String? categoryName,
    String? destinationAccountName,
  }) async {
    final tx = model.Transaction(
      id: DateTime.now().millisecondsSinceEpoch,
      amount: amount,
      note: note,
      date: DateTime.now(),
      type: type,
      accountName: accountName,
      categoryName: categoryName,
      destinationAccountName: destinationAccountName,
    );

    await _database!.insert('transactions', tx.toMap());

    if (type == 0) {
      await _updateBalance(accountName, amount);
    } else if (type == 1) {
      await _updateBalance(accountName, -amount);
    } else if (type == 2 && destinationAccountName != null) {
      await _updateBalance(accountName, -amount);
      await _updateBalance(destinationAccountName, amount);
    }

    _refreshTransactions();
    _refreshAccounts();
  }

  // --- NEW: EDIT & DELETE LOGIC ---

  // 1. Delete Transaction and Fix Balance
  Future<void> deleteTransaction(int id) async {
    final db = _database!;
    // Get the transaction first to know how much to revert
    final List<Map<String, dynamic>> result = await db.query('transactions', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return;
    
    final tx = model.Transaction.fromMap(result.first);

    // Revert the balance effect
    await _revertBalance(tx.accountName, tx.amount, tx.type, tx.destinationAccountName);

    // Delete the row
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
    
    _refreshTransactions();
    _refreshAccounts();
  }

  // 2. Edit Amount and Fix Balance
  Future<void> updateTransactionAmount(int id, double newAmount) async {
    final db = _database!;
    // Get old transaction
    final List<Map<String, dynamic>> result = await db.query('transactions', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return;
    
    final tx = model.Transaction.fromMap(result.first);

    // 1. Undo the Old Amount
    await _revertBalance(tx.accountName, tx.amount, tx.type, tx.destinationAccountName);

    // 2. Apply the New Amount
    if (tx.type == 0) { // Income
      await _updateBalance(tx.accountName, newAmount);
    } else if (tx.type == 1) { // Expense
      await _updateBalance(tx.accountName, -newAmount);
    } else if (tx.type == 2 && tx.destinationAccountName != null) { // Transfer
      await _updateBalance(tx.accountName, -newAmount);
      await _updateBalance(tx.destinationAccountName!, newAmount);
    }

    // 3. Update the Transaction Row
    await db.update('transactions', {'amount': newAmount}, where: 'id = ?', whereArgs: [id]);

    _refreshTransactions();
    _refreshAccounts();
  }

  // Helper to undo a transaction's effect
  Future<void> _revertBalance(String accountName, double amount, int type, String? destAccount) async {
    if (type == 0) {
      // Was Income (Added), so we Deduct it
      await _updateBalance(accountName, -amount);
    } else if (type == 1) {
      // Was Expense (Deducted), so we Add it back
      await _updateBalance(accountName, amount);
    } else if (type == 2 && destAccount != null) {
      // Was Transfer, reverse both
      await _updateBalance(accountName, amount); // Give back to source
      await _updateBalance(destAccount, -amount); // Take from destination
    }
  }

  Future<void> _updateBalance(String accountName, double change) async {
    final currentBal = await getBalance(accountName);
    await _database!.update('accounts', {'balance': currentBal + change}, where: 'name = ?', whereArgs: [accountName]);
  }

  Future<void> cleanDb() async {
    await _database!.delete('transactions');
    await _database!.delete('accounts');
    await _database!.delete('categories');
    
    // Restore defaults
    await _insertDefaultCategories(_database!);
    await _insertDefaultAccounts(_database!); 
    
    _refreshAccounts();
    _refreshCategories();
    _refreshTransactions();
  }

  // --- DEFAULT DATA ---
  static Future<void> _insertDefaultCategories(Database db) async {
    final defaults = [
      Category(id: 1, name: "Salary", iconName: "attach_money", colorValue: Colors.green.value, isExpense: false),
      Category(id: 2, name: "Business", iconName: "business", colorValue: Colors.blue.value, isExpense: false),
      Category(id: 3, name: "Gift", iconName: "card_giftcard", colorValue: Colors.purple.value, isExpense: false),
      Category(id: 4, name: "Food", iconName: "fastfood", colorValue: Colors.orange.value, isExpense: true),
      Category(id: 5, name: "Transport", iconName: "directions_bus", colorValue: Colors.blueAccent.value, isExpense: true),
      Category(id: 6, name: "Shopping", iconName: "shopping_cart", colorValue: Colors.pink.value, isExpense: true),
      Category(id: 7, name: "Bills", iconName: "receipt", colorValue: Colors.red.value, isExpense: true),
      Category(id: 8, name: "Health", iconName: "medical_services", colorValue: Colors.teal.value, isExpense: true),
    ];
    for (var cat in defaults) {
      await db.insert('categories', cat.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  static Future<void> _insertDefaultAccounts(Database db) async {
    await db.insert('accounts', {
      'id': 1, 
      'name': "Cash",
      'balance': 0.0,
      'type': "Cash",
      'currency': "LKR"
    });
    await db.insert('accounts', {
      'id': 2, 
      'name': "Wallet",
      'balance': 0.0,
      'type': "Wallet",
      'currency': "LKR"
    });
  }
}