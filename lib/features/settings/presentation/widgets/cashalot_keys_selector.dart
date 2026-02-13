import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/services/storage/storage_service.dart';
import '../../../../core/widgets/notificarion_toast/view.dart';

/// Віджет для вибору файлів ключів Cashalot через системний провідник
class CashalotKeysSelector extends StatefulWidget {
  const CashalotKeysSelector({super.key});

  @override
  State<CashalotKeysSelector> createState() => _CashalotKeysSelectorState();
}

class _CashalotKeysSelectorState extends State<CashalotKeysSelector> {
  final StorageService _storageService = StorageService();
  String? _cashalotFolderPath;
  String? _keyPath;
  String? _certPath;
  String? _keyPassword;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedPaths();
  }

  Future<void> _loadSavedPaths() async {
    setState(() {
      _isLoading = true;
    });

    final cashalotFolderPath = await _storageService.getCashalotFolderPath();
    final keyPath = await _storageService.getCashalotKeyPath();
    final certPath = await _storageService.getCashalotCertPath();
    final password = await _storageService.getCashalotKeyPassword();

    setState(() {
      _cashalotFolderPath = cashalotFolderPath;
      _keyPath = keyPath;
      _certPath = certPath;
      _keyPassword = password;
      _isLoading = false;
    });
  }

  Future<void> _pickCashalotFolder() async {
    try {
      final result = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Виберіть папку Cashalot',
      );

      if (result != null) {
        await _storageService.setCashalotFolderPath(result);
        setState(() {
          _cashalotFolderPath = result;
        });
        if (mounted) {
          ToastManager.show(
            context,
            type: ToastType.success,
            title: 'Папку вибрано',
            message: 'Перезапустіть додаток для застосування змін',
            duration: const Duration(seconds: 4),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ToastManager.show(
          context,
          type: ToastType.error,
          title: 'Помилка',
          message: 'Не вдалося вибрати папку: $e',
        );
      }
    }
  }

  Future<void> _pickKeyFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        // Дозволяємо стандартні формати ключів + новий формат .ZS2
        allowedExtensions: ['dat', 'jks', 'key', 'pem', 'zs2', 'ZS2'],
        dialogTitle: 'Виберіть файл приватного ключа',
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        await _storageService.setCashalotKeyPath(path);
        setState(() {
          _keyPath = path;
        });
        if (mounted) {
          ToastManager.show(
            context,
            type: ToastType.success,
            title: 'Ключ вибрано',
            message: 'Перезапустіть додаток для застосування змін',
            duration: const Duration(seconds: 4),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ToastManager.show(
          context,
          type: ToastType.error,
          title: 'Помилка',
          message: 'Не вдалося вибрати файл: $e',
        );
      }
    }
  }

  Future<void> _pickCertFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['crt', 'cer', 'pem'],
        dialogTitle: 'Виберіть файл сертифіката',
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        await _storageService.setCashalotCertPath(path);
        setState(() {
          _certPath = path;
        });
        if (mounted) {
          ToastManager.show(
            context,
            type: ToastType.success,
            title: 'Сертифікат вибрано',
            message: 'Перезапустіть додаток для застосування змін',
            duration: const Duration(seconds: 4),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ToastManager.show(
          context,
          type: ToastType.error,
          title: 'Помилка',
          message: 'Не вдалося вибрати файл: $e',
        );
      }
    }
  }

  Future<void> _setPassword() async {
    final passwordController = TextEditingController(text: _keyPassword);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Пароль від ключа',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Пароль',
            labelStyle: TextStyle(color: Colors.white70),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white30),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.red),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Скасувати',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(passwordController.text),
            child: const Text('Зберегти', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (result != null) {
      await _storageService.setCashalotKeyPassword(result);
      setState(() {
        _keyPassword = result;
      });
      if (mounted) {
        ToastManager.show(
          context,
          type: ToastType.success,
          title: 'Пароль збережено',
          message: 'Перезапустіть додаток для застосування змін',
          duration: const Duration(seconds: 4),
        );
      }
    }
  }

  String _getFileName(String path) {
    final parts = path.split(Platform.pathSeparator);
    return parts.isNotEmpty ? parts.last : path;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Файли ключів Cashalot',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        _buildFolderSelector(
          label: 'Шлях до Cashalot',
          path: _cashalotFolderPath,
          onTap: _pickCashalotFolder,
          icon: Icons.folder_outlined,
        ),
        const SizedBox(height: 16),
        _buildFileSelector(
          label: 'Приватний ключ',
          path: _keyPath,
          onTap: _pickKeyFile,
          icon: Icons.vpn_key_outlined,
        ),
        const SizedBox(height: 12),
        _buildFileSelector(
          label: 'Сертифікат',
          path: _certPath,
          onTap: _pickCertFile,
          icon: Icons.verified_outlined,
        ),
        const SizedBox(height: 12),
        _buildPasswordSelector(),
        const SizedBox(height: 16),
        if (_cashalotFolderPath != null || _keyPath != null || _certPath != null)
          TextButton(
            onPressed: () async {
              await _storageService.setCashalotFolderPath(null);
              await _storageService.setCashalotKeyPath(null);
              await _storageService.setCashalotCertPath(null);
              await _storageService.setCashalotKeyPassword(null);
              setState(() {
                _cashalotFolderPath = null;
                _keyPath = null;
                _certPath = null;
                _keyPassword = null;
              });
              if (mounted) {
                ToastManager.show(
                  context,
                  type: ToastType.info,
                  title: 'Налаштування скинуто',
                  message: 'Буде використано конфігурацію з файлу',
                );
              }
            },
            child: const Text(
              'Скинути до значень за замовчуванням',
              style: TextStyle(color: Colors.red),
            ),
          ),
      ],
    );
  }

  Widget _buildFileSelector({
    required String label,
    required String? path,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: path != null ? Colors.green : Colors.white30,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: path != null ? Colors.green : Colors.white70),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: path != null ? Colors.white : Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (path != null)
                    Text(
                      _getFileName(path),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    const Text(
                      'Не вибрано',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderSelector({
    required String label,
    required String? path,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: path != null ? Colors.green : Colors.white30,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: path != null ? Colors.green : Colors.white70),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: path != null ? Colors.white : Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (path != null)
                    Text(
                      path,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    const Text(
                      'Не вибрано',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordSelector() {
    return InkWell(
      onTap: _setPassword,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _keyPassword != null ? Colors.green : Colors.white30,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.lock_outline,
              color: _keyPassword != null ? Colors.green : Colors.white70,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Пароль від ключа',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _keyPassword != null
                        ? '•' * _keyPassword!.length
                        : 'Не встановлено',
                    style: TextStyle(
                      color: _keyPassword != null
                          ? Colors.white70
                          : Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}
