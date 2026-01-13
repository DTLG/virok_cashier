import 'package:flutter/material.dart';
import '../../../nomenclatura/domain/entities/nomenclatura.dart';

class CategoryModel {
  final String id;
  final String name;
  final String? description;
  final IconData icon;
  final Color color;
  final double price;
  final int itemCount;
  final String? parentId;
  final bool isFolder;
  final String? article;

  const CategoryModel({
    required this.id,
    required this.name,
    this.description,
    required this.icon,
    required this.color,
    required this.price,
    required this.itemCount,
    this.parentId,
    required this.isFolder,
    this.article,
  });

  /// Створює CategoryModel з Nomenclatura entity
  factory CategoryModel.fromNomenclatura(
    Nomenclatura nomenclatura, {
    int itemCount = 0,
  }) {
    return CategoryModel(
      id: nomenclatura.guid,
      name: nomenclatura.name,
      description: nomenclatura.description,
      icon: nomenclatura.isFolder
          ? getIconForToolFolder(nomenclatura.name)
          : getIconForToolCategory(nomenclatura.name),
      color: nomenclatura.isFolder
          ? _getColorForCategory(nomenclatura.name)
          : _getColorForProduct(nomenclatura.name),
      price: nomenclatura.prices,
      itemCount: itemCount,
      parentId: nomenclatura.parentGuid,
      isFolder: nomenclatura.isFolder,
      article: nomenclatura.article,
    );
  }

  /// Визначає іконку для папки інструментів на основі її назви
  static IconData getIconForToolFolder(String folderName) {
    final name = folderName.toLowerCase();

    if (name.contains('молоток') || name.contains('hammer')) {
      return Icons.folder; // папка з молотками
    } else if (name.contains('викрутка') ||
        name.contains('screwdriver') ||
        name.contains('гайка') ||
        name.contains('гвинт') ||
        name.contains('шайба') ||
        name.contains('болт')) {
      return Icons.folder_special; // папка для кріплень
    } else if (name.contains('пила') ||
        name.contains('saw') ||
        name.contains('chainsaw')) {
      return Icons.folder_open; // папка з пилами
    }
    //  else if (name.contains('дриль') ||
    //     name.contains('перфоратор') ||
    //     name.contains('drill')) {
    //   return Icons.build_circle; // папка для дрилів
    // } else if (name.contains('шліфмашина') ||
    //     name.contains('болгарка') ||
    //     name.contains('grinder')) {
    //   return Icons.settings; // умовна іконка для шліфувальних
    // } else if (name.contains('лом') || name.contains('crowbar')) {
    //   return Icons.handyman; // лом та важкий інструмент
    // } else if (name.contains('вимір') ||
    //     name.contains('рулетка') ||
    //     name.contains('лінійка') ||
    //     name.contains('ваги') ||
    //     name.contains('метр') ||
    //     name.contains('висок') ||
    //     name.contains('measure')) {
    //   return Icons.straighten; // вимірювальні інструменти
    // } else if (name.contains('фарба') ||
    //     name.contains('paint') ||
    //     name.contains('кисть') ||
    //     name.contains('roller')) {
    //   return Icons.format_paint; // фарбувальні
    // } else if (name.contains('електрика') ||
    //     name.contains('кабель') ||
    //     name.contains('заряд') ||
    //     name.contains('провід') ||
    //     name.contains('акумулятор') ||
    //     name.contains('wire')) {
    //   return Icons.electrical_services;
    // } else if (name.contains('сантех') ||
    //     name.contains('plumbing') ||
    //     name.contains('труба')) {
    //   return Icons.plumbing;
    // } else if (name.contains('будматеріал') ||
    //     name.contains('cement') ||
    //     name.contains('цегла') ||
    //     name.contains('бетон')) {
    //   return Icons.home_repair_service;
    // } else if (name.contains('захист') ||
    //     name.contains('каска') ||
    //     name.contains('рукавиц') ||
    //     name.contains('protective')) {
    //   return Icons.health_and_safety;
    // }
    else {
      return Icons.folder; // дефолтна іконка папки
    }
  }

  /// Визначає іконку на основі назви категорії
  static IconData getIconForToolCategory(String categoryName) {
    final name = categoryName.toLowerCase();

    if (name.contains('молоток') || name.contains('hammer')) {
      return Icons.construction;
    } else if (name.contains('викрутка') ||
        name.contains('screwdriver') ||
        name.contains('гайка') ||
        name.contains('гвинт') ||
        name.contains('шайба') ||
        name.contains('болт')) {
      return Icons.build;
    } else if (name.contains('пила') ||
        name.contains('saw') ||
        name.contains('chainsaw')) {
      return Icons.handyman;
    } else if (name.contains('дриль') ||
        name.contains('перфоратор') ||
        name.contains('drill')) {
      return Icons
          .power_settings_new; // немає спец іконки, можна підібрати іншу
    } else if (name.contains('шліфмашина') ||
        name.contains('болгарка') ||
        name.contains('grinder')) {
      return Icons.settings;
    } else if (name.contains('лом') || name.contains('crowbar')) {
      return Icons.hardware;
    } else if (name.contains('вимір') ||
        name.contains('рулетка') ||
        name.contains('лінійка') ||
        name.contains('ваги') ||
        name.contains('метр') ||
        name.contains('висок') ||
        name.contains('measure')) {
      return Icons.straighten;
    } else if (name.contains('фарба') ||
        name.contains('paint') ||
        name.contains('кисть') ||
        name.contains('roller')) {
      return Icons.format_paint;
    } else if (name.contains('електрика') ||
        name.contains('кабель') ||
        name.contains('заряд') ||
        name.contains('провід') ||
        name.contains('акумулятор') ||
        name.contains('wire')) {
      return Icons.electrical_services;
    } else if (name.contains('сантех') ||
        name.contains('plumbing') ||
        name.contains('труба')) {
      return Icons.plumbing;
    } else if (name.contains('будматеріал') ||
        name.contains('cement') ||
        name.contains('цегла') ||
        name.contains('бетон')) {
      return Icons.home_repair_service;
    } else if (name.contains('захист') ||
        name.contains('каска') ||
        name.contains('рукавиц') ||
        name.contains('protective')) {
      return Icons.health_and_safety;
    } else {
      return Icons.category; // дефолтна іконка
    }
  }

