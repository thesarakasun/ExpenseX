import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Needed for number input
import 'package:shared_preferences/shared_preferences.dart'; // <-- NEW
import '../models/account.dart';
import '../services/database_service.dart';

class ManageAccountsScreen extends StatefulWidget {
  final DatabaseService databaseService;

  const ManageAccountsScreen({super.key, required this.databaseService});

  @override
  State<ManageAccountsScreen> createState() => _ManageAccountsScreenState();
}

class _ManageAccountsScreenState extends State<ManageAccountsScreen> {
  String _currency = "LKR"; // <-- NEW: Default Currency

  @override
  void initState() {
    super.initState();
    _loadCurrency(); // <-- NEW: Load on start
  }

  // --- NEW: Load Saved Currency ---
  Future<void> _loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currency = prefs.getString('currency') ?? "LKR";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Accounts', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[100],
      body: StreamBuilder<List<Account>>(
        stream: widget.databaseService.streamAccounts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final accounts = snapshot.data!;

          if (accounts.isEmpty) {
            return const Center(child: Text("No accounts found."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              final account = accounts[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getAccountColor(account.name).withOpacity(0.2),
                    child: Icon(Icons.account_balance_wallet, color: _getAccountColor(account.name)),
                  ),
                  title: Text(account.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  // UPDATED: Use _currency variable
                  subtitle: Text("$_currency ${account.balance.toStringAsFixed(0)}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showAccountDialog(context, widget.databaseService, account),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteAccount(context, widget.databaseService, account.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showAccountDialog(context, widget.databaseService, null),
      ),
    );
  }

  // --- HELPERS ---

  void _deleteAccount(BuildContext context, DatabaseService db, int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Account?"),
        content: const Text("This will delete the account but keep the transaction history (as text)."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              await db.deleteAccount(id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Color _getAccountColor(String accountName) {
    switch (accountName) {
      case "HNB Bank": return Colors.orange;
      case "Wallet": return Colors.green;
      case "Savings": return Colors.purple;
      default: return Colors.blue;
    }
  }

  // --- DIALOG FOR ADD/EDIT ---
  void _showAccountDialog(BuildContext context, DatabaseService db, Account? account) {
    final nameController = TextEditingController(text: account?.name ?? "");
    final balanceController = TextEditingController(text: account?.balance.toStringAsFixed(0) ?? "0");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(account == null ? "New Account" : "Edit Account"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Account Name", 
                hintText: "e.g., Credit Card", 
                border: OutlineInputBorder()
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: balanceController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: "Current Balance", 
                prefixText: "$_currency ", // <-- UPDATED: Use dynamic currency
                border: const OutlineInputBorder()
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) return;

              final double balance = double.tryParse(balanceController.text) ?? 0.0;

              final newAccount = Account()
                ..id = account?.id ?? DateTime.now().millisecondsSinceEpoch
                ..name = nameController.text
                ..balance = balance
                ..type = account?.type ?? "Cash" 
                ..currency = _currency; // <-- UPDATED: Save dynamic currency

              await db.saveAccount(newAccount);
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}