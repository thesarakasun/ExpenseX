import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For number input
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_slidable/flutter_slidable.dart'; // <-- NEW: Import this
import '../models/account.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';

class Dashboard extends StatefulWidget {
  final DatabaseService databaseService;

  const Dashboard({super.key, required this.databaseService});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  DateTime _selectedMonth = DateTime.now();
  String _currency = "LKR";

  @override
  void initState() {
    super.initState();
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currency = prefs.getString('currency') ?? "LKR";
    });
  }

  void _changeMonth(int monthsToAdd) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + monthsToAdd, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      backgroundColor: Colors.grey[100],
      
      body: StreamBuilder<List<Account>>(
        stream: widget.databaseService.streamAccounts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No Accounts Found"));
          }

          final accounts = snapshot.data!;
          final double totalBalance = accounts.fold(0, (sum, item) => sum + item.balance);

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TOTAL BALANCE
                  _buildTotalBalanceCard(totalBalance),
                  const SizedBox(height: 20),

                  // ACCOUNTS
                  const Text("Accounts", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: accounts.length,
                      itemBuilder: (context, index) {
                        final account = accounts[index];
                        return _buildAccountCard(account.name, account.balance, _getAccountColor(account.name));
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // TRANSACTIONS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Recent Transactions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            InkWell(
                              onTap: () => _changeMonth(-1),
                              child: const Icon(Icons.chevron_left, size: 20),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('MMM yyyy').format(_selectedMonth),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => _changeMonth(1),
                              child: const Icon(Icons.chevron_right, size: 20),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  
                  StreamBuilder<List<Transaction>>(
                    stream: widget.databaseService.streamRecentTransactions(),
                    builder: (context, txSnapshot) {
                      if (!txSnapshot.hasData || txSnapshot.data!.isEmpty) {
                        return const Center(child: Text("No transactions yet.", style: TextStyle(color: Colors.grey)));
                      }

                      final allTransactions = txSnapshot.data!;
                      final transactions = allTransactions.where((tx) {
                        return tx.date.year == _selectedMonth.year && 
                               tx.date.month == _selectedMonth.month;
                      }).toList();

                      if (transactions.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          width: double.infinity,
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                          child: Center(
                            child: Text(
                              "No transactions in ${DateFormat('MMMM').format(_selectedMonth)}",
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                        );
                      }
                      
                      return Column(
                        children: transactions.map((tx) {
                          // PASS THE FULL TRANSACTION OBJECT TO THE BUILDER
                          return _buildTransactionItem(context, tx); 
                        }).toList(),
                      );
                    }
                  ),
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  // --- HELPERS ---

  Widget _buildTotalBalanceCard(double amount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.blue, Colors.blueAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Total Balance", style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 5),
          Text(
            "$_currency ${amount.toStringAsFixed(2)}",
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(String name, double balance, Color color) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet, color: color),
          const Spacer(),
          Text(name, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 4),
          Text("$_currency ${balance.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  // --- NEW: SLIDABLE TRANSACTION ITEM ---
  Widget _buildTransactionItem(BuildContext context, Transaction tx) {
    Color color = tx.type == 0 ? Colors.green : (tx.type == 1 ? Colors.red : Colors.blue);
    String sign = tx.type == 0 ? "+" : (tx.type == 1 ? "-" : "");
    IconData icon = tx.type == 0 ? Icons.arrow_downward : (tx.type == 1 ? Icons.arrow_upward : Icons.swap_horiz);
    String formattedDate = DateFormat('MMM d, h:mm a').format(tx.date);

    String accountInfo = tx.accountName;
    if (tx.type == 2 && tx.destinationAccountName != null) {
      accountInfo = "${tx.accountName} ➝ ${tx.destinationAccountName}";
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Slidable(
        key: ValueKey(tx.id),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            // EDIT BUTTON
            SlidableAction(
              onPressed: (context) => _showEditDialog(context, tx),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              icon: Icons.edit,
              label: 'Edit',
            ),
            // DELETE BUTTON
            SlidableAction(
              onPressed: (context) => _deleteTransaction(context, tx.id),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Delete',
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12), // Same radius as card
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color),
            ),
            title: Text(tx.categoryName ?? "Transfer", style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("$accountInfo  •  $formattedDate", style: const TextStyle(fontSize: 12, color: Colors.grey)), 
            trailing: Text(
              "$sign $_currency ${tx.amount.toStringAsFixed(0)}",
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ),
      ),
    );
  }
  
  // --- ACTIONS ---
  
  void _deleteTransaction(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Transaction?"),
        content: const Text("This will reverse the balance effect on your accounts."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              await widget.databaseService.deleteTransaction(id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, Transaction tx) {
    final TextEditingController amountController = TextEditingController(text: tx.amount.toStringAsFixed(0));
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Edit Amount"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Only the amount can be edited. This will adjust your account balance accordingly.", style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 15),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                prefixText: "$_currency ",
                border: const OutlineInputBorder(),
                label: const Text("New Amount"),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final double? newAmount = double.tryParse(amountController.text);
              if (newAmount == null || newAmount <= 0) return;

              await widget.databaseService.updateTransactionAmount(tx.id, newAmount);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
            child: const Text("Save"),
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
}