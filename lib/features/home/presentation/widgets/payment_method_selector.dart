import 'package:flutter/material.dart';
import '../../../../core/widgets/symbol_icon.dart';

class PaymentMethodSelector extends StatefulWidget {
  const PaymentMethodSelector({super.key});

  @override
  State<PaymentMethodSelector> createState() => _PaymentMethodSelectorState();
}

class _PaymentMethodSelectorState extends State<PaymentMethodSelector> {
  int _selectedMethod = 0; // Cash вибрано за замовчуванням

  final List<PaymentMethod> _paymentMethods = [
    PaymentMethod(
      name: 'Готівка',
      icon: Icons.attach_money, // Залишаємо для інших методів
      symbol: '₴', // Додаємо символ гривні
      useSymbol: true, // Показуємо що використовуємо символ
    ),
    PaymentMethod(
      name: 'Картка',
      icon: Icons.credit_card,
      symbol: null,
      useSymbol: false,
    ),
    PaymentMethod(
      name: 'Е-гаманець',
      icon: Icons.account_balance_wallet,
      symbol: null,
      useSymbol: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Спосіб оплати',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: _paymentMethods.asMap().entries.map((entry) {
            final index = entry.key;
            final method = entry.value;
            final isSelected = index == _selectedMethod;

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedMethod = index;
                  });
                },
                child: Container(
                  height: 70,
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF4A4A4A)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.grey,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      if (method.useSymbol && method.symbol != null)
                        // Використовуємо SymbolIcon
                        SymbolIcon(
                          symbol: method.symbol!,
                          color: isSelected ? Colors.white : Colors.grey,
                          size: 20,
                        )
                      else
                        // Використовуємо звичайну іконку
                        Icon(
                          method.icon,
                          color: isSelected ? Colors.white : Colors.grey,
                          size: 20,
                        ),
                      const SizedBox(height: 4),
                      Text(
                        method.name,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class PaymentMethod {
  final String name;
  final IconData icon;
  final String? symbol; // Додаємо символ
  final bool useSymbol; // Показуємо чи використовувати символ

  PaymentMethod({
    required this.name,
    required this.icon,
    this.symbol,
    required this.useSymbol,
  });
}
