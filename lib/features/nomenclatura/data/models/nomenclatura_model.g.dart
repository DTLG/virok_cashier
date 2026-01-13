// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nomenclatura_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NomenclaturaModel _$NomenclaturaModelFromJson(Map<String, dynamic> json) =>
    NomenclaturaModel(
      createdAt: DateTime.parse(json['created_at'] as String),
      name: json['name'] as String,
      guid: json['guid'] as String,
      article: json['article'] as String,
      unitName: json['unit_name'] as String,
      unitGuid: json['unit_guid'] as String,
      isFolder: json['is_folder'] as bool,
      parentGuid: json['parent_guid'] as String?,
      description: json['description'] as String?,
      barcodes: json['barcodes'] as String? ?? '',
      prices: (json['prices'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$NomenclaturaModelToJson(NomenclaturaModel instance) =>
    <String, dynamic>{
      'created_at': instance.createdAt.toIso8601String(),
      'name': instance.name,
      'guid': instance.guid,
      'article': instance.article,
      'unit_name': instance.unitName,
      'unit_guid': instance.unitGuid,
      'is_folder': instance.isFolder,
      'parent_guid': instance.parentGuid,
      'description': instance.description,
      'barcodes': instance.barcodes,
      'prices': instance.prices,
    };

BarcodeModel _$BarcodeModelFromJson(Map<String, dynamic> json) => BarcodeModel(
  nomGuid: json['nom_guid'] as String,
  barcode: json['barcode'] as String,
);

Map<String, dynamic> _$BarcodeModelToJson(BarcodeModel instance) =>
    <String, dynamic>{
      'nom_guid': instance.nomGuid,
      'barcode': instance.barcode,
    };

PriceModel _$PriceModelFromJson(Map<String, dynamic> json) => PriceModel(
  createdAt: DateTime.parse(json['created_at'] as String),
  nomGuid: json['nom_guid'] as String,
  price: (json['price'] as num).toDouble(),
);

Map<String, dynamic> _$PriceModelToJson(PriceModel instance) =>
    <String, dynamic>{
      'created_at': instance.createdAt.toIso8601String(),
      'nom_guid': instance.nomGuid,
      'price': instance.price,
    };
