import 'profile_screen.dart';
import 'budget_screen.dart';
import 'insights_screen.dart';
import 'package:flutter/material.dart';
import '../services/database_service.dart';
import 'dashboard.dart';
import '../widgets/add_transaction_form.dart';

class MainScreen extends StatefulWidget {
  final DatabaseService databaseService; // Store the service here

  const MainScreen({super.key, required this.databaseService});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // We use a getter method for pages since we need access to 'widget.databaseService'
  // and we can't access 'widget' inside a simple list variable definition.
  List<Widget> get _pages => [
    Dashboard(databaseService: widget.databaseService),
    BudgetScreen(databaseService: widget.databaseService),
    const SizedBox(), // Placeholder for the "+" button
    InsightsScreen(databaseService: widget.databaseService),
    ProfileScreen(databaseService: widget.databaseService),
  ];

  void _onItemTapped(int index) {
    if (index == 2) {
      // Open the Add Transaction Sheet and PASS the database service
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => AddTransactionForm(databaseService: widget.databaseService),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: 'Budget',
          ),
          BottomNavigationBarItem(
            icon: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.blue,
              child: Icon(Icons.add, color: Colors.white),
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Insights',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}