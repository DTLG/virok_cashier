import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/nomenclatura_model.dart';
import '../../../../core/error/failures.dart';
import 'package:flutter/foundation.dart';

abstract class NomenclaturaRemoteDataSource {
  Future<List<NomenclaturaModel>> getAllNomenclatura({
    void Function(String message, double progress)? onProgress,
    bool includeRelations = true, // Чи включати ціни та штрих-коди
  });
  Future<NomenclaturaModel?> getNomenclaturaByGuid(String guid);
  Future<List<NomenclaturaModel>> searchNomenclatura(String query);
  Future<NomenclaturaModel> createNomenclatura(NomenclaturaModel nomenclatura);
  Future<NomenclaturaModel> updateNomenclatura(NomenclaturaModel nomenclatura);
  Future<void> deleteNomenclatura(String guid);
}

class NomenclaturaRemoteDataSourceImpl implements NomenclaturaRemoteDataSource {
  final SupabaseClient supabaseClient;

  NomenclaturaRemoteDataSourceImpl({required this.supabaseClient});

  List<NomenclaturaModel> _parseNomenclatura(
    List<Map<String, dynamic>> records,
  ) {
    return records.map<NomenclaturaModel>((json) {
      final processedJson = Map<String, dynamic>.from(json);

      // View повертає масиви через array_agg
      // Якщо prices - це масив чисел, конвертуємо в список об'єктів
      if (processedJson['prices'] != null) {
        if (processedJson['prices'] is List) {
          final pricesList = processedJson['prices'] as List;
          // Якщо це масив чисел, конвертуємо в список об'єктів з полем price
          if (pricesList.isNotEmpty && pricesList.first is num) {
            processedJson['prices'] = pricesList
                .map(
                  (price) => {
                    'price': price,
                    'nom_guid': processedJson['guid'],
                  },
                )
                .toList();
          }
        } else if (processedJson['prices'] is String) {
          try {
            final decoded = jsonDecode(processedJson['prices']);
            if (decoded is List && decoded.isNotEmpty && decoded.first is num) {
              processedJson['prices'] = decoded
                  .map(
                    (price) => {
                      'price': price,
                      'nom_guid': processedJson['guid'],
                    },
                  )
                  .toList();
            } else {
              processedJson['prices'] = decoded;
            }
          } catch (_) {
            processedJson['prices'] = [];
          }
        }
      } else {
        processedJson['prices'] = [];
      }

      // Аналогічно для barcodes
      if (processedJson['barcodes'] != null) {
        if (processedJson['barcodes'] is List) {
          final barcodesList = processedJson['barcodes'] as List;
          // Якщо це масив рядків, конвертуємо в список об'єктів з полем barcode
          if (barcodesList.isNotEmpty && barcodesList.first is String) {
            processedJson['barcodes'] = barcodesList
                .map(
                  (barcode) => {
                    'barcode': barcode,
                    'nom_guid': processedJson['guid'],
                    'is_deleted': false,
                  },
                )
                .toList();
          }
        } else if (processedJson['barcodes'] is String) {
          try {
            final decoded = jsonDecode(processedJson['barcodes']);
            if (decoded is List &&
                decoded.isNotEmpty &&
                decoded.first is String) {
              processedJson['barcodes'] = decoded
                  .map(
                    (barcode) => {
                      'barcode': barcode,
                      'nom_guid': processedJson['guid'],
                      'is_deleted': false,
                    },
                  )
                  .toList();
            } else {
              processedJson['barcodes'] = decoded;
            }
          } catch (_) {
            processedJson['barcodes'] = [];
          }
        }
      } else {
        processedJson['barcodes'] = [];
      }

      return NomenclaturaModel.fromSupabaseJson(processedJson);
    }).toList();
  }

  @override
  Future<List<NomenclaturaModel>> getAllNomenclatura({
    void Function(String message, double progress)? onProgress,
    bool includeRelations = true,
  }) async {
    try {
      // Отримуємо загальну кількість записів
      final totalResponse = await supabaseClient
          .schema('ut_10_virok_test')
          .from('nomenklatura_with_data')
          .select('guid')
          .count(CountOption.exact);

      final totalCount = totalResponse.count;

      if (totalCount == 0) {
        onProgress?.call('Немає даних для завантаження', 1.0);
        return [];
      }

      onProgress?.call('Початок завантаження $totalCount записів...', 0.0);

      const int pageSize = 1000;
      final List<Map<String, dynamic>> allRecords = [];
      int offset = 0;

      // Завантажуємо дані порціями через offset/limit
      while (offset < totalCount) {
        // Оновлюємо прогрес
        final progress = offset / totalCount;
        onProgress?.call(
          'Завантаження... ${allRecords.length}/$totalCount',
          progress,
        );

        // Отримуємо порцію даних
        final response = await supabaseClient
            .schema('ut_10_virok_test')
            .from('nomenklatura_with_data')
            .select('*')
            .order('guid', ascending: true)
            .range(offset, offset + pageSize - 1);

        if (response.isEmpty) {
          break;
        }

        allRecords.addAll(
          response.map((row) => Map<String, dynamic>.from(row)),
        );

        offset += pageSize;

        // Якщо отримали менше записів, ніж pageSize, значить досягли кінця
        if (response.length < pageSize) {
          break;
        }
      }

      onProgress?.call('Конвертація даних...', 0.95);

      final result = _parseNomenclatura(allRecords);

      onProgress?.call('Завантаження завершено: ${result.length} записів', 1.0);

      return result;
    } catch (e) {
      debugPrint('Error fetching nomenclatura: $e');
      throw ServerFailure('Failed to fetch nomenclatura: $e');
    }
  }

