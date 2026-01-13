import 'package:flutter/material.dart';

import 'notification_toast.dart';
import 'toast_type.dart';

class ToastManager extends StatefulWidget {
  final ToastPosition position;

  const ToastManager({super.key, required this.position});

  static final _entries = <_ToastEntry>[];
  static OverlayEntry? _overlayEntry;

  static void show(
    BuildContext context, {
    required ToastType type,
    required String title,
    String? actionLabel,
    Exception? exception,
    VoidCallback? onAction,
    String? message,
    Duration duration = const Duration(seconds: 3),
    ToastPosition position = ToastPosition.topLeft,
  }) {
    final overlay = Overlay.of(context);
    if (overlay == null) return;

    if (_overlayEntry == null) {
      _overlayEntry = OverlayEntry(
        builder: (_) => ToastManager(position: position),
      );
      overlay.insert(_overlayEntry!);
    }

    late _ToastEntry entry; // оголошуємо спочатку

    entry = _ToastEntry(
      key: UniqueKey(),
      widget: NotificationToast(
        type: type,
        title: title,
        error: exception,
        actionLabel: actionLabel,
        onAction: onAction,
        message: message,
        onClose: () => _remove(entry), // тепер entry вже є
      ),
      duration: duration,
    );

    _entries.add(entry);
    _overlayEntry?.markNeedsBuild();

    Future.delayed(duration, () => _remove(entry));
  }

  static void _remove(_ToastEntry entry) {
    _entries.remove(entry);
    _overlayEntry?.markNeedsBuild();

    if (_entries.isEmpty) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
  }

  @override
  State<ToastManager> createState() => _ToastManagerState();
}

class _ToastManagerState extends State<ToastManager> {
  @override
  Widget build(BuildContext context) {
    Alignment alignment;
    EdgeInsets padding;

    switch (widget.position) {
      case ToastPosition.topRight:
        alignment = Alignment.topRight;
        padding = const EdgeInsets.only(top: 50, right: 20);
        break;
      case ToastPosition.topCenter:
        alignment = Alignment.topCenter;
        padding = const EdgeInsets.only(top: 50);
        break;
      case ToastPosition.bottomRight:
        alignment = Alignment.bottomRight;
        padding = const EdgeInsets.only(bottom: 50, right: 20);
        break;
      case ToastPosition.bottomCenter:
        alignment = Alignment.bottomCenter;
        padding = const EdgeInsets.only(bottom: 50);
        break;
      case ToastPosition.center:
        alignment = Alignment.center;
        padding = EdgeInsets.zero;
        break;
      case ToastPosition.bottomLeft:
        alignment = Alignment.bottomLeft;
        padding = const EdgeInsets.only(bottom: 50, left: 20);
        break;
      case ToastPosition.topLeft:
        alignment = Alignment.topLeft;
        padding = const EdgeInsets.only(top: 50, left: 20);
        break;
    }

    return SafeArea(
      child: Align(
        alignment: alignment,
        child: Padding(
          padding: padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ToastManager._entries.map((e) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AnimatedSwitcher(
                  key: e.key,
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) => SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1, 0),
                      end: Offset.zero,
                    ).animate(anim),
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: e.widget,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _ToastEntry {
  final Key key;
  final Widget widget;
  final Duration duration;
  _ToastEntry({
    required this.key,
    required this.widget,
    required this.duration,
  });
}
