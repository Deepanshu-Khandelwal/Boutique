import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'measurement_category.g.dart';

@HiveType(typeId: 5)
class MeasurementCategory extends HiveObject {

  MeasurementCategory({
    String? id,
    required this.name,
    required this.fields,
  }) : id = id ?? const Uuid().v4();
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  List<String> fields;
}
