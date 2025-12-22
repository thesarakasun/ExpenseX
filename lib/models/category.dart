import 'package:isar/isar.dart';

part 'category.g.dart';

@Collection()
class Category {
  Id id = Isar.autoIncrement;

  late String name;

  late bool isExpense;

  late String iconName;

  late int colorValue;

  double budget = 0.0; 
}