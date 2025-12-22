import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Needed for Date Formatting
import '../models/account.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';

class Dashboard extends StatelessWidget {
  final DatabaseService databaseService;

  const Dashboard({super.key, required this.databaseService});

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
        stream: databaseService.streamAccounts(),
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
                  
                  // --- SECTION A: TOTAL BALANCE ---
                  _buildTotalBalanceCard(totalBalance),
                  
                  const SizedBox(height: 20),

                  // --- SECTION B: ACCOUNTS ---
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

                  // --- SECTION C: RECENT TRANSACTIONS ---
                  const Text("Recent Transactions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  
                  StreamBuilder<List<Transaction>>(
                    stream: databaseService.streamRecentTransactions(),
                    builder: (context, txSnapshot) {
                      if (!txSnapshot.hasData || txSnapshot.data!.isEmpty) {
                        return const Center(child: Text("No transactions yet.", style: TextStyle(color: Colors.grey)));
                      }

                      final transactions = txSnapshot.data!;
                      
                      return Column(
                        children: transactions.take(10).map((tx) { // Increased to show last 10
                          // 1. Color & Icon Logic
                          Color color = tx.type == 0 ? Colors.green : (tx.type == 1 ? Colors.red : Colors.blue);
                          String sign = tx.type == 0 ? "+" : (tx.type == 1 ? "-" : "");
                          IconData icon = tx.type == 0 ? Icons.arrow_downward : (tx.type == 1 ? Icons.arrow_upward : Icons.swap_horiz);
                          
                          // 2. Format Date (e.g., "Dec 19, 10:30 AM")
                          String formattedDate = DateFormat('MMM d, h:mm a').format(tx.date);

                          // 3. Construct Subtitle (Account • Date)
                          String accountInfo = tx.accountName;
                          
                          // If it's a transfer, show "HNB -> Wallet"
                          if (tx.type == 2 && tx.destinationAccountName != null) {
                            accountInfo = "${tx.accountName} ➝ ${tx.destinationAccountName}";
                          }

                          return _buildTransactionItem(
                            tx.categoryName ?? "Transfer", // Title (e.g., Food)
                            "$accountInfo  •  $formattedDate", // Subtitle (e.g., Cash • Dec 19, 10:30 AM)
                            "$sign LKR ${tx.amount.toStringAsFixed(0)}", // Amount
                            color,
                            icon
                          );
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
            "LKR ${amount.toStringAsFixed(2)}",
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
          Text("LKR ${balance.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(String title, String subtitle, String amount, Color color, IconData icon) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)), // Made text slightly smaller/grey
        trailing: Text(
          amount,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15),
        ),
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