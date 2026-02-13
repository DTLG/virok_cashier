import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../../../../core/models/cashalot_models.dart';
import '../../../../../core/widgets/notificarion_toast/view.dart';
import '../../../../../features/nomenclatura/domain/entities/nomenclatura.dart';
import '../../../../../features/nomenclatura/domain/usecases/search_nomenclatura.dart';
import '../../bloc/home_bloc.dart';

class ReturnsPage extends StatefulWidget {
  const ReturnsPage({super.key});

  @override
  State<ReturnsPage> createState() => _ReturnsPageState();
}

class _ReturnsPageState extends State<ReturnsPage> {
  static const int _maxSearchResults = 10; // Обмеження кількості результатів

  final _formKey = GlobalKey<FormState>();
  final _fiscalNumberController = TextEditingController();
  final _rrnController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _productNameController = TextEditingController();
  final _productCodeController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _priceController = TextEditingController();

  bool _isCardReturn = false;
  bool _isSearching = false;
  bool _showSearchResults = false;
  List<Nomenclatura> _searchResults = [];
  List<ReturnItem> _returnItems = [];

  @override
  void dispose() {
    _fiscalNumberController.dispose();
    _rrnController.dispose();
    _barcodeController.dispose();
    _productNameController.dispose();
    _productCodeController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _showSearchResults = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final searchNomenclatura = GetIt.instance<SearchNomenclatura>();
      final result = await searchNomenclatura(query.trim().toLowerCase());

      result.fold(
        (failure) {
          setState(() {
            _searchResults = [];
            _showSearchResults = false;
          });
        },
        (nomenclaturas) {
          setState(() {
            // Обмежуємо кількість результатів
            _searchResults = nomenclaturas.take(_maxSearchResults).toList();
            _showSearchResults = _searchResults.isNotEmpty;
          });
        },
      );
    } catch (e) {
      setState(() {
        _searchResults = [];
        _showSearchResults = false;
      });
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  void _onSearchChanged(String value) {
    // Дебаунс для уникнення занадто частих запитів
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_barcodeController.text == value) {
        _performSearch(value);
      }
    });
  }

  void _selectProduct(Nomenclatura product) {
    setState(() {
      _productNameController.text = product.name;
      _productCodeController.text = product.article.isNotEmpty
          ? product.article
          : product.guid;
      _priceController.text = product.prices.toStringAsFixed(2);
      _barcodeController.clear();
      _searchResults = [];
      _showSearchResults = false;
    });

    ToastManager.show(
      context,
      type: ToastType.success,
      title: 'Товар вибрано',
      message: product.name,
    );
  }

  void _clearSearch() {
    setState(() {
      _barcodeController.clear();
      _searchResults = [];
      _showSearchResults = false;
    });
  }

  void _addItem() {
    if (_productNameController.text.isEmpty || _priceController.text.isEmpty) {
      ToastManager.show(
        context,
        type: ToastType.warning,
        title: 'Заповніть дані товару',
        message: 'Введіть назву та ціну товару',
      );
      return;
    }

    final price = double.tryParse(_priceController.text.replaceAll(',', '.'));
    final quantity = int.tryParse(_quantityController.text) ?? 1;

    if (price == null || price <= 0) {
      ToastManager.show(
        context,
        type: ToastType.warning,
        title: 'Невірна ціна',
        message: 'Введіть коректну ціну товару',
      );
      return;
    }

    setState(() {
      _returnItems.add(
        ReturnItem(
          name: _productNameController.text,
          code: _productCodeController.text.isNotEmpty
              ? _productCodeController.text
              : 'ITEM_${_returnItems.length + 1}',
          quantity: quantity,
          price: price,
        ),
      );
      _productNameController.clear();
      _productCodeController.clear();
      _quantityController.text = '1';
      _priceController.clear();
    });
  }

  void _removeItem(int index) {
    setState(() {
      _returnItems.removeAt(index);
    });
  }

  double get _totalSum =>
      _returnItems.fold(0.0, (sum, item) => sum + (item.price * item.quantity));

  void _submitReturn() {
    if (_fiscalNumberController.text.isEmpty) {
      ToastManager.show(
        context,
        type: ToastType.warning,
        title: 'Введіть фіскальний номер',
        message: 'Потрібен фіскальний номер оригінального чека',
      );
      return;
    }

    if (_returnItems.isEmpty) {
      ToastManager.show(
        context,
        type: ToastType.warning,
        title: 'Додайте товари',
        message: 'Додайте хоча б один товар для повернення',
      );
      return;
    }

    if (_isCardReturn && _rrnController.text.isEmpty) {
      ToastManager.show(
        context,
        type: ToastType.warning,
        title: 'Введіть RRN',
        message:
            'Для повернення на картку потрібен RRN оригінальної транзакції',
      );
      return;
    }

    // Формуємо CheckPayload
    final checkBody = _returnItems
        .map(
          (item) => CheckBodyRow(
            code: item.code,
            name: item.name,
            amount: item.quantity.toDouble(),
            price: item.price,
          ),
        )
        .toList();

    final checkPayload = CheckPayload(
      checkHead: CheckHead(
        docType: "ReturnGoods",
        docSubType: "CheckGoods",
        cashier: "Касир", // Буде замінено в блоці
      ),
      checkTotal: CheckTotal(sum: _totalSum),
      checkBody: checkBody,
      checkPay: [
        CheckPayRow(
          payFormNm: _isCardReturn ? "КАРТКА" : "ГОТІВКА",
          sum: _totalSum,
        ),
      ],
    );

    // Відправляємо подію
    context.read<HomeBloc>().add(
      ReturnCheckEvent(
        checkPayload: checkPayload,
        totalSum: _totalSum,
        originalFiscalNumber: _fiscalNumberController.text,
        isCardReturn: _isCardReturn,
        originalRrn: _isCardReturn ? _rrnController.text : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<HomeBloc, HomeViewState>(
          listenWhen: (prev, curr) =>
              prev.status != curr.status &&
              (curr.status == HomeStatus.returnSuccess ||
                  curr.status == HomeStatus.returnError ||
                  curr.status == HomeStatus.returnLoading),
          listener: (context, state) {
            if (state.status == HomeStatus.returnSuccess) {
              ToastManager.show(
                context,
                type: ToastType.success,
                title: 'Повернення успішне',
                message: 'Чек повернення фіскалізовано',
                duration: const Duration(seconds: 4),
              );
              // Очищаємо форму
              setState(() {
                _returnItems.clear();
                _fiscalNumberController.clear();
                _rrnController.clear();
                _isCardReturn = false;
              });
              // Повертаємо статус
              context.read<HomeBloc>().add(const CheckUserLoginStatus());
            } else if (state.status == HomeStatus.returnError) {
              ToastManager.show(
                context,
                type: ToastType.error,
                title: 'Помилка повернення',
                message: state.errorMessage,
              );
              context.read<HomeBloc>().add(const CheckUserLoginStatus());
            }
          },
        ),
        BlocListener<HomeBloc, HomeViewState>(
          listenWhen: (prev, curr) {
            final shouldListen =
                prev.status != curr.status &&
                curr.status == HomeStatus.kkmSearchSuccess;

            debugPrint(
              '🔎 [RETURNS_LISTENER] listenWhen: prev.status=${prev.status}, '
              'curr.status=${curr.status}, shouldListen=$shouldListen',
            );

            return shouldListen;
          },
          listener: (context, state) {
            final paymentForm = state.kkmPaymentForm;
            final items = state.kkmItems;

            debugPrint(
              '🔁 [RETURNS_LISTENER] status=${state.status}, '
              'kkmItems=${items.length}, '
              'paymentForm=$paymentForm, '
              'RRN=${state.kkmRrn}',
            );

            if (paymentForm == null && items.isEmpty) {
              debugPrint(
                '🔁 [RETURNS_LISTENER] Пропуск: немає paymentForm і items.isEmpty',
              );
              return;
            }

            setState(() {
              // Тип оплати + RRN
              if (paymentForm != null) {
                final isCard = paymentForm.toLowerCase().contains('карт');
                _isCardReturn = isCard;
                if (isCard && state.kkmRrn != null) {
                  _rrnController.text = state.kkmRrn!;
                }
              }

              // Заповнюємо товари з kkm_check_items
              if (items.isNotEmpty) {
                debugPrint(
                  '🔁 [RETURNS_LISTENER] Заповнення _returnItems з ${items.length} позицій',
                );
                _returnItems
                  ..clear()
                  ..addAll(
                    items.map((row) {
                      final name = (row['product_name'] as String?) ?? '';
                      final code = (row['product_code'] as String?) ?? '';
                      final qty = (row['quantity'] as num?)?.toInt() ?? 1;
                      final price = (row['price'] as num?)?.toDouble() ?? 0.0;

                      debugPrint(
                        '   ▶ item name="$name", code="$code", qty=$qty, price=$price',
                      );

                      return ReturnItem(
                        name: name,
                        code: code,
                        quantity: qty,
                        price: price,
                      );
                    }),
                  );
                debugPrint(
                  '🔁 [RETURNS_LISTENER] Після заповнення _returnItems.length=${_returnItems.length}',
                );
              } else {
                debugPrint(
                  '🔁 [RETURNS_LISTENER] items.isEmpty, _returnItems не змінюємо',
                );
              }
            });

            ToastManager.show(
              context,
              type: ToastType.info,
              title: 'Дані чека завантажено',
              message: paymentForm == null
                  ? 'Товари чека додано'
                  : (paymentForm.toLowerCase().contains('карт')
                        ? 'Тип оплати: Картка, товари чека додано'
                        : 'Тип оплати: Готівка, товари чека додано'),
            );

            // Опційно: повертаємо статус у "звичайний" режим логіну
            context.read<HomeBloc>().add(const CheckUserLoginStatus());
          },
        ),
      ],
      child: BlocBuilder<HomeBloc, HomeViewState>(
        builder: (context, state) {
          if (state.status == HomeStatus.kkmSearchSuccess) {
            _returnItems = state.kkmItems
                .map(
                  (item) => ReturnItem(
                    name: item['product_name'] as String,
                    code: item['product_code'] as String,
                    quantity: item['quantity'] as int,
                    price: item['price'] as double,
                  ),
                )
                .toList();
            if (state.kkmPaymentForm != null) {
              _isCardReturn = state.kkmPaymentForm!.toLowerCase().contains(
                'карт',
              );
            }
            if (state.kkmFiscalNumber != null) {
              _fiscalNumberController.text = state.kkmFiscalNumber!;
            }
            if (state.kkmRrn != null) {
              _rrnController.text = state.kkmRrn!;
            }
          }
          final isLoading = state.status == HomeStatus.returnLoading;

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ліва колонка - форма
                Expanded(flex: 2, child: _buildForm(isLoading)),
                const SizedBox(width: 24),
                // Права колонка - список товарів та підсумок
                Expanded(flex: 1, child: _buildItemsList(isLoading)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildForm(bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Повернення товару',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Фіскальний номер оригінального чека
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _fiscalNumberController,
                    label: 'Фіскальний номер оригінального чека *',
                    hint: 'Введіть фіскальний номер',
                    enabled: !isLoading,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          final value = _fiscalNumberController.text.trim();
                          if (value.isEmpty) {
                            ToastManager.show(
                              context,
                              type: ToastType.warning,
                              title: 'Введіть фіскальний номер',
                            );
                            return;
                          }
                          context.read<HomeBloc>().add(
                            GetKkmCheckEvent(fiscalNumber: value),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Знайти чек'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Перемикач типу повернення
            Row(
              children: [
                const Text(
                  'Повернення на картку:',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(width: 16),
                Switch(
                  value: _isCardReturn,
                  onChanged: isLoading
                      ? null
                      : (value) => setState(() => _isCardReturn = value),
                  activeColor: Colors.red,
                ),
              ],
            ),

            // RRN (якщо повернення на картку)
            if (_isCardReturn) ...[
              const SizedBox(height: 16),
              _buildTextField(
                controller: _rrnController,
                label: 'RRN оригінальної транзакції *',
                hint: 'Введіть RRN',
                enabled: !isLoading,
              ),
            ],

            const SizedBox(height: 32),
            const Divider(color: Colors.white30),
            const SizedBox(height: 16),

            const Text(
              'Додати товар',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            // Пошук по штрихкоду
            _buildBarcodeSearchField(isLoading),
            const SizedBox(height: 16),

            // Назва товару
            _buildTextField(
              controller: _productNameController,
              label: 'Назва товару',
              hint: 'Введіть назву',
              enabled: !isLoading,
            ),
            const SizedBox(height: 12),

            // Код товару
            _buildTextField(
              controller: _productCodeController,
              label: 'Артикул',
              hint: 'Введіть артикул',
              enabled: !isLoading,
            ),
            const SizedBox(height: 12),

            // Кількість та ціна в рядок
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _quantityController,
                    label: 'Кількість',
                    hint: '1',
                    keyboardType: TextInputType.number,
                    enabled: !isLoading,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: _buildTextField(
                    controller: _priceController,
                    label: 'Ціна (грн)',
                    hint: '0.00',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    enabled: !isLoading,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Кнопка додати товар
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : _addItem,
                icon: const Icon(Icons.add),
                label: const Text('Додати товар'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList(bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Товари до повернення',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // Список товарів
          Expanded(
            child: _returnItems.isEmpty
                ? const Center(
                    child: Text(
                      'Додайте товари для повернення',
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : ListView.builder(
                    itemCount: _returnItems.length,
                    itemBuilder: (context, index) {
                      final item = _returnItems[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3A3A3A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${item.quantity} x ${item.price.toStringAsFixed(2)} грн',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${(item.price * item.quantity).toStringAsFixed(2)} грн',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: isLoading
                                  ? null
                                  : () => _removeItem(index),
                              icon: const Icon(Icons.delete_outline),
                              color: Colors.red,
                              iconSize: 20,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          const Divider(color: Colors.white30),
          const SizedBox(height: 16),

          // Підсумок
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Сума повернення:',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              Text(
                '${_totalSum.toStringAsFixed(2)} грн',
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Кнопка повернення
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading || _returnItems.isEmpty
                  ? null
                  : _submitReturn,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                disabledBackgroundColor: Colors.red.withOpacity(0.3),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Оформити повернення',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          enabled: enabled,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF3A3A3A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBarcodeSearchField(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Пошук товару (штрихкод або назва)',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  TextField(
                    controller: _barcodeController,
                    enabled: !isLoading,
                    style: const TextStyle(color: Colors.white),
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Скануйте штрихкод або введіть назву',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF3A3A3A),
                      prefixIcon: _isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white54,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.qr_code_scanner,
                              color: Colors.white54,
                            ),
                      suffixIcon: _barcodeController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: Colors.white54,
                              ),
                              onPressed: _clearSearch,
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.blue),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                  // Випадаючий список з результатами
                  if (_showSearchResults && _searchResults.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      constraints: const BoxConstraints(maxHeight: 250),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3A3A3A),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final product = _searchResults[index];
                          return InkWell(
                            onTap: () => _selectProduct(product),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                border: index < _searchResults.length - 1
                                    ? const Border(
                                        bottom: BorderSide(
                                          color: Colors.white12,
                                        ),
                                      )
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          product.article.isNotEmpty
                                              ? 'Артикул: ${product.article}'
                                              : 'Код: ${product.guid.substring(0, 8)}...',
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${product.prices.toStringAsFixed(2)} грн',
                                    style: const TextStyle(
                                      color: Colors.greenAccent,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (_searchResults.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Знайдено: ${_searchResults.length}${_searchResults.length >= _maxSearchResults ? '+' : ''} результатів',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

/// Модель товару для повернення
class ReturnItem {
  final String name;
  final String code;
  final int quantity;
  final double price;

  ReturnItem({
    required this.name,
    required this.code,
    required this.quantity,
    required this.price,
  });
}
