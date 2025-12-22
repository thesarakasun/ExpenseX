import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../models/transaction.dart';

class DatabaseService {
  late Isar isar;

  // --- 1. INITIALIZE DATABASE ---
  Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    
    isar = await Isar.open(
      [AccountSchema, CategorySchema, TransactionSchema],
      directory: dir.path,
    );

    // Check if we need to add default data (First run only)
    if (await isar.accounts.count() == 0) {
      await _seedDefaultData();
    }
  }

  // --- 2. SAVE TRANSACTION LOGIC ---
  Future<void> saveTransaction({
    required double amount,
    required String note,
    required int type, // 0=Income, 1=Expense, 2=Transfer
    required String accountName,
    String? categoryName,
    String? destinationAccountName, // Only for transfers
  }) async {
    
    final newTransaction = Transaction()
      ..amount = amount
      ..date = DateTime.now()
      ..note = note
      ..type = type
      ..categoryName = categoryName
      ..accountName = accountName
      ..destinationAccountName = destinationAccountName;

    // Use a "Write Transaction" to ensure data safety
    await isar.writeTxn(() async {
      // 1. Save the Transaction Record
      await isar.transactions.put(newTransaction);

      // 2. Update Account Balances
      if (type == 0) {
        // Income: Increase Balance
        final account = await isar.accounts.filter().nameEqualTo(accountName).findFirst();
        if (account != null) {
          account.balance += amount;
          await isar.accounts.put(account);
        }
      } else if (type == 1) {
        // Expense: Decrease Balance
        final account = await isar.accounts.filter().nameEqualTo(accountName).findFirst();
        if (account != null) {
          account.balance -= amount;
          await isar.accounts.put(account);
        }
      } else if (type == 2 && destinationAccountName != null) {
        // Transfer: Decrease From, Increase To
        final fromAccount = await isar.accounts.filter().nameEqualTo(accountName).findFirst();
        final toAccount = await isar.accounts.filter().nameEqualTo(destinationAccountName).findFirst();
        
        if (fromAccount != null && toAccount != null) {
          fromAccount.balance -= amount;
          toAccount.balance += amount;
          await isar.accounts.putAll([fromAccount, toAccount]);
        }
      }
    });
  }

// --- 3. WATCH DATA (For the Dashboard) ---
  
  // Listen to Accounts (for Total Balance & Account Cards)
  Stream<List<Account>> streamAccounts() async* {
    yield* isar.accounts.where().watch(fireImmediately: true);
  }

  // Listen to Transactions (for Recent List)
  Stream<List<Transaction>> streamRecentTransactions() async* {
    yield* isar.transactions.where().sortByDateDesc().watch(fireImmediately: true);
  }

// --- 4. CATEGORY LOGIC ---
  
  // Listen to Categories (so we can see the budget limits)
  Stream<List<Category>> streamCategories() async* {
    yield* isar.categorys.where().watch(fireImmediately: true);
  }

  // Update a Category (e.g., Set Budget)
  Future<void> updateCategoryBudget(int id, double newBudget) async {
    await isar.writeTxn(() async {
      final category = await isar.categorys.get(id);
      if (category != null) {
        category.budget = newBudget;
        await isar.categorys.put(category);
      }
    });
  }
// --- 5. GET BALANCE HELPER ---
  Future<double> getBalance(String accountName) async {
    final account = await isar.accounts.filter().nameEqualTo(accountName).findFirst();
    return account?.balance ?? 0.0;
  }

  // --- HELPER: ADD DEFAULT DATA ---
  Future<void> _seedDefaultData() async {
    final defaultAccounts = [
      Account()..name = "Cash"..type = "Cash"..balance = 0.0..currency = "LKR",
      Account()..name = "HNB Bank"..type = "Bank"..balance = 0.0..currency = "LKR",
      Account()..name = "Wallet"..type = "Wallet"..balance = 0.0..currency = "LKR",
    ];

    final defaultCategories = [
      Category()..name = "Salary"..isExpense = false..iconName = "money"..colorValue = 0xFF4CAF50,
      Category()..name = "Food"..isExpense = true..iconName = "fastfood"..colorValue = 0xFFF44336,
      Category()..name = "Transport"..isExpense = true..iconName = "commute"..colorValue = 0xFF2196F3,
      Category()..name = "Bills"..isExpense = true..iconName = "receipt"..colorValue = 0xFFFF9800,
    ];

    await isar.writeTxn(() async {
      await isar.accounts.putAll(defaultAccounts);
      await isar.categorys.putAll(defaultCategories);
    });
  }

// --- 6. MANAGE DATA (Profile Page) ---

  Future<void> saveCategory(Category category) async {
    await isar.writeTxn(() async {
      await isar.categorys.put(category);
    });
  }

  Future<void> deleteCategory(int id) async {
    await isar.writeTxn(() async {
      await isar.categorys.delete(id);
    });
  }

  Future<void> saveAccount(Account account) async {
    await isar.writeTxn(() async {
      await isar.accounts.put(account);
    });
  }

  Future<void> deleteAccount(int id) async {
    await isar.writeTxn(() async {
      await isar.accounts.delete(id);
    });
  }

// --- UTILS ---
  Future<void> cleanDb() async {
    await isar.writeTxn(() async {
      await isar.transactions.clear();
      await isar.accounts.clear();
      await isar.categorys.clear(); // Remember: spelling is 'categorys'
    });
    // Add defaults back so the app doesn't crash
    await _seedDefaultData(); 
  }
}