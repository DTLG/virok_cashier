import 'package:equatable/equatable.dart';

class Nomenclatura extends Equatable {
  final DateTime createdAt;
  final String name;
  final String guid;
  final String article;
  final String unitName;
  final String unitGuid;
  final bool isFolder;
  final String? parentGuid;
  final String? description;
  final String barcodes; // comma-separated string
  final double prices; // single price value
  final String searchName; // article + name in lowercase for search

  const Nomenclatura({
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

  @override
  List<Object?> get props => [
    createdAt,
    name,
    guid,
    article,
    unitName,
    unitGuid,
    isFolder,
    parentGuid,
    description,
    barcodes,
    prices,
    searchName,
  ];

  @override
  String toString() {
    return 'Nomenclatura(guid: $guid, name: $name, article: $article, unitName: $unitName)';
  }
}

class Barcode extends Equatable {
  final String nomGuid;
  final String barcode;

  const Barcode({required this.nomGuid, required this.barcode});

  @override
  List<Object> get props => [nomGuid, barcode];

  @override
  String toString() {
    return 'Barcode(nomGuid: $nomGuid, barcode: $barcode)';
  }
}

class Price extends Equatable {
  final DateTime createdAt;
  final String nomGuid;
  final double price;

  const Price({
    required this.createdAt,
    required this.nomGuid,
    required this.price,
  });

  @override
  List<Object> get props => [createdAt, nomGuid, price];

  @override
  String toString() {
    return 'Price(nomGuid: $nomGuid, price: $price, createdAt: $createdAt)';
  }
}