  @override
  Future<NomenclaturaModel?> getNomenclaturaByGuid(String guid) async {
    try {
      final response = await supabaseClient
          .from('nomenklatura')
          .select('''
            *,
            prices(*),
            barcodes(*)
          ''')
          .eq('guid', guid)
          .single();

      return NomenclaturaModel.fromSupabaseJson(response);
    } catch (e) {
      if (e.toString().contains('No rows')) {
        return null;
      }
      throw ServerFailure('Failed to fetch nomenclatura by guid: $e');
    }
  }

  @override
  Future<List<NomenclaturaModel>> searchNomenclatura(String query) async {
    try {
      final response = await supabaseClient
          .from('nomenklatura')
          .select('''
            *,
            prices(*),
            barcodes(*)
          ''')
          .or(
            'name.ilike.%$query%,article.ilike.%$query%,description.ilike.%$query%',
          )
          .order('name');

      return response.map<NomenclaturaModel>((json) {
        return NomenclaturaModel.fromSupabaseJson(json);
      }).toList();
    } catch (e) {
      throw ServerFailure('Failed to search nomenclatura: $e');
    }
  }

  @override
  Future<NomenclaturaModel> createNomenclatura(
    NomenclaturaModel nomenclatura,
  ) async {
    try {
      // Створюємо основний запис номенклатури
      final response = await supabaseClient
          .from('nomenklatura')
          .insert(nomenclatura.toSupabaseJson())
          .select()
          .single();

      final createdNomenclatura = NomenclaturaModel.fromSupabaseJson(response);

      // // Додаємо штрих-коди якщо є
      // if (nomenclatura.barcodes.isNotEmpty) {
      //   final barcodesData = nomenclatura.barcodes
      //       .map((barcode) => barcode.())
      //       .toList();

      //   await supabaseClient.from('barcodes').insert(barcodesData);
      // }

      // // Додаємо ціни якщо є
      // if (nomenclatura.prices.isNotEmpty) {
      //   final pricesData = nomenclatura.prices
      //       .map((price) => price.toSupabaseJson())
      //       .toList();

      //   await supabaseClient.from('prices').insert(pricesData);
      // }

      // Повертаємо повний об'єкт з усіма зв'язаними даними
      return await getNomenclaturaByGuid(createdNomenclatura.guid) ??
          createdNomenclatura;
    } catch (e) {
      throw ServerFailure('Failed to create nomenclatura: $e');
    }
  }

  @override
  Future<NomenclaturaModel> updateNomenclatura(
    NomenclaturaModel nomenclatura,
  ) async {
    try {
      // Оновлюємо основний запис
      final response = await supabaseClient
          .from('nomenklatura')
          .update(nomenclatura.toSupabaseJson())
          .eq('guid', nomenclatura.guid)
          .select()
          .single();

      // Видаляємо старі штрих-коди та ціни
      await supabaseClient
          .from('barcodes')
          .delete()
          .eq('nom_guid', nomenclatura.guid);

      await supabaseClient
          .from('prices')
          .delete()
          .eq('nom_guid', nomenclatura.guid);

      // Додаємо нові штрих-коди
      // if (nomenclatura.barcodes.isNotEmpty) {
      //   final barcodesData = nomenclatura.barcodes
      //       .map((barcode) => barcode.toSupabaseJson())
      //       .toList();

      //   await supabaseClient.from('barcodes').insert(barcodesData);
      // }

      // // Додаємо нові ціни
      // if (nomenclatura.prices.isNotEmpty) {
      //   final pricesData = nomenclatura.prices
      //       .map((price) => price.toSupabaseJson())
      //       .toList();

      //   await supabaseClient.from('prices').insert(pricesData);
      // }

      // Повертаємо повний оновлений об'єкт
      return await getNomenclaturaByGuid(nomenclatura.guid) ??
          NomenclaturaModel.fromSupabaseJson(response);
    } catch (e) {
      throw ServerFailure('Failed to update nomenclatura: $e');
    }
  }

  @override
  Future<void> deleteNomenclatura(String guid) async {
    try {
      // Видаляємо штрих-коди
      await supabaseClient.from('barcodes').delete().eq('nom_guid', guid);

      // Видаляємо ціни
      await supabaseClient.from('prices').delete().eq('nom_guid', guid);

      // Видаляємо основний запис
      await supabaseClient.from('nomenklatura').delete().eq('guid', guid);
    } catch (e) {
      throw ServerFailure('Failed to delete nomenclatura: $e');
    }
  }
}
