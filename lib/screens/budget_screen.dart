import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
//import 'package:intl/intl.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';

class BudgetScreen extends StatefulWidget {
  final DatabaseService databaseService;

  const BudgetScreen({super.key, required this.databaseService});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Budget', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[100],
      body: StreamBuilder<List<Category>>(
        stream: widget.databaseService.streamCategories(),
        builder: (context, catSnapshot) {
          if (!catSnapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final categories = catSnapshot.data!;
          // 1. Get ALL expense categories (Food, Transport, etc.)
          final expenseCategories = categories.where((c) => c.isExpense).toList();
          
          // 2. Separate active budgets just for the list display below
          final activeBudgets = expenseCategories.where((c) => c.budget > 0).toList();

          return StreamBuilder<List<Transaction>>(
            stream: widget.databaseService.streamRecentTransactions(),
            builder: (context, txSnapshot) {
              if (!txSnapshot.hasData) return const Center(child: CircularProgressIndicator());

              final transactions = txSnapshot.data!;
              final now = DateTime.now();

              // 3. Calculate Spending per Category for THIS MONTH
              final Map<String, double> spendingMap = {};
              for (var tx in transactions) {
                if (tx.type == 1 && tx.date.month == now.month && tx.date.year == now.year) {
                  final catName = tx.categoryName ?? "Uncategorized";
                  spendingMap[catName] = (spendingMap[catName] ?? 0) + tx.amount;
                }
              }

              return Column(
                children: [
                  // --- TOP BUTTON: SET BUDGET LIMIT ---
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.add, size: 16, color: Colors.white),
                          label: const Text("Set Budget Limit", style: TextStyle(fontWeight: FontWeight.bold)),
                          backgroundColor: Colors.black,
                          labelStyle: const TextStyle(color: Colors.white),
                          onPressed: () {
                            if (expenseCategories.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("No expense categories found!"))
                              );
                            } else {
                              // Pass ALL expense categories so the user can select any of them
                              _showAddBudgetDialog(expenseCategories);
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  // --- MAIN LIST: ACTIVE BUDGETS ONLY ---
                  Expanded(
                    child: activeBudgets.isEmpty
                        ? const Center(
                            child: Text(
                              "No budgets set yet.\nTap the button above to start!",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: activeBudgets.length,
                            itemBuilder: (context, index) {
                              final category = activeBudgets[index];
                              final double spent = spendingMap[category.name] ?? 0.0;
                              return _buildBudgetCard(category, spent, category.budget);
                            },
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // --- WIDGET: THE CARD DISPLAY ---
  Widget _buildBudgetCard(Category category, double spent, double budget) {
    // Progress Calculation
    double progress = spent / budget;
    if (progress > 1.0) progress = 1.0; 

    // Color Logic
    Color progressBarColor = Colors.green;
    if (progress > 0.8) progressBarColor = Colors.orange; // Warning zone
    if (progress >= 1.0) progressBarColor = Colors.red;   // Over budget

    return GestureDetector(
      onTap: () => _showEditBudgetDialog(category), // Allow editing existing ones
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Icon
                CircleAvatar(
                  backgroundColor: Color(category.colorValue).withOpacity(0.1),
                  child: Icon(IconData(int.parse("0xe${category.iconName == 'fastfood' ? '547' : '000'}"), fontFamily: 'MaterialIcons'), color: Color(category.colorValue)), 
                ),
                const SizedBox(width: 12),
                
                // Name
                Text(category.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                
                // Text Amount (Spent / Limit)
                Text(
                  "LKR ${spent.toStringAsFixed(0)} / ${budget.toStringAsFixed(0)}",
                  style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.edit, size: 16, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 15),
            
            // Visual Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[100],
                color: progressBarColor,
                minHeight: 12,
              ),
            ),
            const SizedBox(height: 8),
            
            // Percentage Text
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "${(progress * 100).toStringAsFixed(0)}% Used", 
                style: TextStyle(color: progressBarColor, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- DIALOG 1: ADD/SET BUDGET ---
  void _showAddBudgetDialog(List<Category> categories) {
    Category selectedCategory = categories.first;
    final TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Set Monthly Budget"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Select Category:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                
                // Dropdown List
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Category>(
                      value: selectedCategory,
                      isExpanded: true,
                      items: categories.map((Category c) {
                        return DropdownMenuItem<Category>(
                          value: c,
                          child: Text(
                            c.name + (c.budget > 0 ? " (Has Limit)" : ""),
                            style: TextStyle(
                              color: c.budget > 0 ? Colors.grey : Colors.black
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (Category? newValue) {
                        setState(() {
                          selectedCategory = newValue!;
                          // Pre-fill if a budget exists
                          if (selectedCategory.budget > 0) {
                            amountController.text = selectedCategory.budget.toStringAsFixed(0);
                          } else {
                            amountController.clear();
                          }
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Amount Input
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: "Monthly Limit",
                    prefixText: "LKR ",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () async {
                  final double? amount = double.tryParse(amountController.text);
                  if (amount != null) {
                    await widget.databaseService.updateCategoryBudget(selectedCategory.id, amount);
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                child: const Text("Save"),
              ),
            ],
          );
        }
      ),
    );
  }

  // --- DIALOG 2: EDIT EXISTING ---
  void _showEditBudgetDialog(Category category) {
    final TextEditingController controller = TextEditingController(text: category.budget.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit ${category.name} Budget"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: "New Limit (0 to remove)",
            prefixText: "LKR ",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final double? newBudget = double.tryParse(controller.text);
              if (newBudget != null) {
                await widget.databaseService.updateCategoryBudget(category.id, newBudget);
                if (context.mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}