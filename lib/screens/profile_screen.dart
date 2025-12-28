import 'dart:io'; // <-- NEW: Needed to display files
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart'; // <-- NEW: The picker package
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
  String _userName = "User";
  int _avatarIndex = 0; 
  String? _profileImagePath; // <-- NEW: Holds path to custom photo

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
    _loadUserProfile();
  }

  // --- 1. LOAD DATA ---
  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? "User";
      _avatarIndex = prefs.getInt('user_avatar_index') ?? 0;
      _profileImagePath = prefs.getString('user_profile_image'); // Load the path
    });
  }

  // --- 2. SAVE DATA ---
  Future<void> _saveUserProfile(String name, int avatarIndex, String? imagePath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    await prefs.setInt('user_avatar_index', avatarIndex);
    
    if (imagePath != null) {
      await prefs.setString('user_profile_image', imagePath);
    } else {
      await prefs.remove('user_profile_image'); // Clear it if they went back to an icon
    }
    
    setState(() {
      _userName = name;
      _avatarIndex = avatarIndex;
      _profileImagePath = imagePath;
    });
  }

  // --- 3. PICK IMAGE FUNCTION ---
  Future<String?> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    // Pick an image
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    return image?.path;
  }


  @override
  Widget build(BuildContext context) {
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
          // 1. User Info Card
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
                  // --- MAIN AVATAR DISPLAY LOGIC ---
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: _profileImagePath != null ? Colors.transparent : currentAvatar['color'],
                    // If path exists, show file image. Else show nothing here.
                    backgroundImage: _profileImagePath != null 
                        ? FileImage(File(_profileImagePath!)) as ImageProvider
                        : null,
                    // If path is NULL, show the icon child.
                    child: _profileImagePath == null 
                        ? Icon(currentAvatar['icon'], size: 35, color: Colors.white)
                        : null,
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
          // ... (Rest of your menu options remain the same) ...
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
    int tempIndex = _avatarIndex; 
    String? tempPath = _profileImagePath; // Temp path for dialog preview

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        // We use 'dialogSetState' here to update the UI *inside* the dialog
        builder: (context, dialogSetState) {
          return AlertDialog(
            title: const Text("Edit Profile"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- PREVIEW AREA ---
                GestureDetector(
                   onTap: () async {
                      // Trigger image picker when tapping the big preview circle
                      final path = await _pickImageFromGallery();
                       if (path != null) {
                        dialogSetState(() => tempPath = path);
                       }
                    },
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: tempPath != null ? Colors.transparent : _avatarOptions[tempIndex]['color'],
                        backgroundImage: tempPath != null 
                            ? FileImage(File(tempPath!)) as ImageProvider
                            : null,
                        child: tempPath == null 
                            ? Icon(_avatarOptions[tempIndex]['icon'], size: 40, color: Colors.white)
                            : null,
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt, size: 16, color: Colors.black),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text("Tap above to upload photo", style: TextStyle(fontSize: 12, color: Colors.grey)),
                
                const SizedBox(height: 20),
                const Text("Or choose an avatar:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 10),
                
                // --- ICON GRID ---
                Wrap(
                  spacing: 15,
                  runSpacing: 15,
                  alignment: WrapAlignment.center,
                  children: List.generate(_avatarOptions.length, (index) {
                    final option = _avatarOptions[index];
                    // Selected if index matches AND we aren't using a custom photo
                    final isSelected = tempIndex == index && tempPath == null;
                    return GestureDetector(
                      onTap: () {
                         // If they click an icon, clear the custom photo path
                         dialogSetState(() {
                           tempIndex = index;
                           tempPath = null; 
                         });
                      },
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
                  // SAVE all data including the new path (or null path)
                  _saveUserProfile(newName, tempIndex, tempPath);
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