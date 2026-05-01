// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'poi_hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PoiHiveAdapter extends TypeAdapter<PoiHive> {
  @override
  final int typeId = 0;

  @override
  PoiHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PoiHive(
      name: fields[0] as String,
      description: fields[1] as String,
      category: fields[2] as String,
      address: fields[3] as String?,
      openingHours: fields[4] as String?,
      tip: fields[5] as String?,
      latitude: fields[6] as double?,
      longitude: fields[7] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, PoiHive obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.address)
      ..writeByte(4)
      ..write(obj.openingHours)
      ..writeByte(5)
      ..write(obj.tip)
      ..writeByte(6)
      ..write(obj.latitude)
      ..writeByte(7)
      ..write(obj.longitude);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PoiHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
