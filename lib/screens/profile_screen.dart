import 'package:flutter/material.dart';
import '../services/database_service.dart';
import 'manage_categories_screen.dart'; // Import the screen we just made

class ProfileScreen extends StatelessWidget {
  final DatabaseService databaseService;

  const ProfileScreen({super.key, required this.databaseService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[100],
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. User Info Card (Visual only)
          const UserInfoCard(),
          
          const SizedBox(height: 20),
          const Text("General", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 10),

          // 2. Manage Categories Button (LINKED!)
          _buildProfileOption(
            context,
            icon: Icons.category,
            title: "Manage Categories",
            subtitle: "Add or remove expense categories",
            onTap: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => ManageCategoriesScreen(databaseService: databaseService)),
              );
            },
          ),
          
          // 3. Manage Accounts Button (Coming Next)
          _buildProfileOption(
            context,
            icon: Icons.account_balance_wallet,
            title: "Manage Accounts",
            subtitle: "Add banks, wallets, etc.",
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Building this next!")));
            },
          ),

          const SizedBox(height: 20),
          const Text("Danger Zone", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red)),
          const SizedBox(height: 10),

          // 4. Clear Data Button
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text("Erase All Data", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              onTap: () => _showDeleteDialog(context),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildProfileOption(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withOpacity(0.1),
          child: Icon(icon, color: Colors.blue),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Are you sure?"),
        content: const Text("This will delete ALL transactions and accounts permanently."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              // We added this function in the database service earlier
              await databaseService.cleanDb(); 
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Data Erased")));
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class UserInfoCard extends StatelessWidget {
  const UserInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.black,
            child: const Icon(Icons.person, size: 35, color: Colors.white),
          ),
          const SizedBox(width: 15),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Thesara Subasinghe", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text("User", style: TextStyle(color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}