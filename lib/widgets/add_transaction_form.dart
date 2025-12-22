import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/database_service.dart';

class AddTransactionForm extends StatefulWidget {
  final DatabaseService databaseService;

  const AddTransactionForm({super.key, required this.databaseService});

  @override
  State<AddTransactionForm> createState() => _AddTransactionFormState();
}

class _AddTransactionFormState extends State<AddTransactionForm> {
  // 0=Income, 1=Expense, 2=Transfer
  int _typeIndex = 1; 

  final TextEditingController _amountController = TextEditingController();

  final List<String> _incomeCategories = ["Salary", "Business", "Interest", "Gift"];
  final List<String> _expenseCategories = ["Food", "Transport", "Bills", "Shopping", "Health"];
  
  final List<String> _accounts = ["Cash", "HNB Bank", "Wallet", "Savings"];

  String? _selectedCategory;
  String _selectedAccount = "Cash";
  String _selectedFromAccount = "HNB Bank";
  String _selectedToAccount = "Cash";

  @override
  void initState() {
    super.initState();
    _selectedCategory = _expenseCategories.first;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final availableToAccounts = _accounts.where((a) => a != _selectedFromAccount).toList();

    if (_selectedToAccount == _selectedFromAccount) {
      _selectedToAccount = availableToAccounts.first;
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(25)),
            child: Row(
              children: [
                _buildTab("Income", 0, Colors.green),
                _buildTab("Expense", 1, Colors.red),
                _buildTab("Transfer", 2, Colors.blue),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text("Amount", style: TextStyle(fontWeight: FontWeight.bold)),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: "LKR 0",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.attach_money),
            ),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),

          if (_typeIndex == 2) ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("From", style: TextStyle(fontWeight: FontWeight.bold)),
                      _buildDropdown(_accounts, _selectedFromAccount, (val) {
                        setState(() {
                          _selectedFromAccount = val!;
                        });
                      }),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.arrow_forward, color: Colors.blue),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("To", style: TextStyle(fontWeight: FontWeight.bold)),
                      _buildDropdown(availableToAccounts, _selectedToAccount, (val) {
                        setState(() => _selectedToAccount = val!);
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            const Text("Category", style: TextStyle(fontWeight: FontWeight.bold)),
            _buildDropdown(
              _typeIndex == 0 ? _incomeCategories : _expenseCategories, 
              _selectedCategory ?? "", 
              (val) {
                setState(() => _selectedCategory = val!);
              }
            ),
            const SizedBox(height: 15),

            const Text("Account", style: TextStyle(fontWeight: FontWeight.bold)),
            _buildDropdown(_accounts, _selectedAccount, (val) {
              setState(() => _selectedAccount = val!);
            }),
          ],

          const SizedBox(height: 25),

          // --- SAVE BUTTON ---
ElevatedButton(
            onPressed: () async {
              final double? amount = double.tryParse(_amountController.text);

              // 1. Basic Validation
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please enter a valid amount")),
                );
                return;
              }

              // 2. Check Balance (The Guard Clause)
              if (_typeIndex == 1 || _typeIndex == 2) {
                final accountToCheck = _typeIndex == 2 ? _selectedFromAccount : _selectedAccount;
                final double currentBalance = await widget.databaseService.getBalance(accountToCheck);

                if (amount > currentBalance) {
                  // ERROR: Show an ALERT DIALOG instead of a SnackBar
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Insufficient Funds", style: TextStyle(color: Colors.red)),
                        content: Text(
                          "You cannot spend LKR ${amount.toStringAsFixed(0)}.\n\n"
                          "$accountToCheck only has LKR ${currentBalance.toStringAsFixed(0)} available.",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context), // Close the popup
                            child: const Text("OK", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  }
                  return; // Stop here. Do not save.
                }
              }

              // 3. Save & Close (If balance was fine)
              await widget.databaseService.saveTransaction(
                amount: amount,
                note: "Transaction",
                type: _typeIndex,
                accountName: _typeIndex == 2 ? _selectedFromAccount : _selectedAccount,
                categoryName: _typeIndex == 2 ? null : _selectedCategory,
                destinationAccountName: _typeIndex == 2 ? _selectedToAccount : null,
              );

              if (context.mounted) {
                Navigator.pop(context); // Close the form
              }
            },
            // ... (keep your style code here) ...
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("SAVE", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildTab(String text, int index, Color color) {
    bool isSelected = _typeIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _typeIndex = index;
            if (index == 0) _selectedCategory = _incomeCategories.first;
            if (index == 1) _selectedCategory = _expenseCategories.first;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(List<String> items, String selectedValue, Function(String?) onChanged) {
    if (!items.contains(selectedValue) && items.isNotEmpty) {
      selectedValue = items.first;
    }
    return Container(
      margin: const EdgeInsets.only(top: 5),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedValue,
          isExpanded: true,
          items: items.map((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}