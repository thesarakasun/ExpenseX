import 'package:isar/isar.dart';

part 'transaction.g.dart';

@Collection()
class Transaction {
  Id id = Isar.autoIncrement;

  late double amount;

  late DateTime date; // Date & Time of transaction

  late String note;

  // 0=Income, 1=Expense, 2=Transfer
  late int type; 

  // --- Relationships (Linking tables) ---
  
  // Which Category? (e.g., Food) - Nullable because Transfers don't have categories
  late String? categoryName; 
  
  // Which Account? (e.g., HNB)
  late String accountName; 

  // If Transfer, where did it go?
  late String? destinationAccountName; 
} 