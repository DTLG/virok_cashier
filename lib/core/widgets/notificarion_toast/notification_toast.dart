import 'package:flutter/material.dart';
import 'toast_type.dart';

enum ToastPosition {
  topRight,
  topCenter,
  bottomRight,
  bottomCenter,
  center,
  bottomLeft,
  topLeft,
}

class NotificationToast extends StatelessWidget {
  final ToastType type;
  final String title;
  final String? message;
  final Exception? error;
  final Duration duration;
  final VoidCallback? onAction;
  final String? actionLabel;
  final ToastPosition position;
  final VoidCallback? onClose; // <- для хрестика

  const NotificationToast({
    super.key,
    required this.type,
    required this.title,
    this.message,
    this.error,
    this.duration = const Duration(seconds: 2),
    this.onAction,
    this.actionLabel,
    this.position = ToastPosition.topLeft,
    this.onClose,
  });

  Color _backgroundColor() {
    switch (type) {
      case ToastType.success:
        return Colors.green.shade50;
      case ToastType.error:
        return Colors.red.shade50;
      case ToastType.info:
        return Colors.blue.shade50;
      case ToastType.warning:
        return Colors.orange.shade50;
    }
  }

  IconData _icon() {
    switch (type) {
      case ToastType.success:
        return Icons.check_circle;
      case ToastType.error:
        return Icons.error;
      case ToastType.info:
        return Icons.info;
      case ToastType.warning:
        return Icons.warning;
    }
  }

  Color _iconColor() {
    switch (type) {
      case ToastType.success:
        return Colors.green;
      case ToastType.error:
        return Colors.red;
      case ToastType.info:
        return Colors.blue;
      case ToastType.warning:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = Material(
      type: MaterialType.card,
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 260, maxWidth: 420),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _backgroundColor(),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_icon(), color: _iconColor(), size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(message ?? '', softWrap: true),
                    if (error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        error!.toString().replaceAll('Exception: ', ''),
                        softWrap: true,
                      ),
                    ],
                    if (onAction != null && actionLabel != null) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: onAction,
                        child: Text(actionLabel!),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                behavior: HitTestBehavior.opaque, // <- важливо
                onTap: onClose,
                child: const Padding(
                  // Padding, щоб “зона” іконки була більша
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.close, size: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return GestureDetector(
      behavior:
          HitTestBehavior.translucent, // <- робимо всю картку клікабельною
      onTap: () {
        print('onTap на toast!');
      },
      child: card,
    );
  }

  // ---- SHOW ----
  static void show(
    BuildContext context, {
    required ToastType type,
    required String title,
    String? message,
    Exception? error,
    Duration duration = const Duration(seconds: 2),
    VoidCallback? onAction,
    String? actionLabel,
    ToastPosition position = ToastPosition.topRight,
  }) {
    final overlay = Overlay.of(context);
    if (overlay == null) return;

    late OverlayEntry entry;
    void remove() {
      if (entry.mounted) entry.remove();
    }

    final toast = NotificationToast(
      type: type,
      title: title,
      message: message,
      error: error,
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel,
      position: position,
      onClose: remove,
    );

    // Вираховуємо позицію через Positioned
    Widget positioned(Widget child) {
      const gap = 20.0;
      const topPad = 50.0;
      const bottomPad = 50.0;

      switch (position) {
        case ToastPosition.topRight:
          return Positioned.fill(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: topPad, right: gap),
                child: child,
              ),
            ),
          );

        case ToastPosition.topCenter:
          return Positioned.fill(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: topPad),
                child: child,
              ),
            ),
          );

        case ToastPosition.bottomRight:
          return Positioned.fill(
            child: Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(bottom: bottomPad, right: gap),
                child: child,
              ),
            ),
          );

        case ToastPosition.bottomCenter:
          return Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: bottomPad),
                child: child,
              ),
            ),
          );

        case ToastPosition.center:
          return Positioned.fill(child: Center(child: child));

        case ToastPosition.bottomLeft:
          return Positioned.fill(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.only(bottom: bottomPad, left: gap),
                child: child,
              ),
            ),
          );

        case ToastPosition.topLeft:
          return Positioned.fill(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: topPad, left: gap),
                child: child,
              ),
            ),
          );
      }
    }

    entry = OverlayEntry(builder: (_) => positioned(SafeArea(child: toast)));

    overlay.insert(entry);
    Future.delayed(duration, remove);
  }
}
