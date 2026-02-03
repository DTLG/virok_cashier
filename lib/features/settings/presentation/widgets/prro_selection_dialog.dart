import 'package:flutter/material.dart';
import '../../../../core/models/prro_info.dart';
// import '../../../../core/services/cashalot_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/widgets/notificarion_toast/view.dart';
// import 'package:get_it/get_it.dart';

/// Діалог для вибору активної каси (ПРРО)
/// Для Vchasno не потрібно отримувати список ПРРО з API
class PrroSelectionDialog extends StatefulWidget {
  final List<PrroInfo> prroInfo;
  const PrroSelectionDialog({super.key, required this.prroInfo});

  @override
  State<PrroSelectionDialog> createState() => _PrroSelectionDialogState();
}

class _PrroSelectionDialogState extends State<PrroSelectionDialog> {
  // final CashalotService _cashalotService = GetIt.instance<CashalotService>();
  final StorageService _storageService = StorageService();
  List<PrroInfo> _prros = [];
  PrroInfo? _selectedPrro;
  String? _savedPrroNum;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPrros();
    _loadSavedPrro();
  }

  Future<void> _loadPrros() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_savedPrroNum != null) {
        _prros = [
          PrroInfo(numFiscal: _savedPrroNum!, name: 'Каса ${_savedPrroNum!}'),
        ];
        _selectedPrro = _prros.first;
      } else {
        // Якщо немає збереженої каси, створюємо дефолтну
        _prros = [PrroInfo(numFiscal: '4000365576', name: 'Каса 1')];
        _selectedPrro = _prros.first;
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ToastManager.show(
          context,
          type: ToastType.error,
          title: 'Помилка',
          message: 'Не вдалося завантажити список кас: $e',
        );
      }
    }
  }

  Future<void> _loadSavedPrro() async {
    final saved = await _storageService.getCashalotSelectedPrro();
    setState(() {
      _savedPrroNum = saved;
    });
  }

  Future<void> _saveSelection() async {
    if (_selectedPrro == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await _storageService.setCashalotSelectedPrro(_selectedPrro!.numFiscal);
      if (mounted) {
        ToastManager.show(
          context,
          type: ToastType.success,
          title: 'Каса вибрана',
          message: 'Активна каса: ${_selectedPrro!.name}',
        );
        Navigator.of(context).pop(_selectedPrro);
      }
    } catch (e) {
      if (mounted) {
        ToastManager.show(
          context,
          type: ToastType.error,
          title: 'Помилка',
          message: 'Не вдалося зберегти вибір: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2A2A2A),
      title: const Text(
        'Вибір активної каси',
        style: TextStyle(color: Colors.white),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _prros.isEmpty
            ? const Text(
                'Доступні каси не знайдено',
                style: TextStyle(color: Colors.white70),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _prros.map((prro) {
                    final isSelected =
                        _selectedPrro?.numFiscal == prro.numFiscal;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedPrro = prro;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.red.withOpacity(0.2)
                              : const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? Colors.red : Colors.white30,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              color: isSelected ? Colors.red : Colors.white70,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    prro.name,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.white70,
                                      fontSize: 16,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'ФН: ${prro.numFiscal}',
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (prro.address != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      prro.address!,
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text(
            'Скасувати',
            style: TextStyle(color: Colors.white70),
          ),
        ),
        TextButton(
          onPressed: _isSaving || _selectedPrro == null ? null : _saveSelection,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Зберегти', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}
