import 'package:flutter/material.dart';
import '../models/category.dart';
import '../services/database_service.dart';

class ManageCategoriesScreen extends StatelessWidget {
  final DatabaseService databaseService;

  const ManageCategoriesScreen({super.key, required this.databaseService});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Categories', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          bottom: const TabBar(
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.black,
            tabs: [
              Tab(text: "Expense"),
              Tab(text: "Income"),
            ],
          ),
        ),
        backgroundColor: Colors.grey[100],
        body: TabBarView(
          children: [
            _CategoryList(databaseService: databaseService, isExpense: true),
            _CategoryList(databaseService: databaseService, isExpense: false),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.black,
          child: const Icon(Icons.add, color: Colors.white),
          onPressed: () {
            // Default to Expense tab logic, but user can switch in dialog
            _showCategoryDialog(context, databaseService, null);
          },
        ),
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  final DatabaseService databaseService;
  final bool isExpense;

  const _CategoryList({required this.databaseService, required this.isExpense});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Category>>(
      stream: databaseService.streamCategories(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final categories = snapshot.data!.where((c) => c.isExpense == isExpense).toList();

        if (categories.isEmpty) {
          return const Center(child: Text("No categories found."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(category.colorValue).withOpacity(0.2),
                  child: Icon(
                    IconData(int.parse("0xe${category.iconName == 'fastfood' ? '547' : '000'}"), fontFamily: 'MaterialIcons'),
                    color: Color(category.colorValue),
                  ),
                ),
                title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showCategoryDialog(context, databaseService, category),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteCategory(context, databaseService, category.id),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _deleteCategory(BuildContext context, DatabaseService db, int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Category?"),
        content: const Text("This will NOT delete past transactions, but it will remove this option for future use."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              await db.deleteCategory(id);
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// --- DIALOG FOR ADD/EDIT ---
void _showCategoryDialog(BuildContext context, DatabaseService db, Category? category) {
  final nameController = TextEditingController(text: category?.name ?? "");
  bool isExpense = category?.isExpense ?? true;
  
  // Simple Color Picker Logic (Hardcoded options for now)
  List<Color> colors = [Colors.red, Colors.blue, Colors.green, Colors.orange, Colors.purple];
  Color selectedColor = category != null ? Color(category.colorValue) : colors[0];

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: Text(category == null ? "New Category" : "Edit Category"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Category Name", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  const Text("Type: "),
                  const SizedBox(width: 10),
                  ChoiceChip(
                    label: const Text("Income"),
                    selected: !isExpense,
                    onSelected: (val) => setState(() => isExpense = !val),
                  ),
                  const SizedBox(width: 10),
                  ChoiceChip(
                    label: const Text("Expense"),
                    selected: isExpense,
                    onSelected: (val) => setState(() => isExpense = val),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              const Text("Pick Color:"),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: colors.map((c) {
                  return GestureDetector(
                    onTap: () => setState(() => selectedColor = c),
                    child: CircleAvatar(
                      backgroundColor: c,
                      radius: 15,
                      child: selectedColor == c ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                    ),
                  );
                }).toList(),
              )
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) return;

                final newCategory = Category()
                  ..id = category?.id ?? DateTime.now().millisecondsSinceEpoch // Unique ID logic
                  ..name = nameController.text
                  ..isExpense = isExpense
                  ..colorValue = selectedColor.value
                  ..iconName = "circle" // Default icon for custom ones
                  ..budget = category?.budget ?? 0.0; // Keep old budget if editing

                await db.saveCategory(newCategory);
                Navigator.pop(context);
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