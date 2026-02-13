import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/settings_bloc.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';
import '../widgets/theme_selector.dart';
import '../widgets/language_selector.dart';
import '../widgets/sync_settings.dart';
import '../widgets/about_section.dart';
import '../../../../core/widgets/notificarion_toast/view.dart';
import '../../../../core/config/cashalot_config.dart';
import '../../../home/presentation/bloc/home_bloc.dart';
import '../widgets/cashalot_keys_selector.dart';
import '../widgets/prro_selection_dialog.dart';
import '../../../../core/services/storage/storage_service.dart';
import '../../../../core/models/prro_info.dart';
// import 'package:get_it/get_it.dart';
// import '../../../../core/services/cashalot/cashalot_service.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Завантажуємо налаштування при першому відкритті сторінки
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        context.read<SettingsBloc>().add(const LoadSettings());
      } catch (e) {
        print('Error loading settings: $e');
      }
    });

    return const _SettingsPageView();
  }
}

class _SettingsPageView extends StatefulWidget {
  const _SettingsPageView();

  @override
  State<_SettingsPageView> createState() => _SettingsPageViewState();
}

class _SettingsPageViewState extends State<_SettingsPageView> {
  bool _isLoadingPrro = true;
  final TextEditingController _prroController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSelectedPrro();
  }

  @override
  void dispose() {
    _prroController.dispose();
    super.dispose();
  }

  Future<void> _loadSelectedPrro() async {
    final storageService = StorageService();
    final selectedPrroNum = await storageService.getCashalotSelectedPrro();

    final value = selectedPrroNum ?? CashalotConfig.defaultPrroFiscalNum;
    if (mounted) {
      setState(() {
        _prroController.text = value;
        _isLoadingPrro = false;
      });
    }
  }

  Future<void> _savePrro(String value) async {
    final storageService = StorageService();
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      await storageService.setCashalotSelectedPrro(null);
      ToastManager.show(
        context,
        type: ToastType.info,
        title: 'Активну касу очищено',
      );
    } else {
      await storageService.setCashalotSelectedPrro(trimmed);
      ToastManager.show(
        context,
        type: ToastType.success,
        title: 'Активну касу збережено',
        message: 'Фіскальний номер: $trimmed',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      // appBar: AppBar(
      //   backgroundColor: const Color(0xFF2A2A2A),
      //   foregroundColor: Colors.white,
      //   title: const Text(
      //     'Налаштування',
      //     style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      //   ),
      //   centerTitle: true,
      //   elevation: 0,
      // ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Загальні налаштування
                SettingsSection(
                  title: 'Загальні',
                  children: [
                    SettingsTile(
                      icon: Icons.palette_outlined,
                      title: 'Тема',
                      subtitle: state.themeMode == ThemeMode.system
                          ? 'Системна'
                          : state.themeMode == ThemeMode.light
                          ? 'Світла'
                          : 'Темна',
                      onTap: () => _showThemeSelector(context),
                    ),
                    SettingsTile(
                      icon: Icons.language_outlined,
                      title: 'Мова',
                      subtitle: state.language == 'uk'
                          ? 'Українська'
                          : 'English',
                      onTap: () => _showLanguageSelector(context),
                    ),
                    SettingsTile(
                      icon: Icons.notifications_outlined,
                      title: 'Сповіщення',
                      subtitle: state.notificationsEnabled
                          ? 'Увімкнено'
                          : 'Вимкнено',
                      trailing: Switch(
                        value: state.notificationsEnabled,
                        onChanged: (value) {
                          context.read<SettingsBloc>().add(
                            ToggleNotifications(value),
                          );
                        },
                        activeColor: Colors.red,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Налаштування синхронізації
                SettingsSection(
                  title: 'Синхронізація',
                  children: [
                    SettingsTile(
                      icon: Icons.sync_outlined,
                      title: 'Автоматична синхронізація',
                      subtitle: state.autoSyncEnabled
                          ? 'Увімкнено'
                          : 'Вимкнено',
                      trailing: Switch(
                        value: state.autoSyncEnabled,
                        onChanged: (value) {
                          context.read<SettingsBloc>().add(
                            ToggleAutoSync(value),
                          );
                        },
                        activeColor: Colors.red,
                      ),
                    ),
                    SettingsTile(
                      icon: Icons.schedule_outlined,
                      title: 'Інтервал синхронізації',
                      subtitle: '${state.syncIntervalMinutes} хвилин',
                      onTap: () => _showSyncIntervalSelector(context),
                    ),
                    SettingsTile(
                      icon: Icons.wifi_outlined,
                      title: 'Синхронізація тільки по Wi-Fi',
                      subtitle: state.wifiOnlySync ? 'Увімкнено' : 'Вимкнено',
                      trailing: Switch(
                        value: state.wifiOnlySync,
                        onChanged: (value) {
                          context.read<SettingsBloc>().add(
                            ToggleWifiOnlySync(value),
                          );
                        },
                        activeColor: Colors.red,
                      ),
                    ),
                    SettingsTile(
                      icon: Icons.sync,
                      title: 'Синхронізувати зараз',
                      subtitle:
                          'Остання синхронізація: ${_formatLastSync(state.lastSyncTime)}',
                      onTap: () {
                        context.read<SettingsBloc>().add(const SyncNow());
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Налаштування каси
                SettingsSection(
                  title: 'Каса',
                  children: [
                    SettingsTile(
                      icon: Icons.receipt_outlined,
                      title: 'Автоматичний друк чеків',
                      subtitle: state.autoPrintReceipts
                          ? 'Увімкнено'
                          : 'Вимкнено',
                      trailing: Switch(
                        value: state.autoPrintReceipts,
                        onChanged: (value) {
                          context.read<SettingsBloc>().add(
                            ToggleAutoPrintReceipts(value),
                          );
                        },
                        activeColor: Colors.red,
                      ),
                    ),
                    SettingsTile(
                      icon: Icons.print_outlined,
                      title: 'Принтер',
                      subtitle: state.printerIp != null
                          ? '${state.printerIp}:${state.printerPort}'
                          : 'Не налаштовано',
                      onTap: () => _showPrinterSettings(context),
                    ),
                    SettingsTile(
                      icon: Icons.money_outlined,
                      title: 'Валюта',
                      subtitle: state.currency,
                      onTap: () => _showCurrencySelector(context),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Безпека
                SettingsSection(
                  title: 'Безпека',
                  children: [
                    SettingsTile(
                      icon: Icons.lock_outline,
                      title: 'Блокування екрану',
                      subtitle: state.screenLockEnabled
                          ? 'Увімкнено'
                          : 'Вимкнено',
                      trailing: Switch(
                        value: state.screenLockEnabled,
                        onChanged: (value) {
                          context.read<SettingsBloc>().add(
                            ToggleScreenLock(value),
                          );
                        },
                        activeColor: Colors.red,
                      ),
                    ),
                    SettingsTile(
                      icon: Icons.timer_outlined,
                      title: 'Час блокування',
                      subtitle: '${state.screenLockTimeoutMinutes} хвилин',
                      onTap: () => _showScreenLockTimeoutSelector(context),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Налаштування Cashalot ключів
                SettingsSection(
                  title: 'Cashalot',
                  children: [
                    SettingsTile(
                      icon: Icons.store_outlined,
                      title: 'Активна каса (фіскальний номер ПРРО)',
                      subtitle: _isLoadingPrro
                          ? 'Завантаження...'
                          : 'Введіть номер каси, наприклад ${CashalotConfig.defaultPrroFiscalNum}',
                      trailing: SizedBox(
                        width: 180,
                        child: TextField(
                          controller: _prroController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'ФН ПРРО',
                            hintStyle: TextStyle(
                              color: Colors.white38,
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                          ),
                          onSubmitted: _savePrro,
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CashalotKeysSelector(),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Тестування Cashalot
                SettingsSection(
                  title: 'Тестування Cashalot',
                  children: [
                    SettingsTile(
                      icon: Icons.science_outlined,
                      title: 'Тестовий депозит',
                      subtitle: 'Перевірка з\'язку з API (1 грн)',
                      onTap: () => _testCashalotDeposit(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Про додаток
                SettingsSection(
                  title: 'Про додаток',
                  children: [
                    SettingsTile(
                      icon: Icons.info_outline,
                      title: 'Версія',
                      subtitle: state.appVersion,
                      // onTap: () => _showAboutDialog(context),
                    ),
                    SettingsTile(
                      icon: Icons.help_outline,
                      title: 'Допомога',
                      onTap: () => _showHelpDialog(context),
                    ),
                    SettingsTile(
                      icon: Icons.bug_report_outlined,
                      title: 'Повідомити про помилку',
                      onTap: () => _showBugReportDialog(context),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Очищення даних
                SettingsSection(
                  title: 'Дані',
                  children: [
                    SettingsTile(
                      icon: Icons.delete_outline,
                      title: 'Очистити кеш',
                      subtitle: 'Видалити тимчасові файли',
                      onTap: () => _showClearCacheDialog(context),
                    ),
                    SettingsTile(
                      icon: Icons.logout,
                      title: 'Вийти з акаунту',
                      onTap: () => _showLogoutDialog(context),
                    ),
                  ],
                ),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showThemeSelector(BuildContext context) {
    showDialog(context: context, builder: (context) => const ThemeSelector());
  }

  void _showLanguageSelector(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const LanguageSelector(),
    );
  }

  void _showSyncIntervalSelector(BuildContext context) {
    showDialog(context: context, builder: (context) => const SyncSettings());
  }

  void _showPrinterSettings(BuildContext context) {
    final state = context.read<SettingsBloc>().state;
    final ipController = TextEditingController(text: state.printerIp ?? '');
    final portController = TextEditingController(
      text: state.printerPort.toString(),
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Налаштування принтера',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: ipController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'IP-адреса принтера',
                labelStyle: const TextStyle(color: Colors.white70),
                hintText: '192.168.1.100',
                hintStyle: const TextStyle(color: Colors.white54),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.white30),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.white),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: portController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Порт',
                labelStyle: const TextStyle(color: Colors.white70),
                hintText: '9100',
                hintStyle: const TextStyle(color: Colors.white54),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.white30),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.white),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(
              'Скасувати',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final ip = ipController.text.trim();
              final portText = portController.text.trim();
              final port = int.tryParse(portText) ?? 9100;

              if (ip.isNotEmpty) {
                context.read<SettingsBloc>().add(
                  UpdatePrinterIp(printerIp: ip),
                );
              } else {
                context.read<SettingsBloc>().add(
                  const UpdatePrinterIp(printerIp: null),
                );
              }
              context.read<SettingsBloc>().add(
                UpdatePrinterPort(printerPort: port),
              );

              Navigator.of(dialogContext).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text(
              'Зберегти',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showCurrencySelector(BuildContext context) {
    // TODO: Implement currency selector
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Вибір валюти в розробці')));
  }

  void _showScreenLockTimeoutSelector(BuildContext context) {
    // TODO: Implement screen lock timeout selector
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Налаштування блокування в розробці')),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const AboutSection());
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('Допомога', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Для отримання допомоги зверніться до служби підтримки:\n\n'
          'Email: support@virok.com\n'
          'Телефон: +380 44 123 45 67',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрити', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showBugReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Повідомити про помилку',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Для повідомлення про помилку:\n\n'
          '1. Опишіть проблему детально\n'
          '2. Вкажіть кроки для відтворення\n'
          '3. Додайте скріншоти якщо можливо\n\n'
          'Email: bugs@virok.com',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрити', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Очистити кеш',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Ви впевнені, що хочете очистити кеш? Це видалить всі тимчасові файли та дані.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Скасувати',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              context.read<SettingsBloc>().add(const ClearCache());
              Navigator.of(context).pop();
              ToastManager.show(
                context,
                type: ToastType.success,
                title: 'Кеш очищено',
              );
            },
            child: const Text('Очистити', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _testCashalotDeposit(BuildContext context) {
    // Перевіряємо чи HomeBloc доступний
    try {
      final homeBloc = context.read<HomeBloc>();
      final prroFiscalNum = int.parse(CashalotConfig.defaultPrroFiscalNum);

      // Показуємо діалог підтвердження
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: const Text(
            'Тестовий депозит',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Виконати тестовий депозит на 1 гривню для перевірки з\'язку з Cashalot API?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Скасувати',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Викликаємо тестовий депозит через публічний метод
                homeBloc.testDeposit(
                  prroFiscalNum: prroFiscalNum,
                  cashier: 'Тест Адмін',
                );
                // Показуємо повідомлення про початок тесту
                ToastManager.show(
                  context,
                  type: ToastType.info,
                  title: 'Тест запущено',
                  message: 'Перевірка з\'язку з API...',
                );
              },
              child: const Text(
                'Підтвердити',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      // Якщо HomeBloc недоступний, показуємо помилку
      ToastManager.show(
        context,
        type: ToastType.error,
        title: 'Помилка',
        message: 'HomeBloc недоступний: $e',
      );
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Скасувати',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              context.read<SettingsBloc>().add(const Logout());
              Navigator.of(context).pop();
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

  String _formatLastSync(DateTime? lastSync) {
    if (lastSync == null) return 'Ніколи';

    final now = DateTime.now();
    final difference = now.difference(lastSync);

    if (difference.inMinutes < 1) {
      return 'Щойно';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} хв тому';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} год тому';
    } else {
      return '${difference.inDays} дн тому';
    }
  }
}
