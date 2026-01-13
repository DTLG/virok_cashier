import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../bloc/home_bloc.dart';
import '../../dialogs/open_shift_dialog.dart';
import '../../dialogs/close_shift_dialog.dart';
import '../../../../../core/widgets/notificarion_toast/toast_manager.dart';
import '../../../../../core/widgets/notificarion_toast/toast_type.dart';

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
      // При вході на сторінку перевіряємо стан зміни в Supabase
      context.read<HomeBloc>().add(const CheckTodayShiftPrompt());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeViewState>(
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Касова зміна',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    shiftOpen
                        ? 'Зміна відкрита о $openedAtStr'
                        : 'Зміна закрита. Відкрийте зміну, щоб проводити чеки.',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          color: Colors.white70,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Активний користувач: ',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        Text(
                          state.user?.name ?? state.user?.email ?? 'Невідомо',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

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
                      ],
                    ),
                  ],
                  const SizedBox(height: 32),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 16),
                  _primaryButton(
                    context,
                    label: 'Вийти з акаунту',
                    color: Colors.grey.shade800,
                    icon: Icons.logout,
                    loading: loading,
                    onPressed: () => _showLogoutDialog(context),
                  ),
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
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Сума, грн',
              labelStyle: TextStyle(color: Colors.white70),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Скасувати'),
            ),
            ElevatedButton(
              onPressed: () {
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
