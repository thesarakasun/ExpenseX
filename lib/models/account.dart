class Account {
  int id;
  String name;
  double balance;
  String type; // "Cash", "Bank", "Wallet"
  String currency;

  Account({
    required this.id,
    required this.name,
    required this.balance,
    required this.type,
    required this.currency,
  });

  // Empty constructor for creating new instances easily
  factory Account.empty() {
    return Account(
        id: DateTime.now().millisecondsSinceEpoch,
        name: "",
        balance: 0.0,
        type: "Cash",
        currency: "LKR");
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
      'type': type,
      'currency': currency,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'],
      name: map['name'],
      balance: map['balance'],
      type: map['type'],
      currency: map['currency'] ?? "LKR",
    );
  }
}