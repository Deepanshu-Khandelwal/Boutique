import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'measurement.g.dart';

@HiveType(typeId: 1)
enum ClothingType {
  @HiveField(0) outfit,
  @HiveField(1) shirt,
  @HiveField(2) trouser,
  @HiveField(3) dress,
  @HiveField(4) blouse,
  @HiveField(5) skirt,
  @HiveField(6) custom,
}

@HiveType(typeId: 4)
enum MeasurementStatus {
  @HiveField(0)
  notStarted,
  @HiveField(1)
  cutting,
  @HiveField(2)
  stitching,
  @HiveField(3)
  readyForTrial,
  @HiveField(4)
  completed,
  @HiveField(5)
  delivered,
}

@HiveType(typeId: 2)
class Measurement extends HiveObject {

  Measurement({
    String? id,
    required this.customerId,
    required this.type,
    required this.values,
    this.note,
    DateTime? date,
    this.photos,
    this.deliveryDate,
    this.status = MeasurementStatus.notStarted,
    this.totalPrice = 0.0,
    this.paidAmount = 0.0,
    this.customCategoryName,
  })  : id = id ?? const Uuid().v4(),
        date = date ?? DateTime.now();
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String customerId;

  @HiveField(2)
  ClothingType type;

  @HiveField(3)
  Map<String, double> values;

  @HiveField(4)
  String? note;

  @HiveField(5)
  DateTime date;

  @HiveField(6)
  List<String>? photos;

  @HiveField(7)
  DateTime? deliveryDate;

  @HiveField(8)
  MeasurementStatus status;

  @HiveField(9)
  double totalPrice;

  @HiveField(10)
  double paidAmount;

  @HiveField(11)
  String? customCategoryName;
}

