import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/widgets/notificarion_toast/toast_manager.dart';
import '../../../../core/widgets/notificarion_toast/toast_type.dart';
import '../../data/datasources/shift_remote_data_source.dart';
import '../bloc/home_bloc.dart';

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
  bool _loading = true;
  double _openingAmount = 0.0;
  double _salesAmountCash = 0.0;
  double _salesAmountCashless = 0.0;
  int? _shiftId;
  DateTime? openedAt;
  final TextEditingController _closeAmountController = TextEditingController();

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

      setState(() {
        _salesAmountCash = salesCash;
        _salesAmountCashless = salesCashless;
        _closeAmountController.text = (_openingAmount + salesCash)
            .toStringAsFixed(2);
        _loading = false;
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2A2A2A),

      title: Text(
        openedAt != null
            ? 'Закриття зміни за ${DateFormat('yyyy-MM-dd HH:mm').format(openedAt!)}'
            : 'Закриття зміни',
        style: const TextStyle(color: Colors.white),
      ),
      content: _loading
          ? const SizedBox(
              height: 80,
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Внесено при відкритті: ${_openingAmount.toStringAsFixed(2)} грн',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 6),
                Text(
                  'Виручка за зміну: ${_salesAmountCash.toStringAsFixed(2)} грн',
                  style: const TextStyle(color: Colors.white70),
                ),
                Text(
                  '(готівка)',
                  style: TextStyle(color: Colors.white70, fontSize: 10),
                ),
                const SizedBox(height: 6),
                Text(
                  'Виручка за зміну: ${_salesAmountCashless.toStringAsFixed(2)} грн',
                  style: const TextStyle(color: Colors.white70),
                ),
                Text(
                  '(картка)',
                  style: TextStyle(color: Colors.white70, fontSize: 10),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _closeAmountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Сума для вилучення',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Скасувати'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _confirmClose,
          child: const Text('Закрити зміну'),
        ),
      ],
    );
  }

  Future<void> _confirmClose() async {
    try {
      final closingAmount =
          double.tryParse(
            _closeAmountController.text.trim().replaceAll(',', '.'),
          ) ??
          0.0;

      // Фіскальне закриття зміни (Z-звіт) через HomeBloc
      if (mounted && widget.rootContext.mounted) {
        final homeBloc = widget.rootContext.read<HomeBloc>();
        homeBloc.add(const CloseCashalotShift());
        // Зберігаємо закриття зміни в Supabase
        final shiftDataSource = ShiftRemoteDataSource(Supabase.instance.client);
        await shiftDataSource.closeShift(
          shiftId: _shiftId!,
          closingAmount: closingAmount,
          salesAmountCash: _salesAmountCash,
          salesAmountCashless: _salesAmountCashless,
        );
        Navigator.of(context).pop();
      }

      if (mounted) {
        ToastManager.show(
          context,
          type: ToastType.success,
          title: 'Зміна закрита',
        );
        // Navigator.pushReplacementNamed(context, AppRouter.login);
      }
    } catch (e) {
      if (!mounted) return;
      ToastManager.show(
        context,
        type: ToastType.error,
        title: 'Помилка закриття зміни',
        exception: e as Exception,
      );
    }
  }
}
