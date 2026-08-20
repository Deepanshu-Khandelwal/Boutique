// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'measurement_category.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MeasurementCategoryAdapter extends TypeAdapter<MeasurementCategory> {
  @override
  final int typeId = 5;

  @override
  MeasurementCategory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MeasurementCategory(
      id: fields[0] as String?,
      name: fields[1] as String,
      fields: (fields[2] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, MeasurementCategory obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.fields);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeasurementCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
