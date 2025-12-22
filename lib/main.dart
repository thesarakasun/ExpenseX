import 'package:flutter/material.dart';
import 'screens/main_screen.dart';
import 'services/database_service.dart';

void main() async {
  // 1. Ensure Flutter bindings are ready
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Database
  final databaseService = DatabaseService();
  await databaseService.initialize();

  // 3. Run App (Injecting the database service)
  runApp(ExpenseXApp(databaseService: databaseService));
}

class ExpenseXApp extends StatelessWidget {
  final DatabaseService databaseService; // Receive the service

  const ExpenseXApp({super.key, required this.databaseService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ExpenseX',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // Pass the service down to the MainScreen
      home: MainScreen(databaseService: databaseService), 
    );
  }
}