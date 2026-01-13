import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import '../../bloc/home_bloc.dart';
import '../../../../../core/widgets/notificarion_toast/view.dart';

class CartItemsList extends StatelessWidget {
  const CartItemsList({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.select((HomeBloc b) => b.state.cart);
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Row(
            children: [
              Text(
                'Кошик',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: cart.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.home_repair_service_rounded,
                          size: 48,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Додайте перший товар',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: cart.length,
                    separatorBuilder: (_, __) =>
                        const Divider(color: Colors.white10),
                    itemBuilder: (context, index) {
                      final item = cart[index];
                      return _CartItemWidget(item: item);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _CartItemWidget extends StatefulWidget {
  final CartItem item;

  const _CartItemWidget({required this.item});

  @override
  State<_CartItemWidget> createState() => _CartItemWidgetState();
}

class _CartItemWidgetState extends State<_CartItemWidget> {
  late TextEditingController _quantityController;
  late FocusNode _quantityFocusNode;
  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(
      text: widget.item.quantity.toString(),
    );
    _quantityFocusNode = FocusNode();
  }

  @override
  void didUpdateWidget(_CartItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.quantity != widget.item.quantity) {
      _quantityController.text = widget.item.quantity.toString();
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _quantityFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.item.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '${widget.item.price.toStringAsFixed(2)} грн',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Кнопка мінус
        IconButton(
          onPressed: () {
            final newQuantity = widget.item.quantity - 1;
            context.read<HomeBloc>().add(
              UpdateCartItemQuantity(
                guid: widget.item.guid,
                quantity: newQuantity,
              ),
            );
            _quantityController.text = newQuantity.toString();
          },
          icon: const Icon(Icons.remove, color: Colors.white70, size: 18),
          tooltip: 'Зменшити кількість',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
        // Поле для введення кількості
        Container(
          width: 50,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.transparent),
            // border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: TextField(
            controller: _quantityController,
            textAlign: TextAlign.center,

            style: const TextStyle(color: Colors.white, fontSize: 14),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(width: 0, color: Colors.transparent),
              ),
              disabledBorder: OutlineInputBorder(
                borderSide: BorderSide(width: 0, color: Colors.transparent),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(width: 0, color: Colors.transparent),
              ),
              border: OutlineInputBorder(
                borderSide: BorderSide(width: 0, color: Colors.transparent),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 0),
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly, // ← тільки цифри
            ],
            focusNode: _quantityFocusNode,
            onChanged: (value) {
              final quantity = int.tryParse(value) ?? 1;
              context.read<HomeBloc>().add(
                UpdateCartItemQuantity(
                  guid: widget.item.guid,
                  quantity: quantity,
                ),
              );
            },
            onSubmitted: (value) {
              final quantity = int.tryParse(value) ?? 1;
              context.read<HomeBloc>().add(
                UpdateCartItemQuantity(
                  guid: widget.item.guid,
                  quantity: quantity,
                ),
              );
            },
            onEditingComplete: () {
              final quantity = int.tryParse(_quantityController.text) ?? 1;
              context.read<HomeBloc>().add(
                UpdateCartItemQuantity(
                  guid: widget.item.guid,
                  quantity: quantity,
                ),
              );
            },
          ),
        ),
        // Кнопка плюс
        IconButton(
          onPressed: () {
            final newQuantity = widget.item.quantity + 1;
            context.read<HomeBloc>().add(
              UpdateCartItemQuantity(
                guid: widget.item.guid,
                quantity: newQuantity,
              ),
            );
            _quantityController.text = newQuantity.toString();
          },
          icon: const Icon(Icons.add, color: Colors.white70, size: 18),
          tooltip: 'Збільшити кількість',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
        const SizedBox(width: 8),
        // Кнопка видалення
        IconButton(
          icon: const Icon(
            Icons.delete_outline,
            color: Colors.redAccent,
            size: 18,
          ),
          tooltip: 'Видалити',
          onPressed: () {
            context.read<HomeBloc>().add(
              RemoveFromCart(guid: widget.item.guid),
            );
            ToastManager.show(
              context,
              type: ToastType.warning,
              title: "Товар видалено",
              message: "\"${widget.item.name}\" видалено з кошика",
              position: ToastPosition.bottomLeft,
            );
          },
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ],
    );
  }
}
