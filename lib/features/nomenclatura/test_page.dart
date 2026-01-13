import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'data/datasources/nomenclatura_remote_data_source.dart';
import 'data/datasources/nomenclatura_local_data_source.dart';
import 'data/repositories/nomenclatura_repository_impl.dart';
import 'domain/repositories/nomenclatura_repository.dart';
import 'domain/usecases/get_all_nomenclatura.dart';
import 'domain/usecases/search_nomenclatura.dart';
import 'domain/usecases/sync_nomenclatura.dart';
import 'domain/entities/nomenclatura.dart';

class NomenclaturaTestPage extends StatefulWidget {
  const NomenclaturaTestPage({super.key});

  @override
  State<NomenclaturaTestPage> createState() => _NomenclaturaTestPageState();
}

class _NomenclaturaTestPageState extends State<NomenclaturaTestPage> {
  final GetIt _sl = GetIt.instance;
  List<Nomenclatura> _nomenclaturas = [];
  bool _isLoading = false;
  String _status = 'Готовий до роботи';
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeDependencies();
  }

  Future<void> _initializeDependencies() async {
    try {
      // Реєстрація залежностей
      if (!_sl.isRegistered<NomenclaturaRemoteDataSource>()) {
        _sl.registerLazySingleton<NomenclaturaRemoteDataSource>(
          () => NomenclaturaRemoteDataSourceImpl(
            supabaseClient: Supabase.instance.client,
          ),
        );
      }

      if (!_sl.isRegistered<NomenclaturaLocalDataSource>()) {
        _sl.registerLazySingleton<NomenclaturaLocalDataSource>(
          () => NomenclaturaLocalDataSourceImpl(),
        );
      }

      if (!_sl.isRegistered<Connectivity>()) {
        _sl.registerLazySingleton(() => Connectivity());
      }

      if (!_sl.isRegistered<NomenclaturaRepository>()) {
        _sl.registerLazySingleton<NomenclaturaRepository>(
          () => NomenclaturaRepositoryImpl(
            remoteDataSource: _sl<NomenclaturaRemoteDataSource>(),
            localDataSource: _sl<NomenclaturaLocalDataSource>(),
            connectivity: _sl<Connectivity>(),
          ),
        );
      }

      if (!_sl.isRegistered<GetAllNomenclatura>()) {
        _sl.registerLazySingleton(
          () => GetAllNomenclatura(_sl<NomenclaturaRepository>()),
        );
      }

      if (!_sl.isRegistered<SearchNomenclatura>()) {
        _sl.registerLazySingleton(
          () => SearchNomenclatura(_sl<NomenclaturaRepository>()),
        );
      }

      if (!_sl.isRegistered<SyncNomenclatura>()) {
        _sl.registerLazySingleton(
          () => SyncNomenclatura(_sl<NomenclaturaRepository>()),
        );
      }

      setState(() {
        _isInitialized = true;
        _status = 'Ініціалізовано успішно';
      });
    } catch (e) {
      setState(() {
        _status = 'Помилка ініціалізації: $e';
      });
    }
  }

  Future<void> _loadAllNomenclatura() async {
    if (!_isInitialized) return;

    setState(() {
      _isLoading = true;
      _status = 'Завантаження номенклатури...';
    });

    try {
      final getAllNomenclatura = _sl<GetAllNomenclatura>();
      final result = await getAllNomenclatura(
        onProgress: (message, progress) {
          setState(() {
            _status = '$message (${(progress * 100).toInt()}%)';
          });
        },
      );

      result.fold(
        (failure) {
          setState(() {
            _status = 'Помилка: ${failure.runtimeType}';
          });
        },
        (nomenclaturas) {
          setState(() {
            _nomenclaturas = nomenclaturas;
            _status =
                'Успішно завантажено ${nomenclaturas.length} записів номенклатури!';
          });
        },
      );
    } catch (e) {
      setState(() {
        _status = 'Виняток: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadNomenclaturaFast() async {
    if (!_isInitialized) return;

    setState(() {
      _isLoading = true;
      _status = 'Швидке завантаження...';
    });

    try {
      final getAllNomenclatura = _sl<GetAllNomenclatura>();
      final result = await getAllNomenclatura(
        onProgress: (message, progress) {
          setState(() {
            _status = '(Швидко) $message (${(progress * 100).toInt()}%)';
          });
        },
        includeRelations: false, // Без цін та штрих-кодів
      );

      result.fold(
        (failure) {
          setState(() {
            _status = 'Помилка: ${failure.runtimeType}';
          });
        },
        (nomenclaturas) {
          setState(() {
            _nomenclaturas = nomenclaturas;
            _status =
                'Швидко завантажено ${nomenclaturas.length} записів (без цін та штрих-кодів)';
          });
        },
      );
    } catch (e) {
      setState(() {
        _status = 'Виняток: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _syncWithServer() async {
    if (!_isInitialized) return;

    setState(() {
      _isLoading = true;
      _status = 'Синхронізація...';
    });

    try {
      final syncNomenclatura = _sl<SyncNomenclatura>();
      final result = await syncNomenclatura();

      result.fold(
        (failure) {
          setState(() {
            _status = 'Помилка синхронізації: ${failure.runtimeType}';
          });
        },
        (_) {
          setState(() {
            _status = 'Синхронізація завершена';
          });
        },
      );
    } catch (e) {
      setState(() {
        _status = 'Виняток синхронізації: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _searchNomenclatura() async {
    if (!_isInitialized) return;

    setState(() {
      _isLoading = true;
      _status = 'Пошук...';
    });

    try {
      final searchNomenclatura = _sl<SearchNomenclatura>();
      final result = await searchNomenclatura('test');

      result.fold(
        (failure) {
          setState(() {
            _status = 'Помилка пошуку: ${failure.runtimeType}';
          });
        },
        (results) {
          setState(() {
            _nomenclaturas = results;
            _status = 'Знайдено ${results.length} результатів';
          });
        },
      );
    } catch (e) {
      setState(() {
        _status = 'Виняток пошуку: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Тест Nomenclatura'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    if (_isLoading) const CircularProgressIndicator(),
                    const SizedBox(height: 8),
                    Text(
                      _status,
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_isInitialized) ...[
              ElevatedButton(
                onPressed: _isLoading ? null : _loadAllNomenclatura,
                child: const Text('Завантажити всю номенклатуру'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _isLoading ? null : _loadNomenclaturaFast,
                child: const Text('Швидке завантаження (без цін)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[50],
                  foregroundColor: Colors.green[700],
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _isLoading ? null : _syncWithServer,
                child: const Text('Синхронізувати з сервером'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _isLoading ? null : _searchNomenclatura,
                child: const Text('Пошук "test"'),
              ),
            ],
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _nomenclaturas.length,
                itemBuilder: (context, index) {
                  final item = _nomenclaturas[index];
                  return ListTile(
                    title: Text(item.name),
                    subtitle: Text('Артикул: ${item.article}'),
                    trailing: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('ШК: ${item.barcodes.length}'),
                        Text('Цін: ${item.prices}'),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
