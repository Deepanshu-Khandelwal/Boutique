import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'customer.g.dart';

@HiveType(typeId: 0)
class Customer extends HiveObject {

  Customer({
    String? id,
    required this.name,
    required this.phone,
    this.email,
    DateTime? createdAt,
    this.photoPath,
    this.birthday,
    this.notes,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String phone;

  @HiveField(3)
  String? email;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  String? photoPath;

  @HiveField(6)
  DateTime? birthday;

  @HiveField(7)
  String? notes;
}
