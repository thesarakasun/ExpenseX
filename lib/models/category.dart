//import 'package:flutter/material.dart';

class Category {
  int id;
  String name;
  String iconName;
  int colorValue;
  bool isExpense;
  double budget;

  Category({
    required this.id,
    required this.name,
    required this.iconName,
    required this.colorValue,
    required this.isExpense,
    this.budget = 0.0,
  });

  // Convert a Category object into a Map object
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconName': iconName,
      'colorValue': colorValue,
      'isExpense': isExpense ? 1 : 0, // SQLite stores bools as 0 or 1
      'budget': budget,
    };
  }

  // Convert a Map object into a Category object
  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      iconName: map['iconName'],
      colorValue: map['colorValue'],
      isExpense: map['isExpense'] == 1,
      budget: map['budget'] ?? 0.0,
    );
  }
}