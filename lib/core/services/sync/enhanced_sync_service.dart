import 'package:dartz/dartz.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:cash_register/features/nomenclatura/domain/repositories/nomenclatura_repository.dart';
import 'package:cash_register/core/error/failures.dart';

enum SyncStatus {
  upToDate, // Дані актуальні
  needsUpdate, // Потребує оновлення
  noConnection, // Немає з'єднання
  noData, // Немає локальних даних
  error, // Помилка при перевірці
  syncing, // В процесі синхронізації
}

class EnhancedSyncInfo {
  final SyncStatus status;
  final DateTime? lastSyncTime;
  final int totalItems;
  final int syncedItems;
  final bool isConnected;
  final String? errorMessage;
  final double? progress;
  final String? currentOperation;

  const EnhancedSyncInfo({
    required this.status,
    this.lastSyncTime,
    this.totalItems = 0,
    this.syncedItems = 0,
    this.isConnected = false,
    this.errorMessage,
    this.progress,
    this.currentOperation,
  });

  bool get needsSync =>
      status == SyncStatus.needsUpdate || status == SyncStatus.noData;
  bool get canSync =>
      status != SyncStatus.noConnection &&
      status != SyncStatus.error &&
      status != SyncStatus.syncing;
  bool get isSyncing => status == SyncStatus.syncing;

  double get syncProgress {
    if (totalItems == 0) return 0.0;
    return syncedItems / totalItems;
  }
}

class SyncOperation {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final bool isEnabled;
  final int priority;

  const SyncOperation({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.isEnabled = true,
    this.priority = 0,
  });
}

abstract class EnhancedSyncService {
  Future<EnhancedSyncInfo> getSyncInfo();
  Future<Either<Failure, void>> performSync({
    List<String>? operations,
    void Function(String operation, double progress)? onProgress,
  });
  Future<Either<Failure, void>> performFullSync({
    void Function(String operation, double progress)? onProgress,
  });
  Future<Either<Failure, void>> performQuickSync({
    void Function(String operation, double progress)? onProgress,
  });
  Future<Either<Failure, void>> clearAllData();
  Future<List<SyncOperation>> getAvailableOperations();
  Future<bool> hasInternetConnection();
  Stream<EnhancedSyncInfo> getSyncInfoStream();
}

class EnhancedSyncServiceImpl implements EnhancedSyncService {
  final NomenclaturaRepository nomenclaturaRepository;
  final Connectivity connectivity;

  // Час після якого дані вважаються застарілими (24 години)
  static const Duration syncThreshold = Duration(hours: 24);

  EnhancedSyncServiceImpl({
    required this.nomenclaturaRepository,
    required this.connectivity,
  });

  @override
  Future<EnhancedSyncInfo> getSyncInfo() async {
    try {
      // Перевіряємо з'єднання
      final isConnected = await hasInternetConnection();

      // Отримуємо локальні дані
      final localDataResult = await nomenclaturaRepository
          .getCachedNomenclatura();
      final localCount = localDataResult.fold((l) => 0, (r) => r.length);

      // Отримуємо час останньої синхронізації
      final lastSyncResult = await nomenclaturaRepository.getLastSyncTime();
      final lastSyncTime = lastSyncResult.fold((l) => null, (r) => r);

      // Визначаємо статус
      SyncStatus status;
      if (!isConnected) {
        status = localCount > 0 ? SyncStatus.noConnection : SyncStatus.noData;
      } else if (localCount == 0) {
        status = SyncStatus.noData;
      } else if (lastSyncTime == null) {
        status = SyncStatus.needsUpdate;
      } else {
        final timeSinceLastSync = DateTime.now().difference(lastSyncTime);
        status = timeSinceLastSync > syncThreshold
            ? SyncStatus.needsUpdate
            : SyncStatus.upToDate;
      }

      return EnhancedSyncInfo(
        status: status,
        lastSyncTime: lastSyncTime,
        totalItems: localCount,
        syncedItems: localCount,
        isConnected: isConnected,
      );
    } catch (e) {
      return EnhancedSyncInfo(
        status: SyncStatus.error,
        errorMessage: e.toString(),
        isConnected: false,
      );
    }
  }

  @override
  Future<Either<Failure, void>> performSync({
    List<String>? operations,
    void Function(String operation, double progress)? onProgress,
  }) async {
    try {
      onProgress?.call('Початок синхронізації...', 0.0);

      // Перевіряємо з'єднання
      if (!await hasInternetConnection()) {
        return Left(NetworkFailure('Немає з\'єднання з інтернетом'));
      }

      // Визначаємо операції для виконання
      final operationsToPerform = operations ?? ['nomenclatura'];
      double totalProgress = 0.0;
      final progressStep = 1.0 / operationsToPerform.length;

      for (final operationId in operationsToPerform) {
        onProgress?.call('Виконання $operationId...', totalProgress);

        switch (operationId) {
          case 'nomenclatura':
            final result = await _syncNomenclatura();
            if (result.isLeft()) {
              return result.fold(
                (failure) => Left(failure),
                (_) => const Right(null),
              );
            }
            break;
          // Тут можна додати інші операції
        }

        totalProgress += progressStep;
      }

      onProgress?.call('Синхронізація завершена', 1.0);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Помилка синхронізації: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> performFullSync({
    void Function(String operation, double progress)? onProgress,
  }) async {
    return performSync(operations: ['nomenclatura'], onProgress: onProgress);
  }

  @override
  Future<Either<Failure, void>> performQuickSync({
    void Function(String operation, double progress)? onProgress,
  }) async {
    try {
      onProgress?.call('Швидка синхронізація...', 0.0);

      // Перевіряємо з'єднання
      if (!await hasInternetConnection()) {
        return Left(NetworkFailure('Немає з\'єднання з інтернетом'));
      }

      // Швидка синхронізація без зв'язків
      onProgress?.call('Завантаження номенклатури...', 0.5);
      final result = await nomenclaturaRepository.getAllNomenclatura(
        includeRelations: false,
      );

      if (result.isLeft()) {
        return result.fold(
          (failure) => Left(failure),
          (_) => const Right(null),
        );
      }

      onProgress?.call('Швидка синхронізація завершена', 1.0);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Помилка швидкої синхронізації: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> clearAllData() async {
    try {
      final result = await nomenclaturaRepository.clearCache();
      return result.fold((failure) => Left(failure), (_) => const Right(null));
    } catch (e) {
      return Left(CacheFailure('Помилка очищення даних: $e'));
    }
  }

  @override
  Future<List<SyncOperation>> getAvailableOperations() async {
    return [
      const SyncOperation(
        id: 'nomenclatura',
        name: 'Номенклатура',
        description: 'Синхронізація товарів та категорій',
        icon: Icons.inventory,
        priority: 1,
      ),
      // Тут можна додати інші операції
    ];
  }

  @override
  Future<bool> hasInternetConnection() async {
    try {
      final connectivityResult = await connectivity.checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  @override
  Stream<EnhancedSyncInfo> getSyncInfoStream() async* {
    while (true) {
      yield await getSyncInfo();
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  Future<Either<Failure, void>> _syncNomenclatura() async {
    try {
      final result = await nomenclaturaRepository.syncWithServer();
      return result.fold((failure) => Left(failure), (_) => const Right(null));
    } catch (e) {
      return Left(ServerFailure('Помилка синхронізації номенклатури: $e'));
    }
  }
}
