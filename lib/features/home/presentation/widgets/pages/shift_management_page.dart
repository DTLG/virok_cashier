import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../bloc/home_bloc.dart';
import '../../dialogs/open_shift_dialog.dart';
import '../../dialogs/close_shift_dialog.dart';
import '../../../../../core/widgets/notificarion_toast/toast_manager.dart';
import '../../../../../core/widgets/notificarion_toast/toast_type.dart';
import '../../dialogs/x_report_dialog.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../home/data/datasources/shift_remote_data_source.dart';

class ShiftManagementPage extends StatefulWidget {
  const ShiftManagementPage({super.key});

  @override
  State<ShiftManagementPage> createState() => _ShiftManagementPageState();
}

class _ShiftManagementPageState extends State<ShiftManagementPage> {
  bool _requestedShiftStatus = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_requestedShiftStatus) {
      _requestedShiftStatus = true;
      context.read<HomeBloc>().add(const CheckTodayShiftPrompt());
    }
  }

  @override
  Widget build(BuildContext context) {
    // Використовуємо BlocConsumer, щоб слухати зміни (Listener) і будувати UI (Builder)
    return BlocConsumer<HomeBloc, HomeViewState>(
      listenWhen: (previous, current) {
        // Слухаємо тільки якщо з'явилися нові дані звіту
        return previous.xReportData != current.xReportData &&
            current.xReportData != null;
      },
      listener: (context, state) {
        // Обробка успіху очищення ПРРО
        if (state.status == HomeStatus.cleanupSuccess) {
          ToastManager.show(
            context,
            type: ToastType.success,
            title: 'ПРРО успішно синхронізовано!',
          );
        }
        // Якщо прийшли дані звіту - показуємо діалог
        // if (state.xReportData != null) {
        //   showDialog(
        //     context: context,
        //     barrierDismissible: false, // Забороняємо закривати кліком повз
        //     builder: (context) => XReportDialog(
        //       reportData: state.xReportData!,
        //       // ВАЖЛИВО: Передаємо візуалізацію з об'єкта звіту
        //       // Переконайтесь, що ви додали це поле в модель XReportData (див. нижче)
        //       visualization: state.xReportData!.visualization,
        //       title: state.xReportData!.isZRep ? 'Z-Звіт (Закриття)' : 'X-Звіт',
        //     ),
        //   ).then((_) {
        //     // Коли діалог закрився - очищаємо дані в блоці, щоб діалог не відкрився знову
        //     if (context.mounted) {
        //       context.read<HomeBloc>().add(const ClearXReportData());
        //     }
        //   });
        // }

        // Обробка помилок
        if (state.status == HomeStatus.error && state.errorMessage.isNotEmpty) {
          ToastManager.show(
            context,
            type: ToastType.error,
            title: state.errorMessage,
          );
        }
      },
      builder: (context, state) {
        final bool shiftOpen = state.openedShiftAt != null;
        final bool loading = state.status == HomeStatus.loading;
        final openedAtStr = state.openedShiftAt != null
            ? DateFormat('HH:mm').format(state.openedShiftAt!)
            : null;

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                // ... ВЕСЬ ВАШ UI КОД БЕЗ ЗМІН ...
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ... (код кнопок і текстів залишається той самий)
                  // ...
                  // Нижче наведено скорочений приклад кнопок, щоб показати структуру:

                  // Якщо зміна закрита
                  if (!shiftOpen) ...[
                    _primaryButton(
                      context,
                      label: 'Відкрити зміну',
                      color: Colors.green,
                      icon: Icons.play_arrow_rounded,
                      loading: loading,
                      onPressed: () => showOpenShiftDialog(context),
                    ),
                  ] else ...[
                    // Якщо зміна відкрита
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _primaryButton(
                          context,
                          label: 'Службове внесення',
                          color: Colors.blue,
                          icon: Icons.account_balance_wallet_outlined,
                          loading: loading,
                          onPressed: () => _showServiceDepositDialog(context),
                        ),
                        _primaryButton(
                          context,
                          label: 'Службова видача',
                          color: Colors.blue,
                          icon: Icons.account_balance_wallet_rounded,
                          loading: loading,
                          onPressed: () {
                            _showServiceIssueDialog(context);
                          },
                        ),
                        _primaryButton(
                          context,
                          label: 'X-Звіт',
                          color: Colors.teal,
                          icon: Icons.receipt_long,
                          loading: loading,
                          onPressed: () => context.read<HomeBloc>().add(
                            const XReportEvent(),
                          ),
                        ),
                        _primaryButton(
                          context,
                          label: 'Z-Звіт (Закрити)',
                          color: Colors.redAccent,
                          icon: Icons.lock_outline,
                          loading: loading,
                          onPressed: () => showCloseShiftDialog(context),
                        ),
                        _primaryButton(
                          context,
                          label: 'Очистити ПРРО(Синхронізація) Z-звіт',
                          color: Colors.redAccent,
                          icon: Icons.lock_outline,
                          loading: loading,
                          onPressed: () async {
                            final shiftDataSource = ShiftRemoteDataSource(
                              Supabase.instance.client,
                            );
                            // 1. Беремо останню відкриту зміну користувача
                            final shift = await shiftDataSource
                                .getLastOpenedShift();
                            if (shift == null)
                              throw Exception('Немає відкритої зміни');

                            final shiftId = shift['id'] as int;
                            final openingAmount =
                                (shift['opening_amount'] as num?)?.toDouble() ??
                                0.0;
                            final openedAt = DateTime.parse(
                              shift['opened_at'] as String,
                            );

                            // 2. Беремо суми по формі оплати (групування)
                            final salesData = await shiftDataSource
                                .getShiftSalesData(openedAt!);
                            final salesCash = salesData['cash'] ?? 0.0;
                            final salesCashless = salesData['cashless'] ?? 0.0;

                            await shiftDataSource.closeShift(
                              shiftId: shiftId,
                              closingAmount: openingAmount,
                              salesAmountCash: salesCash,
                              salesAmountCashless: salesCashless,
                            );
                            context.read<HomeBloc>().add(
                              const CleanupCashalotEvent(),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                  // ...
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _primaryButton(
    BuildContext context, {
    required String label,
    required Color color,
    required IconData icon,
    required bool loading,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 220,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: Icon(icon),
        label: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Future<void> _showServiceIssueDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Службова видача',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: 400,
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white),

            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),

              TextInputFormatter.withFunction((oldValue, newValue) {
                final text = newValue.text;

                if (text.isEmpty) return newValue;

                final dotCount = text.split('.').length - 1;
                final commaCount = text.split(',').length - 1;

                if (dotCount + commaCount > 1) {
                  return oldValue;
                }

                if (text.contains('.') || text.contains(',')) {
                  final split = text.split(RegExp(r'[.,]'));
                  if (split.length > 1 && split[1].length > 2) {
                    return oldValue;
                  }
                }

                return newValue;
              }),
            ],

            decoration: const InputDecoration(
              labelText: 'Службова видача готівкових коштів на суму, грн',
              labelStyle: TextStyle(color: Colors.white70),
              suffixText: 'грн',
              suffixStyle: TextStyle(color: Colors.white70),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Скасувати'),
          ),
          ElevatedButton(
            onPressed: () {
              // Ваша існуюча логіка обробки (вона залишається правильною)
              final amount = double.tryParse(
                controller.text.trim().replaceAll(',', '.'),
              );

              if (amount == null || amount < 0) {
                ToastManager.show(
                  ctx,
                  type: ToastType.error,
                  title: 'Некоректна сума',
                );
                return;
              }

              context.read<HomeBloc>().add(ServiceIssueEvent(amount: amount));
              Navigator.of(ctx).pop();
            },
            child: const Text('Підтвердити'),
          ),
        ],
      ),
    );
  }

  Future<void> _showServiceDepositDialog(BuildContext context) async {
    final controller = TextEditingController();

    return showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: const Text(
            'Службове внесення',
            style: TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: 400,
            child: TextField(
              controller: controller,
              // Вказуємо клавіатуру з крапкою/комою
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(color: Colors.white),

              // === ДОДАНО ВАЛІДАЦІЮ ===
              inputFormatters: [
                // 1. Дозволяємо вводити лише цифри, крапку та кому (забороняємо літери, пробіли, спецсимволи)
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),

                // 2. Логіка для заборони двох крапок/ком та обмеження 2 знаків після коми
                TextInputFormatter.withFunction((oldValue, newValue) {
                  final text = newValue.text;

                  // Якщо поле пусте - дозволяємо
                  if (text.isEmpty) return newValue;

                  // Перевіряємо, щоб не було більше однієї коми або крапки
                  final dotCount = text.split('.').length - 1;
                  final commaCount = text.split(',').length - 1;

                  if (dotCount + commaCount > 1) {
                    return oldValue; // Повертаємо старе значення (блокуємо введення)
                  }

                  // Перевіряємо, щоб після коми/крапки було не більше 2 цифр (для копійок)
                  if (text.contains('.') || text.contains(',')) {
                    final split = text.split(RegExp(r'[.,]'));
                    if (split.length > 1 && split[1].length > 2) {
                      return oldValue;
                    }
                  }

                  return newValue;
                }),
              ],

              // =========================
              decoration: const InputDecoration(
                labelText: 'Службове внесення готівкових коштів на суму, грн',
                labelStyle: TextStyle(color: Colors.white70),
                // Додаємо підказку або суфікс валюти
                suffixText: 'грн',
                suffixStyle: TextStyle(color: Colors.white70),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Скасувати'),
            ),
            ElevatedButton(
              onPressed: () {
                // Ваша існуюча логіка обробки (вона залишається правильною)
                final amount = double.tryParse(
                  controller.text.trim().replaceAll(',', '.'),
                );

                if (amount == null || amount < 0) {
                  ToastManager.show(
                    ctx,
                    type: ToastType.error,
                    title: 'Некоректна сума',
                  );
                  return;
                }

                context.read<HomeBloc>().add(
                  ServiceDepositEvent(amount: amount),
                );
                Navigator.of(ctx).pop();
              },
              child: const Text('Підтвердити'),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Вийти з акаунту',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Ви впевнені, що хочете вийти з акаунту?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(
              'Скасувати',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              context.read<HomeBloc>().add(const LogoutUser());
              Navigator.of(dialogContext).pop();
              // Navigate to login page
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/login', (route) => false);
            },
            child: const Text('Вийти', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
