import 'package:isar/isar.dart';

part 'account.g.dart';

@Collection()
class Account {
  Id id = Isar.autoIncrement;

  late String name;

  late String type;

  late double balance;

  late String currency;
} 