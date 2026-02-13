import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/cashalot/com/cashalot_com_service.dart';
import '../../../../core/services/prro/prro_service.dart';
import '../../../../core/services/storage/storage_service.dart';
import '../../../../core/widgets/notificarion_toast/toast_manager.dart';
import '../../../../core/widgets/notificarion_toast/toast_type.dart';
import '../../data/datasources/shift_remote_data_source.dart';
import '../bloc/home_bloc.dart';

/// Етапи закриття зміни
enum _CloseShiftStep { loading, serviceIssue, closing }

/// [rootContext] must be a context that is under the [HomeBloc] provider.
Future<void> showCloseShiftDialog(
  BuildContext rootContext, {
  bool cancelButtonVisible = false,
}) async {
  await showDialog(
    context: rootContext,
    barrierDismissible: false,
    builder: (ctx) {
      return _CloseShiftContent(
        cancelButtonVisible: cancelButtonVisible,
        rootContext: rootContext,
      );
    },
  );
}

class _CloseShiftContent extends StatefulWidget {
  final bool cancelButtonVisible;
  final BuildContext rootContext;

  const _CloseShiftContent({
    required this.cancelButtonVisible,
    required this.rootContext,
  });

  @override
  State<_CloseShiftContent> createState() => _CloseShiftContentState();
}

class _CloseShiftContentState extends State<_CloseShiftContent> {
  double _openingAmount = 0.0;
  double _salesAmountCash = 0.0;
  double _salesAmountCashless = 0.0;
  double _prroCashBalance = 0.0; // Залишок готівки з ПРРО
  int? _shiftId;
  DateTime? openedAt;
  final TextEditingController _closeAmountController = TextEditingController();

  // Стан процесу закриття
  _CloseShiftStep _currentStep = _CloseShiftStep.loading;
  String? _prroError;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final shiftDataSource = ShiftRemoteDataSource(Supabase.instance.client);

      // 1. Беремо останню відкриту зміну користувача
      final shift = await shiftDataSource.getLastOpenedShift();
      if (shift == null) throw Exception('Немає відкритої зміни');

      _shiftId = shift['id'] as int;
      _openingAmount = (shift['opening_amount'] as num?)?.toDouble() ?? 0.0;
      openedAt = DateTime.parse(shift['opened_at'] as String);

      // 2. Беремо суми по формі оплати (групування)
      final salesData = await shiftDataSource.getShiftSalesData(openedAt!);
      final salesCash = salesData['cash'] ?? 0.0;
      final salesCashless = salesData['cashless'] ?? 0.0;

      // 3. Отримуємо стан ПРРО (залишок готівки)
      await _fetchPrroState();

