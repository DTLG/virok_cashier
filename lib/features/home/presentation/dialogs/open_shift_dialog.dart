import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/widgets/notificarion_toast/toast_manager.dart';
import '../../../../core/widgets/notificarion_toast/toast_type.dart';
import '../../data/datasources/shift_remote_data_source.dart';
import '../bloc/home_bloc.dart';

Future<void> showOpenShiftDialog(BuildContext context) async {
  final amountController = TextEditingController(text: '0');
  bool isSubmitting = false;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          Future<void> onConfirm() async {
            if (isSubmitting) return;
            setState(() => isSubmitting = true);
            try {
              final raw = amountController.text.trim().replaceAll(',', '.');
              final openingAmount = double.tryParse(raw);
              if (openingAmount == null) {
                throw Exception('Введіть коректну суму');
              }

              // Зберігаємо зміну в Supabase
              final shiftDataSource = ShiftRemoteDataSource(
                Supabase.instance.client,
              );
              await shiftDataSource.openShift(openingAmount);

              // Фіскальне відкриття зміни через CashalotService
              if (context.mounted) {
                final homeBloc = context.read<HomeBloc>();
                homeBloc.add(const OpenCashalotShift());
              }

              if (context.mounted) Navigator.of(ctx).pop();
            } catch (e) {
              if (!context.mounted) return;
              ToastManager.show(
                context,
                type: ToastType.error,
                title: 'Помилка відкриття зміни: $e',
              );
            } finally {
              if (ctx.mounted) setState(() => isSubmitting = false);
            }
          }

          return Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 200,
              vertical: 80,
            ),
            backgroundColor: const Color(0xFF2A2A2A),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 500, maxWidth: 700),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Відкрити зміну',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Для початку роботи необхідно відкрити зміну і зафіксувати внесення коштів (від 0.00 грн).',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 20),

                    // Поле внесення коштів
                    const Text(
                      'Внесення коштів (грн)',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: const Color(0xFF3A3A3A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // if (cancelButtonVisible)
                        //   TextButton(
                        //     onPressed: isSubmitting
                        //         ? null
                        //         : () => Navigator.of(ctx).pop(),
                        //     child: const Text(
                        //       'Скасувати',
                        //       style: TextStyle(color: Colors.white70),
                        //     ),
                        //   ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: isSubmitting ? null : onConfirm,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Відкрити',
                                  style: TextStyle(color: Colors.white),
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
