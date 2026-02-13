import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:get_it/get_it.dart';
import '../../bloc/home_bloc.dart';
import '../../dialogs/open_shift_dialog.dart';
import '../../dialogs/close_shift_dialog.dart';
import '../../../../../core/widgets/notificarion_toast/toast_manager.dart';
import '../../../../../core/widgets/notificarion_toast/toast_type.dart';
import '../../dialogs/x_report_dialog.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../home/data/datasources/shift_remote_data_source.dart';
import '../../../../../core/services/cashalot/com/cashalot_com_service.dart';

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
                  // Якщо зміна відкрита
                  // ═══════════════════════════════════════════════════════════
                  // СЕКЦІЯ: Управління зміною
                  // ═══════════════════════════════════════════════════════════
                  _buildButtonSection(
                    title: 'Управління зміною',
                    icon: Icons.access_time_rounded,
                    children: [
                      _primaryButton(
                        context,
                        label: shiftOpen ? 'Зміна відкрита' : 'Відкрити зміну',
                        color: shiftOpen ? Colors.grey : Colors.green,
                        icon: shiftOpen
                            ? Icons.check_circle
                            : Icons.play_arrow_rounded,
                        loading: loading,
                        onPressed: shiftOpen
                            ? () => _showShiftAlreadyOpenMessage(
                                context,
                                state.openedShiftAt!,
                              )
                            : () => showOpenShiftDialog(context),
                      ),
                      _primaryButton(
                        context,
                        label: 'Z-Звіт (Закрити зміну)',
                        color: shiftOpen ? Colors.redAccent : Colors.grey,
                        icon: Icons.stop_rounded,
                        loading: loading,
                        onPressed: shiftOpen
                            ? () => showCloseShiftDialog(context)
                            : () => _showShiftNotOpenMessage(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ═══════════════════════════════════════════════════════════
                  // СЕКЦІЯ: Касові операції
                  // ═══════════════════════════════════════════════════════════
                  _buildButtonSection(
                    title: 'Касові операції',
                    icon: Icons.account_balance_wallet_rounded,
                    children: [
                      _primaryButton(
                        context,
                        label: 'Службове внесення',
                        color: Colors.blue,
                        icon: Icons.add_circle_outline,
                        loading: loading,
                        onPressed: () => _showServiceDepositDialog(context),
                      ),
                      _primaryButton(
                        context,
                        label: 'Службова видача',
                        color: Colors.blue.shade700,
                        icon: Icons.remove_circle_outline,
                        loading: loading,
                        onPressed: () => _showServiceIssueDialog(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ═══════════════════════════════════════════════════════════
                  // СЕКЦІЯ: Звіти
                  // ═══════════════════════════════════════════════════════════
                  _buildButtonSection(
                    title: 'Звіти',
                    icon: Icons.analytics_outlined,
                    children: [
                      _primaryButton(
                        context,
                        label: 'X-Звіт',
                        color: Colors.teal,
                        icon: Icons.receipt_long,
                        loading: loading,
                        onPressed: () =>
                            context.read<HomeBloc>().add(const XReportEvent()),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ═══════════════════════════════════════════════════════════
                  // СЕКЦІЯ: ПРРО (фіскалізація)
                  // ═══════════════════════════════════════════════════════════
                  _buildButtonSection(
                    title: 'ПРРО (фіскалізація)',
                    icon: Icons.verified_outlined,
                    children: [
                      _primaryButton(
                        context,
                        label: 'Перевірити стан ПРРО',
                        color: Colors.orange,
                        icon: Icons.info_outline,
                        loading: loading,
                        onPressed: () => _showPrroStateDialog(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ═══════════════════════════════════════════════════════════
                  // СЕКЦІЯ: Сервісні функції (для розробників)
                  // ═══════════════════════════════════════════════════════════
                  // _buildButtonSection(
                  //   title: 'Сервісні функції',
                  //   icon: Icons.build_outlined,
                  //   isWarning: true,
                  //   children: [
                  //     _primaryButton(
                  //       context,
                  //       label: 'Очистити ПРРО (Синхронізація)',
                  //       color: Colors.grey.shade700,
                  //       icon: Icons.sync_problem,
                  //       loading: loading,
                  //       onPressed: () async {
                  //         final shiftDataSource = ShiftRemoteDataSource(
                  //           Supabase.instance.client,
                  //         );
                  //         // 1. Беремо останню відкриту зміну користувача
                  //         final shift = await shiftDataSource
                  //             .getLastOpenedShift();
                  //         if (shift == null) {
                  //           throw Exception('Немає відкритої зміни');
                  //         }

                  //         final shiftId = shift['id'] as int;
                  //         final openingAmount =
                  //             (shift['opening_amount'] as num?)?.toDouble() ??
                  //             0.0;
                  //         final openedAt = DateTime.parse(
                  //           shift['opened_at'] as String,
                  //         );

                  //         // 2. Беремо суми по формі оплати (групування)
                  //         final salesData = await shiftDataSource
                  //             .getShiftSalesData(openedAt);
                  //         final salesCash = salesData['cash'] ?? 0.0;
                  //         final salesCashless = salesData['cashless'] ?? 0.0;

                  //         await shiftDataSource.closeShift(
                  //           shiftId: shiftId,
                  //           closingAmount: openingAmount,
                  //           salesAmountCash: salesCash,
                  //           salesAmountCashless: salesCashless,
                  //         );
                  //         context.read<HomeBloc>().add(
                  //           const CleanupCashalotEvent(),
                  //         );
                  //       },
                  //     ),
                  //   ],
                  // ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildButtonSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    bool isWarning = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isWarning
            ? Colors.orange.withOpacity(0.05)
            : Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWarning
              ? Colors.orange.withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: isWarning ? Colors.orange : Colors.white70,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: isWarning ? Colors.orange : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (isWarning) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Обережно',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 12, runSpacing: 12, children: children),
        ],
      ),
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

  void _showShiftAlreadyOpenMessage(BuildContext context, DateTime openedAt) {
    final formattedTime = DateFormat('HH:mm').format(openedAt);
    final formattedDate = DateFormat('dd.MM.yyyy').format(openedAt);

    ToastManager.show(
      context,
      type: ToastType.warning,
      title: 'Зміна вже відкрита',
      message: 'Зміна була відкрита $formattedDate о $formattedTime',
    );
  }

  void _showShiftNotOpenMessage(BuildContext context) {
    ToastManager.show(
      context,
      type: ToastType.warning,
      title: 'Зміна не відкрита',
      message: 'Спочатку відкрийте зміну',
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

  Future<void> _showPrroStateDialog(BuildContext context) async {
    // Показуємо діалог із завантаженням
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        backgroundColor: Color(0xFF2A2A2A),
        content: SizedBox(
          height: 100,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 16),
                Text(
                  'Перевірка стану ПРРО...',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final cashalotService = GetIt.instance<CashalotComService>();
      // Використовуємо фіскальний номер ПРРО (можна отримати з налаштувань)
      const prroFiscalNum = 4000944684; // TODO: отримати з налаштувань

      final response = await cashalotService.getPrroState(
        prroFiscalNum: prroFiscalNum,
      );

      // Закриваємо діалог завантаження
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Показуємо результат
      if (context.mounted) {
        if (response.errorCode != null) {
          // Помилка
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF2A2A2A),
              title: const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Помилка ПРРО', style: TextStyle(color: Colors.white)),
                ],
              ),
              content: Text(
                response.errorMessage ?? 'Невідома помилка',
                style: const TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Закрити'),
                ),
              ],
            ),
          );
        } else {
          // Успіх - показуємо дані
          final data = response.data;

          // Визначаємо статус зміни
          final shiftState = data?['ShiftState'];
          final shiftStateStr =
              data?['ShiftStateStr']?.toString() ?? 'Невідомо';
          final isShiftOpen =
              shiftState == 2 || shiftStateStr.toLowerCase() == 'opened';

          // Форматування дати
          String formatDateTime(String? dateStr) {
            if (dateStr == null ||
                dateStr.isEmpty ||
                dateStr.startsWith('0001')) {
              return '-';
            }
            try {
              final date = DateTime.parse(dateStr);
              return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
            } catch (e) {
              return dateStr;
            }
          }

          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF2A2A2A),
              title: Row(
                children: [
                  Icon(
                    isShiftOpen ? Icons.lock_open : Icons.lock_outline,
                    color: isShiftOpen ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Стан ПРРО: ${isShiftOpen ? "Зміна відкрита" : "Зміна закрита"}',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (data != null) ...[
                        // Секція: Інформація про бізнес
                        _buildSectionHeader('Інформація про точку продажу'),
                        _buildStateRow(
                          'Назва',
                          data['BusinesUnitName']?.toString() ?? '-',
                        ),
                        _buildStateRow(
                          'Адреса',
                          data['BusinesUnitAddress']?.toString() ?? '-',
                        ),
                        const SizedBox(height: 12),

                        // Секція: Стан зміни
                        _buildSectionHeader('Стан зміни'),
                        _buildStateRow(
                          'Статус',
                          '$shiftStateStr (${shiftState ?? "-"})',
                        ),
                        _buildStateRow(
                          'Локальний номер зміни',
                          data['ShiftLocalNumber']?.toString() ?? '-',
                        ),
                        _buildStateRow(
                          'Фіскальний номер зміни',
                          data['ShiftFiscalNumber']?.toString() ?? '-',
                        ),
                        _buildStateRow(
                          'ID зміни',
                          data['ShiftID']?.toString() ?? '-',
                        ),
                        _buildStateRow(
                          'Відкрита',
                          formatDateTime(data['ShiftDateBeg']?.toString()),
                        ),
                        if (!isShiftOpen)
                          _buildStateRow(
                            'Закрита',
                            formatDateTime(data['ShiftDateEnd']?.toString()),
                          ),
                        const SizedBox(height: 12),

                        // Секція: Останній чек
                        _buildSectionHeader('Останній чек'),
                        _buildStateRow(
                          'Локальний номер',
                          data['LastCheckLocalNumber']?.toString() ?? '-',
                        ),
                        _buildStateRow(
                          'Фіскальний номер',
                          data['LastCheckFiscalNumber']?.toString() ?? '-',
                        ),
                        _buildStateRow(
                          'Дата/час',
                          formatDateTime(data['LastCheckDateTime']?.toString()),
                        ),
                        _buildStateRow(
                          'Наступний номер',
                          data['NextLocalNumber']?.toString() ?? '-',
                        ),
                        const SizedBox(height: 12),

                        // Секція: Фінанси та режим
                        _buildSectionHeader('Фінанси та режим роботи'),
                        _buildStateRowHighlight(
                          'Залишок готівки',
                          '${data['CashBalance']?.toString() ?? "0"} грн',
                          Colors.greenAccent,
                        ),
                        _buildStateRow(
                          'Режим роботи',
                          data['IsOfflineMode'] == "0"
                              ? '🟢 Онлайн'
                              : '🔴 Офлайн',
                          //                               Стан офлайн-режиму каси: 0 – каса в онлайн-режимі,
                          //                                 1 – каса в офлайн-режимі,
                        ),
                        const SizedBox(height: 12),

                        // Секція: Ліцензії
                        _buildSectionHeader('Терміни дії'),
                        _buildStateRow(
                          'Ліцензія до',
                          formatDateTime(data['LicEndDate']?.toString()),
                        ),
                        _buildStateRow(
                          'Сертифікат до',
                          formatDateTime(data['CertEndDate']?.toString()),
                        ),
                      ] else
                        const Text(
                          'Дані не отримано',
                          style: TextStyle(color: Colors.white70),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Закрити'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      // Закриваємо діалог завантаження
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Показуємо помилку
      if (context.mounted) {
        ToastManager.show(
          context,
          type: ToastType.error,
          title: 'Помилка перевірки ПРРО',
          message: e.toString(),
        );
      }
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(color: Colors.white24, height: 8),
        ],
      ),
    );
  }

  Widget _buildStateRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              '$label:',
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStateRowHighlight(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              '$label:',
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
