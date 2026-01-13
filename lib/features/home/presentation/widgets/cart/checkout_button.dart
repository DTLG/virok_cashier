import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/home_bloc.dart';
import '../../../../../core/widgets/notificarion_toast/view.dart';

class CheckoutButton extends StatelessWidget {
  const CheckoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: BlocBuilder<HomeBloc, HomeViewState>(
            builder: (context, state) {
              final shiftOpen = state.openedShiftAt != null;
              return SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: shiftOpen
                      ? () => _processCheckout(context)
                      : () {
                          ToastManager.show(
                            context,
                            type: ToastType.error,
                            title: 'Спочатку відкрийте зміну',
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: shiftOpen
                        ? const Color(0xFF4A4A4A)
                        : Colors.grey,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Провести чек',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 10),

        Expanded(
          flex: 3,
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                _processPutOffCheck(context);
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: const Color(0xFF4A4A4A),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Відкласти',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _processPutOffCheck(BuildContext rootContext) {
    showDialog(
      context: rootContext,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: const Text(
            'Відкласти чек?',
            style: TextStyle(color: Colors.white),
          ),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Flexible(
                child: Text(
                  'Ви впевнені, що хочете відкласти чек? Ви зможете провести чек пізніше.',
                  textAlign: TextAlign.center,
                  softWrap: true,
                  maxLines: null,
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text(
                'Скасувати',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  // Використовуємо rootContext, який знаходиться під BlocProvider
                  rootContext.read<HomeBloc>().add(const PutOffCheckEvent());
                } catch (e) {
                  if (!rootContext.mounted) return;
                  ToastManager.show(
                    rootContext,
                    type: ToastType.error,
                    title: 'Помилка збереження чеку',
                    exception: e as Exception,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
              ),
              child: const Text(
                'Підтвердити',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        );
      },
    );
  }

  void _processCheckout(BuildContext rootContext) {
    showDialog(
      context: rootContext,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: const Text(
            'Підтвердження замовлення',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Ви впевнені, що хочете розмістити це замовлення?',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text(
                'Скасувати',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  // Використовуємо rootContext, який знаходиться під BlocProvider
                  rootContext.read<HomeBloc>().add(const CheckoutEvent());
                } catch (e) {
                  if (!rootContext.mounted) return;
                  ToastManager.show(
                    rootContext,
                    type: ToastType.error,
                    title: 'Помилка збереження чеку',
                    exception: e as Exception,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
              ),
              child: const Text(
                'Підтвердити',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        );
      },
    );
  }

  // збереження винесене у BLoC + data source
}
