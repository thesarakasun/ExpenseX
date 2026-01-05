import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart'; // <-- NEW
import '../models/category.dart';
import '../models/account.dart';
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
  String _currency = "LKR"; // <-- NEW: Default

  final TextEditingController _amountController = TextEditingController();

  String? _selectedCategory;
  String? _selectedAccount;
  String? _selectedFromAccount;
  String? _selectedToAccount;

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
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Category>>(
      stream: widget.databaseService.streamCategories(),
      builder: (context, catSnapshot) {
        
        return StreamBuilder<List<Account>>(
          stream: widget.databaseService.streamAccounts(),
          builder: (context, accSnapshot) {
            
            if (!catSnapshot.hasData || !accSnapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final categories = catSnapshot.data!;
            final accounts = accSnapshot.data!;

            // DATA PROCESSING
            final incomeCats = categories.where((c) => !c.isExpense).map((c) => c.name).toList();
            final expenseCats = categories.where((c) => c.isExpense).map((c) => c.name).toList();
            final accountNames = accounts.map((a) => a.name).toList();

            // Setup Defaults
            if (_selectedAccount == null && accountNames.isNotEmpty) _selectedAccount = accountNames.first;
            if (_selectedFromAccount == null && accountNames.isNotEmpty) _selectedFromAccount = accountNames.first;
            if (_selectedToAccount == null && accountNames.isNotEmpty) {
               _selectedToAccount = accountNames.length > 1 ? accountNames[1] : accountNames.first;
            }

            // Decide which list to show
            List<String> currentCatList = _typeIndex == 0 ? incomeCats : expenseCats;
            
            // Valid category check
            if ((_selectedCategory == null || !currentCatList.contains(_selectedCategory)) && currentCatList.isNotEmpty) {
              _selectedCategory = currentCatList.first;
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
                  // Handle Bar
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tabs
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

                  // Amount Input
                  const Text("Amount", style: TextStyle(fontWeight: FontWeight.bold)),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      hintText: "$_currency 0", // <-- UPDATED: Shows "USD 0" etc.
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.attach_money),
                    ),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),

                  // DYNAMIC FORM CONTENT
                  if (accountNames.isEmpty) 
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text("Please add an Account in Profile first!", style: TextStyle(color: Colors.red)),
                    )
                  else if (_typeIndex == 2) ...[
                    // TRANSFER UI
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("From", style: TextStyle(fontWeight: FontWeight.bold)),
                              _buildDropdown(accountNames, _selectedFromAccount!, (val) {
                                setState(() => _selectedFromAccount = val!);
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
                              _buildDropdown(
                                accountNames.where((a) => a != _selectedFromAccount).toList(), 
                                _selectedToAccount!, 
                                (val) => setState(() => _selectedToAccount = val!)
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // INCOME / EXPENSE UI
                    if (currentCatList.isEmpty)
                       Padding(
                        padding: const EdgeInsets.only(bottom: 15),
                        child: Text(
                          "No ${_typeIndex == 0 ? 'Income' : 'Expense'} categories found. Add some in Profile!",
                          style: const TextStyle(color: Colors.red),
                        ),
                      )
                    else ...[
                      const Text("Category", style: TextStyle(fontWeight: FontWeight.bold)),
                      _buildDropdown(currentCatList, _selectedCategory!, (val) {
                        setState(() => _selectedCategory = val!);
                      }),
                      const SizedBox(height: 15),
                    ],

                    const Text("Account", style: TextStyle(fontWeight: FontWeight.bold)),
                    _buildDropdown(accountNames, _selectedAccount!, (val) {
                      setState(() => _selectedAccount = val!);
                    }),
                  ],

                  const SizedBox(height: 25),

                  // --- SAVE BUTTON ---
                  ElevatedButton(
                    onPressed: () async {
                      if (accountNames.isEmpty) return; 

                      final double? amount = double.tryParse(_amountController.text);

                      // 1. Basic Validation
                      if (amount == null || amount <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please enter a valid amount")),
                        );
                        return;
                      }

                      // 2. Check Balance Logic
                      if (_typeIndex == 1 || _typeIndex == 2) {
                        final accountToCheck = _typeIndex == 2 ? _selectedFromAccount! : _selectedAccount!;
                        final double currentBalance = await widget.databaseService.getBalance(accountToCheck);

                        if (amount > currentBalance) {
                          if (context.mounted) {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Insufficient Funds", style: TextStyle(color: Colors.red)),
                                content: Text(
                                  // UPDATED: Use _currency here
                                  "You cannot spend $_currency ${amount.toStringAsFixed(0)}.\n\n"
                                  "$accountToCheck only has $_currency ${currentBalance.toStringAsFixed(0)} available.",
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("OK", style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            );
                          }
                          return;
                        }
                      }

                      // 3. Save
                      await widget.databaseService.saveTransaction(
                        amount: amount,
                        note: "Transaction",
                        type: _typeIndex,
                        accountName: _typeIndex == 2 ? _selectedFromAccount! : _selectedAccount!,
                        categoryName: _typeIndex == 2 ? null : _selectedCategory,
                        destinationAccountName: _typeIndex == 2 ? _selectedToAccount : null,
                      );

                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
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
        );
      }
    );
  }

  Widget _buildTab(String text, int index, Color color) {
    bool isSelected = _typeIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _typeIndex = index;
            // Force re-evaluation of default category in build()
             _selectedCategory = null; 
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
    String displayValue = selectedValue;
    if (!items.contains(selectedValue) && items.isNotEmpty) {
      displayValue = items.first;
    } else if (items.isEmpty) {
      return const Text("No options available"); 
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
          value: displayValue,
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