      setState(() {
        _salesAmountCash = salesCash;
        _salesAmountCashless = salesCashless;
        // Використовуємо залишок з ПРРО для видачі
        _closeAmountController.text = (_prroCashBalance).toStringAsFixed(2);
        _currentStep = _CloseShiftStep.serviceIssue;
      });
    } catch (e) {
      if (!mounted) return;
      ToastManager.show(
        context,
        type: ToastType.error,
        title: 'Помилка ініціалізації закриття зміни: $e',
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _fetchPrroState() async {
    try {
      final cashalotService = GetIt.instance<CashalotComService>();
      // TODO: отримати фіскальний номер з налаштувань
      const prroFiscalNum = 4000944684;

      final response = await cashalotService.getPrroState(
        prroFiscalNum: prroFiscalNum,
      );

      if (response.errorCode != null) {
        _prroError = response.errorMessage ?? 'Помилка отримання стану ПРРО';
        _prroCashBalance = 0.0;
      } else {
        final data = response.data;
        _prroCashBalance = double.parse(
          data?['CashBalance'] as String ?? '0.0',
        );
      }
    } catch (e) {
      _prroError = 'Не вдалося отримати стан ПРРО: $e';
      _prroCashBalance = 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2A2A2A),
      title: _buildTitle(),
      content: _buildContent(),
      actions: _buildActions(),
    );
  }

  Widget _buildTitle() {
    switch (_currentStep) {
      case _CloseShiftStep.loading:
        return const Text(
          'Підготовка до закриття зміни...',
          style: TextStyle(color: Colors.white),
        );
      case _CloseShiftStep.serviceIssue:
        return Row(
          children: [
            const Icon(Icons.account_balance_wallet, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Крок 1: Службова видача',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      case _CloseShiftStep.closing:
        return Row(
          children: [
            const Icon(Icons.lock_outline, color: Colors.orange),
            const SizedBox(width: 8),
            Text(
              openedAt != null
                  ? 'Крок 2: Закриття зміни (${DateFormat('dd.MM.yyyy HH:mm').format(openedAt!)})'
                  : 'Крок 2: Закриття зміни',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        );
    }
  }

  Widget _buildContent() {
    switch (_currentStep) {
      case _CloseShiftStep.loading:
        return const SizedBox(
          height: 100,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 16),
                Text(
                  'Отримання стану ПРРО...',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        );

      case _CloseShiftStep.serviceIssue:
        return SizedBox(
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Попередження про помилку ПРРО (якщо є)
              if (_prroError != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _prroError!,
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Інформація про зміну
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      'Внесено при відкритті',
                      '${_openingAmount.toStringAsFixed(2)} грн',
                    ),
                    _buildInfoRow(
                      'Виручка готівкою',
                      '${_salesAmountCash.toStringAsFixed(2)} грн',
                    ),
                    _buildInfoRow(
                      'Виручка карткою',
                      '${_salesAmountCashless.toStringAsFixed(2)} грн',
                    ),
                    const Divider(color: Colors.white24, height: 16),
                    _buildInfoRow(
                      'Залишок готівки (ПРРО)',
                      '${_prroCashBalance.toStringAsFixed(2)} грн',
                      valueColor: Colors.greenAccent,
                      isBold: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Поле для введення суми видачі
              TextField(
                controller: _closeAmountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(color: Colors.white, fontSize: 18),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    final text = newValue.text;
                    if (text.isEmpty) return newValue;
                    final dotCount = text.split('.').length - 1;
                    final commaCount = text.split(',').length - 1;
                    if (dotCount + commaCount > 1) return oldValue;
                    if (text.contains('.') || text.contains(',')) {
                      final split = text.split(RegExp(r'[.,]'));
                      if (split.length > 1 && split[1].length > 2)
                        return oldValue;
                    }
                    return newValue;
                  }),
                ],
                decoration: InputDecoration(
                  labelText: 'Сума для службової видачі',
                  labelStyle: const TextStyle(color: Colors.white70),
                  suffixText: 'грн',
                  suffixStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 8),
              Text(
                'Ця сума буде вилучена з каси перед закриттям зміни',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        );

      case _CloseShiftStep.closing:
        return const SizedBox(
          height: 100,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 16),
                Text(
                  'Закриття зміни (Z-звіт)...',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        );
    }
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActions() {
    switch (_currentStep) {
      case _CloseShiftStep.loading:
        return [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Скасувати'),
          ),
        ];

      case _CloseShiftStep.serviceIssue:
        return [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Скасувати',
              style: TextStyle(color: Colors.white),
            ),
          ),
          ElevatedButton.icon(
            onPressed: _proceedWithServiceIssue,
            icon: const Icon(Icons.arrow_forward, color: Colors.white),
            label: const Text(
              'Виконати видачу та закрити зміну',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          ),
        ];

      case _CloseShiftStep.closing:
        return [];
    }
  }

  Future<void> _proceedWithServiceIssue() async {
    final issueAmount =
        double.tryParse(
          _closeAmountController.text.trim().replaceAll(',', '.'),
        ) ??
        0.0;

    // Перевіряємо суму
    if (issueAmount < 0) {
      ToastManager.show(
        context,
        type: ToastType.error,
        title: 'Некоректна сума видачі',
      );
      return;
    }

    try {
      // Показуємо стан закриття
      setState(() {
        _currentStep = _CloseShiftStep.closing;
      });

      final prroService = GetIt.instance<PrroService>();
      final storageService = GetIt.instance<StorageService>();

      // Отримуємо ім'я касира
      final cashierName =
          (await storageService.getUserEmail())?.split('@')[0] ?? 'Касир';

      // 1. Якщо є сума для видачі - виконуємо службову видачу І ЧЕКАЄМО НА ЗАВЕРШЕННЯ
      if (issueAmount > 0) {
        debugPrint(
          '💸 [CLOSE_SHIFT_DIALOG] Крок 1: Службова видача $issueAmount грн...',
        );
        final serviceOutResult = await prroService.serviceOut(
          issueAmount,
          cashier: cashierName,
        );

        if (serviceOutResult == null) {
          throw Exception('Помилка службової видачі');
        }
        debugPrint('✅ [CLOSE_SHIFT_DIALOG] Службова видача завершена успішно');
      }

      // 2. Виконуємо фіскальне закриття зміни (Z-звіт) І ЧЕКАЄМО НА ЗАВЕРШЕННЯ
      debugPrint('🔒 [CLOSE_SHIFT_DIALOG] Крок 2: Закриття зміни (Z-звіт)...');
      final closeShiftResult = await prroService.closeShift();

      if (closeShiftResult == null) {
        throw Exception('Помилка закриття зміни (Z-звіт)');
      }
      debugPrint('✅ [CLOSE_SHIFT_DIALOG] Z-звіт отримано успішно');

      // 3. Зберігаємо закриття зміни в Supabase
      debugPrint('💾 [CLOSE_SHIFT_DIALOG] Крок 3: Збереження в Supabase...');
      final shiftDataSource = ShiftRemoteDataSource(Supabase.instance.client);
      await shiftDataSource.closeShift(
        shiftId: _shiftId!,
        closingAmount: issueAmount,
        salesAmountCash: _salesAmountCash,
        salesAmountCashless: _salesAmountCashless,
      );
      debugPrint('✅ [CLOSE_SHIFT_DIALOG] Дані збережено в Supabase');

      // 4. Оновлюємо стан HomeBloc (очищаємо openedShiftAt)
      if (widget.rootContext.mounted) {
        final homeBloc = widget.rootContext.read<HomeBloc>();
        // Оновлюємо стан - зміна закрита
        homeBloc.add(const ShiftClosedEvent());
      }

      if (mounted) {
        Navigator.of(context).pop();
        ToastManager.show(
          context,
          type: ToastType.success,
          title: 'Зміна успішно закрита',
          message: issueAmount > 0
              ? 'Службова видача: ${issueAmount.toStringAsFixed(2)} грн'
              : null,
        );
      }
    } catch (e) {
      debugPrint('❌ [CLOSE_SHIFT_DIALOG] Помилка: $e');
      if (!mounted) return;

      setState(() {
        _currentStep = _CloseShiftStep.serviceIssue;
      });

      ToastManager.show(
        context,
        type: ToastType.error,
        title: 'Помилка закриття зміни',
        message: e.toString(),
      );
    }
  }
}
