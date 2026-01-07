import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart'; // GPS
import 'package:geocoding/geocoding.dart';   // Address lookup
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
  String? _profileImagePath;
  
  // Currency State
  String _selectedCurrency = "LKR"; 
  bool _isLoadingLocation = false;

  final List<Map<String, dynamic>> _avatarOptions = [
    {'icon': Icons.person, 'color': Colors.black},
    {'icon': Icons.face, 'color': Colors.blue},
    {'icon': Icons.emoji_emotions, 'color': Colors.orange},
    {'icon': Icons.pets, 'color': Colors.brown},
    {'icon': Icons.rocket_launch, 'color': Colors.purple},
    {'icon': Icons.spa, 'color': Colors.green},
  ];

  final List<String> _currencies = ["LKR", "USD", "INR", "AUD", "JPY", "EUR", "PKR"];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // --- 1. LOAD DATA ---
  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    
    // FIX: Check if screen is still alive before updating UI
    if (!mounted) return;

    setState(() {
      _userName = prefs.getString('user_name') ?? "User";
      _avatarIndex = prefs.getInt('user_avatar_index') ?? 0;
      _profileImagePath = prefs.getString('user_profile_image');
      _selectedCurrency = prefs.getString('currency') ?? "LKR"; 
    });
  }

  // --- 2. SAVE PROFILE DATA ---
  Future<void> _saveUserProfile(String name, int avatarIndex, String? imagePath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    await prefs.setInt('user_avatar_index', avatarIndex);
    
    if (imagePath != null) {
      await prefs.setString('user_profile_image', imagePath);
    } else {
      await prefs.remove('user_profile_image'); 
    }
    
    if (mounted) {
      setState(() {
        _userName = name;
        _avatarIndex = avatarIndex;
        _profileImagePath = imagePath;
      });
    }
  }

  // --- 3. SAVE CURRENCY ---
  Future<void> _saveCurrency(String currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', currency);
    
    if (mounted) {
      setState(() {
        _selectedCurrency = currency;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Currency changed to $currency")),
      );
    }
  }

  // --- 4. DETECT LOCATION LOGIC (FIXED) ---
  Future<void> _detectCurrencyFromLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw "Location permissions are denied";
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw "Location permissions are permanently denied.";
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low, 
        timeLimit: const Duration(seconds: 5),
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      
      if (placemarks.isNotEmpty) {
        final country = placemarks.first.country; 
        final isoCode = placemarks.first.isoCountryCode; 
        
        Map<String, String> countryToCurrency = {
          "LK": "LKR", "US": "USD", "AU": "AUD", "JP": "JPY", 
          "IN": "INR", "PK": "PKR", 
          "FR": "EUR", "DE": "EUR", "IT": "EUR", "ES": "EUR", 
          "NL": "EUR", "BE": "EUR", "AT": "EUR", "IE": "EUR"
        };

        String newCurrency = countryToCurrency[isoCode] ?? "USD";

        if (mounted) {
          await _saveCurrency(newCurrency);
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("Location Detected"),
                content: Text("You are in $country.\nCurrency set to $newCurrency."),
                actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not detect location.")));
      }
    } finally {
      // FIX: Check mounted before stopping the loader
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  Future<String?> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    return image?.path;
  }

  @override
  Widget build(BuildContext context) {
    // Safety check for index out of bounds
    int safeIndex = (_avatarIndex >= 0 && _avatarIndex < _avatarOptions.length) ? _avatarIndex : 0;
    final currentAvatar = _avatarOptions[safeIndex];

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
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: _profileImagePath != null ? Colors.transparent : currentAvatar['color'],
                    backgroundImage: _profileImagePath != null 
                        ? FileImage(File(_profileImagePath!)) as ImageProvider
                        : null,
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
          
          const SizedBox(height: 20),
          
          // --- CURRENCY SETTINGS SECTION ---
          const Text("Currency Settings", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 10),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 5)],
            ),
            child: Column(
              children: [
                // AUTO MODE ROW
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.location_on, color: Colors.purple),
                  ),
                  title: const Text("Detect from Location", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text("Automatically set currency based on GPS"),
                  trailing: _isLoadingLocation 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  onTap: _detectCurrencyFromLocation, 
                ),
                const Divider(),
                // MANUAL MODE ROW
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.attach_money, color: Colors.green),
                  ),
                  title: const Text("Currency", style: TextStyle(fontWeight: FontWeight.bold)),
                  trailing: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _currencies.contains(_selectedCurrency) ? _selectedCurrency : _currencies.first,
                      items: _currencies.map((String c) {
                        return DropdownMenuItem<String>(
                          value: c,
                          child: Text(c, style: const TextStyle(fontWeight: FontWeight.bold)),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        if (newValue != null) _saveCurrency(newValue);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const Text("General", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 10),

          // Manage Categories
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
          
          // Manage Accounts
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

          // Clear Data
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
    String? tempPath = _profileImagePath;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, dialogSetState) {
          return AlertDialog(
            title: const Text("Edit Profile"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                   onTap: () async {
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
                
                Wrap(
                  spacing: 15,
                  runSpacing: 15,
                  alignment: WrapAlignment.center,
                  children: List.generate(_avatarOptions.length, (index) {
                    final option = _avatarOptions[index];
                    final isSelected = tempIndex == index && tempPath == null;
                    return GestureDetector(
                      onTap: () {
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