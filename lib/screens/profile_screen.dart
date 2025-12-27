import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import the new package
import '../services/database_service.dart';
import 'manage_categories_screen.dart';
import 'manage_accounts_screen.dart';

class ProfileScreen extends StatefulWidget {
  final DatabaseService databaseService;

  const ProfileScreen({super.key, required this.databaseService});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Default values
  String _userName = "User";
  int _avatarIndex = 0; // We save the "ID" of the avatar, not the icon itself

  // The list of available avatars (Icon + Color)
  final List<Map<String, dynamic>> _avatarOptions = [
    {'icon': Icons.person, 'color': Colors.black},
    {'icon': Icons.face, 'color': Colors.blue},
    {'icon': Icons.emoji_emotions, 'color': Colors.orange},
    {'icon': Icons.pets, 'color': Colors.brown},
    {'icon': Icons.rocket_launch, 'color': Colors.purple},
    {'icon': Icons.spa, 'color': Colors.green},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile(); // <--- Load data when screen starts
  }

  // --- 1. LOAD DATA ---
  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? "User";
      _avatarIndex = prefs.getInt('user_avatar_index') ?? 0;
    });
  }

  // --- 2. SAVE DATA ---
  Future<void> _saveUserProfile(String name, int avatarIndex) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    await prefs.setInt('user_avatar_index', avatarIndex);
    
    setState(() {
      _userName = name;
      _avatarIndex = avatarIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get current avatar details based on index
    final currentAvatar = _avatarOptions[_avatarIndex];

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
          // 1. User Info Card (NOW PERSISTENT!)
          GestureDetector(
            onTap: _showEditProfileDialog,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: currentAvatar['color'],
                    child: Icon(currentAvatar['icon'], size: 35, color: Colors.white),
                  ),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const Text("Tap to edit profile", style: TextStyle(fontSize: 12, color: Colors.blue)),
                    ],
                  ),
                  const Spacer(),
                  const Icon(Icons.edit, size: 18, color: Colors.grey),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          const Text("General", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 10),

          // 2. Manage Categories
          _buildProfileOption(
            context,
            icon: Icons.category,
            title: "Manage Categories",
            subtitle: "Add or remove expense categories",
            onTap: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => ManageCategoriesScreen(databaseService: widget.databaseService)),
              );
            },
          ),
          
          // 3. Manage Accounts
          _buildProfileOption(
            context,
            icon: Icons.account_balance_wallet,
            title: "Manage Accounts",
            subtitle: "Add banks, wallets, etc.",
            onTap: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => ManageAccountsScreen(databaseService: widget.databaseService)),
              );
            },
          ),

          const SizedBox(height: 20),
          const Text("Danger Zone", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red)),
          const SizedBox(height: 10),

          // 4. Clear Data
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

  // --- DIALOG: EDIT PROFILE ---
  void _showEditProfileDialog() {
    final TextEditingController nameController = TextEditingController(text: _userName);
    int tempIndex = _avatarIndex; // Temp variable for dialog selection

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Edit Profile"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Choose Avatar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 15),
                // Avatar Grid
                Wrap(
                  spacing: 15,
                  runSpacing: 15,
                  alignment: WrapAlignment.center,
                  children: List.generate(_avatarOptions.length, (index) {
                    final option = _avatarOptions[index];
                    final isSelected = tempIndex == index;
                    return GestureDetector(
                      onTap: () => setState(() => tempIndex = index),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: option['color'].withOpacity(isSelected ? 1.0 : 0.2),
                        child: Icon(option['icon'], color: isSelected ? Colors.white : option['color'], size: 22),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                
                // Name Input
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Your Name",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () {
                  final newName = nameController.text.isEmpty ? "User" : nameController.text;
                  // SAVE to persistent storage
                  _saveUserProfile(newName, tempIndex);
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

  // --- HELPER WIDGETS ---
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
              await widget.databaseService.cleanDb(); 
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