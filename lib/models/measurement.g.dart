// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'measurement.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MeasurementAdapter extends TypeAdapter<Measurement> {
  @override
  final int typeId = 2;

  @override
  Measurement read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Measurement(
      id: fields[0] as String?,
      customerId: fields[1] as String,
      type: fields[2] as ClothingType,
      values: (fields[3] as Map).cast<String, double>(),
      note: fields[4] as String?,
      date: fields[5] as DateTime?,
      photos: (fields[6] as List?)?.cast<String>(),
      deliveryDate: fields[7] as DateTime?,
      status: fields[8] as MeasurementStatus,
      totalPrice: fields[9] as double,
      paidAmount: fields[10] as double,
      customCategoryName: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Measurement obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.customerId)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.values)
      ..writeByte(4)
      ..write(obj.note)
      ..writeByte(5)
      ..write(obj.date)
      ..writeByte(6)
      ..write(obj.photos)
      ..writeByte(7)
      ..write(obj.deliveryDate)
      ..writeByte(8)
      ..write(obj.status)
      ..writeByte(9)
      ..write(obj.totalPrice)
      ..writeByte(10)
      ..write(obj.paidAmount)
      ..writeByte(11)
      ..write(obj.customCategoryName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeasurementAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ClothingTypeAdapter extends TypeAdapter<ClothingType> {
  @override
  final int typeId = 1;

  @override
  ClothingType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ClothingType.outfit;
      case 1:
        return ClothingType.shirt;
      case 2:
        return ClothingType.trouser;
      case 3:
        return ClothingType.dress;
      case 4:
        return ClothingType.blouse;
      case 5:
        return ClothingType.skirt;
      case 6:
        return ClothingType.custom;
      default:
        return ClothingType.outfit;
    }
  }

  @override
  void write(BinaryWriter writer, ClothingType obj) {
    switch (obj) {
      case ClothingType.outfit:
        writer.writeByte(0);
        break;
      case ClothingType.shirt:
        writer.writeByte(1);
        break;
      case ClothingType.trouser:
        writer.writeByte(2);
        break;
      case ClothingType.dress:
        writer.writeByte(3);
        break;
      case ClothingType.blouse:
        writer.writeByte(4);
        break;
      case ClothingType.skirt:
        writer.writeByte(5);
        break;
      case ClothingType.custom:
        writer.writeByte(6);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClothingTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MeasurementStatusAdapter extends TypeAdapter<MeasurementStatus> {
  @override
  final int typeId = 4;

  @override
  MeasurementStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MeasurementStatus.notStarted;
      case 1:
        return MeasurementStatus.cutting;
      case 2:
        return MeasurementStatus.stitching;
      case 3:
        return MeasurementStatus.readyForTrial;
      case 4:
        return MeasurementStatus.completed;
      case 5:
        return MeasurementStatus.delivered;
      default:
        return MeasurementStatus.notStarted;
    }
  }

  @override
  void write(BinaryWriter writer, MeasurementStatus obj) {
    switch (obj) {
      case MeasurementStatus.notStarted:
        writer.writeByte(0);
        break;
      case MeasurementStatus.cutting:
        writer.writeByte(1);
        break;
      case MeasurementStatus.stitching:
        writer.writeByte(2);
        break;
      case MeasurementStatus.readyForTrial:
        writer.writeByte(3);
        break;
      case MeasurementStatus.completed:
        writer.writeByte(4);
        break;
      case MeasurementStatus.delivered:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeasurementStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
