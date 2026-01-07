class Transaction {
  int id;
  double amount;
  String note;
  DateTime date;
  int type; // 0=Income, 1=Expense, 2=Transfer
  String accountName;
  String? categoryName;
  String? destinationAccountName; // For transfers

  Transaction({
    required this.id,
    required this.amount,
    required this.note,
    required this.date,
    required this.type,
    required this.accountName,
    this.categoryName,
    this.destinationAccountName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'note': note,
      'date': date.millisecondsSinceEpoch, // Store date as timestamp
      'type': type,
      'accountName': accountName,
      'categoryName': categoryName,
      'destinationAccountName': destinationAccountName,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      amount: map['amount'],
      note: map['note'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      type: map['type'],
      accountName: map['accountName'],
      categoryName: map['categoryName'],
      destinationAccountName: map['destinationAccountName'],
    );
  }
}