  /// Визначає колір на основі назви категорії (узгоджено з іконками)
  static Color _getColorForCategory(String categoryName) {
    final name = categoryName.toLowerCase();

    if (name.contains('молоток') || name.contains('hammer')) {
      return const Color(0xFFFFF3E0);
    } else if (name.contains('викрутка') ||
        name.contains('screwdriver') ||
        name.contains('гайка') ||
        name.contains('гвинт') ||
        name.contains('шайба') ||
        name.contains('болт')) {
      return const Color(0xFFE3F2FD);
    } else if (name.contains('пила') ||
        name.contains('saw') ||
        name.contains('chainsaw')) {
      return const Color(0xFFE8F5E9);
    } else if (name.contains('дриль') ||
        name.contains('перфоратор') ||
        name.contains('drill')) {
      return const Color(0xFFF3E5F5);
    } else if (name.contains('шліфмашина') ||
        name.contains('болгарка') ||
        name.contains('grinder')) {
      return const Color(0xFFFFEBEE);
    } else if (name.contains('лом') || name.contains('crowbar')) {
      return const Color(0xFFE0F2F1);
    } else if (name.contains('вимір') ||
        name.contains('рулетка') ||
        name.contains('лінійка') ||
        name.contains('ваги') ||
        name.contains('метр') ||
        name.contains('висок') ||
        name.contains('measure')) {
      return const Color(0xFFFFFDE7);
    } else if (name.contains('фарба') ||
        name.contains('paint') ||
        name.contains('кисть') ||
        name.contains('roller')) {
      return const Color(0xFFE1F5FE);
    } else if (name.contains('електрика') ||
        name.contains('кабель') ||
        name.contains('заряд') ||
        name.contains('провід') ||
        name.contains('акумулятор') ||
        name.contains('wire')) {
      return const Color(0xFFFFF8E1);
    } else if (name.contains('сантех') ||
        name.contains('plumbing') ||
        name.contains('труба')) {
      return const Color(0xFFE3F2FD);
    } else if (name.contains('будматеріал') ||
        name.contains('cement') ||
        name.contains('цегла') ||
        name.contains('бетон')) {
      return const Color(0xFFF5F5F5);
    } else if (name.contains('захист') ||
        name.contains('каска') ||
        name.contains('рукавиц') ||
        name.contains('protective')) {
      return const Color(0xFFE8EAF6);
    } else {
      return const Color(0xFFE6E6FA);
    }
  }

  /// Визначає колір для товарів (узгоджено з іконками)
  static Color _getColorForProduct(String productName) {
    final name = productName.toLowerCase();

    if (name.contains('молоток') || name.contains('hammer')) {
      return const Color(0xFFFFE0B2);
    } else if (name.contains('викрутка') ||
        name.contains('screwdriver') ||
        name.contains('гайка') ||
        name.contains('гвинт') ||
        name.contains('шайба') ||
        name.contains('болт')) {
      return const Color(0xFFBBDEFB);
    } else if (name.contains('пила') ||
        name.contains('saw') ||
        name.contains('chainsaw')) {
      return const Color(0xFFC8E6C9);
    } else if (name.contains('дриль') ||
        name.contains('перфоратор') ||
        name.contains('drill')) {
      return const Color(0xFFE1BEE7);
    } else if (name.contains('шліфмашина') ||
        name.contains('болгарка') ||
        name.contains('grinder')) {
      return const Color(0xFFFFCDD2);
    } else if (name.contains('лом') || name.contains('crowbar')) {
      return const Color(0xFFB2DFDB);
    } else if (name.contains('вимір') ||
        name.contains('рулетка') ||
        name.contains('лінійка') ||
        name.contains('ваги') ||
        name.contains('метр') ||
        name.contains('висок') ||
        name.contains('measure')) {
      return const Color(0xFFFFF59D);
    } else if (name.contains('фарба') ||
        name.contains('paint') ||
        name.contains('кисть') ||
        name.contains('roller')) {
      return const Color(0xFFB3E5FC);
    } else if (name.contains('електрика') ||
        name.contains('кабель') ||
        name.contains('заряд') ||
        name.contains('провід') ||
        name.contains('акумулятор') ||
        name.contains('wire')) {
      return const Color(0xFFFFF9C4);
    } else if (name.contains('сантех') ||
        name.contains('plumbing') ||
        name.contains('труба')) {
      return const Color(0xFFBBDEFB);
    } else if (name.contains('будматеріал') ||
        name.contains('cement') ||
        name.contains('цегла') ||
        name.contains('бетон')) {
      return const Color(0xFFE0E0E0);
    } else if (name.contains('захист') ||
        name.contains('каска') ||
        name.contains('рукавиц') ||
        name.contains('protective')) {
      return const Color(0xFFC5CAE9);
    } else {
      return const Color.fromARGB(255, 238, 161, 161);
    }
  }
}
