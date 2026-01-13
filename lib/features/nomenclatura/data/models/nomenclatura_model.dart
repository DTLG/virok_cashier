import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/nomenclatura.dart';

part 'nomenclatura_model.g.dart';

@JsonSerializable()
class NomenclaturaModel {
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  final String name;
  final String guid;
  final String article;
  @JsonKey(name: 'unit_name')
  final String unitName;
  @JsonKey(name: 'unit_guid')
  final String unitGuid;
  @JsonKey(name: 'is_folder')
  final bool isFolder;
  @JsonKey(name: 'parent_guid')
  final String? parentGuid;
  final String? description;
  final String barcodes;
  final double prices;
  final String searchName;

  const NomenclaturaModel({
    required this.createdAt,
    required this.name,
    required this.guid,
    required this.article,
    required this.unitName,
    required this.unitGuid,
    required this.isFolder,
    this.parentGuid,
    this.description,
    this.barcodes = '',
    this.prices = 0.0,
    this.searchName = '',
  });

  factory NomenclaturaModel.fromJson(Map<String, dynamic> json) =>
      _$NomenclaturaModelFromJson(json);

  Map<String, dynamic> toJson() => _$NomenclaturaModelToJson(this);

  factory NomenclaturaModel.fromSupabaseJson(Map<String, dynamic> json) {
    // Parse barcodes if they exist
    // Parse barcodes if they exist
    String barcodes = '';
    if (json['barcodes'] != null) {
      final list = (json['barcodes'] as List)
          .where((barcode) => barcode != null) // відкидаємо null
          .map((barcode) => barcode.toString())
          .toList();
      barcodes = list.isNotEmpty
          ? list.join(',')
          : ''; // перетворюємо в одну стрічку
    }

    // Parse prices if they exist
    double price = 0.0;
    if (json['prices'] != null && (json['prices'] as List).isNotEmpty) {
      final rawPrices = (json['prices'] as List);

      double? _extractPrice(dynamic p) {
        if (p == null) return null;

        // Випадок коли елемент вже є числом
        if (p is num) return p.toDouble();

        // Випадок коли це мапа типу {"price": 720, "nom_guid": "..."}
        if (p is Map<String, dynamic>) {
          final value = p['price'] ?? p['value'];
          if (value is num) return value.toDouble();

          // Якщо price всередині ще однієї мапи
          if (value is Map<String, dynamic>) {
            final inner = value['price'] ?? value['value'];
            if (inner is num) return inner.toDouble();
          }
        }

        return null;
      }

      final list = rawPrices
          .map(_extractPrice)
          .where((v) => v != null)
          .cast<double>()
          .toList();

      if (list.isNotEmpty) {
        price = list.first; // беремо першу валідну ціну
      }
    }

    final name = json['name'] ?? '';
    final article = json['article'] ?? '';
    final searchName = '${article}${name}'.toLowerCase();

    return NomenclaturaModel(
      createdAt: DateTime.parse(json['created_at']),
      name: name,
      guid: json['guid'] ?? '',
      article: article,
      unitName: json['unit_name'] ?? '',
      unitGuid: json['unit_guid'] ?? '',
      isFolder: json['is_folder'] ?? false,
      parentGuid: json['parent_guid'],
      description: json['description'],
      barcodes: barcodes,
      prices: price,
      searchName: searchName,
    );
  }

  Map<String, dynamic> toSupabaseJson() {
    return {
      'created_at': createdAt.toIso8601String(),
      'name': name,
      'guid': guid,
      'article': article,
      'unit_name': unitName,
      'unit_guid': unitGuid,
      'is_folder': isFolder,
      'parent_guid': parentGuid,
      'description': description,
    };
  }

  Nomenclatura toEntity() {
    return Nomenclatura(
      createdAt: createdAt,
      name: name,
      guid: guid,
      article: article,
      unitName: unitName,
      unitGuid: unitGuid,
      isFolder: isFolder,
      parentGuid: parentGuid,
      description: description,
      barcodes: barcodes,
      prices: prices,
      searchName: searchName,
    );
  }

  factory NomenclaturaModel.fromEntity(Nomenclatura entity) {
    return NomenclaturaModel(
      createdAt: entity.createdAt,
      name: entity.name,
      guid: entity.guid,
      article: entity.article,
      unitName: entity.unitName,
      unitGuid: entity.unitGuid,
      isFolder: entity.isFolder,
      parentGuid: entity.parentGuid,
      description: entity.description,
      barcodes: entity.barcodes,
      prices: entity.prices,
      searchName: entity.searchName,
    );
  }

  NomenclaturaModel copyWith({
    DateTime? createdAt,
    String? name,
    String? guid,
    String? article,
    String? unitName,
    String? unitGuid,
    bool? isFolder,
    String? parentGuid,
    String? description,
    String? barcodes,
    double? prices,
    String? searchName,
  }) {
    return NomenclaturaModel(
      createdAt: createdAt ?? this.createdAt,
      name: name ?? this.name,
      guid: guid ?? this.guid,
      article: article ?? this.article,
      unitName: unitName ?? this.unitName,
      unitGuid: unitGuid ?? this.unitGuid,
      isFolder: isFolder ?? this.isFolder,
      parentGuid: parentGuid ?? this.parentGuid,
      description: description ?? this.description,
      barcodes: barcodes ?? this.barcodes,
      prices: prices ?? this.prices,
      searchName: searchName ?? this.searchName,
    );
  }
}

@JsonSerializable()
class BarcodeModel {
  @JsonKey(name: 'nom_guid')
  final String nomGuid;
  final String barcode;

  const BarcodeModel({required this.nomGuid, required this.barcode});

  factory BarcodeModel.fromJson(Map<String, dynamic> json) =>
      _$BarcodeModelFromJson(json);

  Map<String, dynamic> toJson() => _$BarcodeModelToJson(this);

  factory BarcodeModel.fromSupabaseJson(Map<String, dynamic> json) {
    return BarcodeModel(
      nomGuid: json['nom_guid'] ?? '',
      barcode: json['barcode'] ?? '',
    );
  }

  Map<String, dynamic> toSupabaseJson() {
    return {'nom_guid': nomGuid, 'barcode': barcode};
  }

  Barcode toEntity() {
    return Barcode(nomGuid: nomGuid, barcode: barcode);
  }

  factory BarcodeModel.fromEntity(Barcode entity) {
    return BarcodeModel(nomGuid: entity.nomGuid, barcode: entity.barcode);
  }
}

@JsonSerializable()
class PriceModel {
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'nom_guid')
  final String nomGuid;
  final double price;

  const PriceModel({
    required this.createdAt,
    required this.nomGuid,
    required this.price,
  });

  factory PriceModel.fromJson(Map<String, dynamic> json) =>
      _$PriceModelFromJson(json);

  Map<String, dynamic> toJson() => _$PriceModelToJson(this);

  factory PriceModel.fromSupabaseJson(Map<String, dynamic> json) {
    return PriceModel(
      createdAt: DateTime.parse(json['created_at']),
      nomGuid: json['nom_guid'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toSupabaseJson() {
    return {
      'created_at': createdAt.toIso8601String(),
      'nom_guid': nomGuid,
      'price': price,
    };
  }

  Price toEntity() {
    return Price(createdAt: createdAt, nomGuid: nomGuid, price: price);
  }

  factory PriceModel.fromEntity(Price entity) {
    return PriceModel(
      createdAt: entity.createdAt,
      nomGuid: entity.nomGuid,
      price: entity.price,
    );
  }
}
