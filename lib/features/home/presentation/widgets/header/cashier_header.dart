import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/home_bloc.dart';
import '../../dialogs/close_shift_dialog.dart';
import '../../../../../core/widgets/notificarion_toast/view.dart';

class CashierHeader extends StatelessWidget {
  const CashierHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Каса',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Builder(
            builder: (context) {
              final adminLogin = context.select(
                (HomeBloc b) => b.state.user?.email ?? '',
              );
              return Text(
                adminLogin,
                style: const TextStyle(color: Colors.white),
              );
            },
          ),

          // TextButton(
          //   onPressed: () async {
          //     final api = CashalotApiClient(
          //       baseUrl: 'https://fsapi.cashalot.org.ua',
          //     );
          //     try {
          //       final res = await api.openShift();
          //       _showSnack(context, 'Зміна відкрита: ${res['id'] ?? 'ok'}');
          //     } catch (e) {
          //       _showSnack(context, 'Помилка відкриття зміни: $e', error: true);
          //     }
          //   },
          //   child: const Text('Відкрити зміну'),
          // ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () async {
              await showCloseShiftDialog(context, cancelButtonVisible: true);
            },
            style: TextButton.styleFrom(
              // backgroundColor: Colors.redAccent,
              foregroundColor: Colors.redAccent,
            ),
            child: const Text('Закрити зміну'),
          ),
        ],
      ),
    );
  }

  void _showSnack(BuildContext context, String msg, {bool error = false}) {
    ToastManager.show(
      context,
      type: ToastType.error,
      title: 'Помилка закриття зміни',
      exception: Exception(msg),
    );
  }
}
