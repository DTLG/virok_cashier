import 'package:flutter/material.dart';

class SyncIndicator extends StatefulWidget {
  final Duration duration;
  final Color color;
  final double size;

  const SyncIndicator({
    super.key,
    this.duration = const Duration(seconds: 3),
    this.color = Colors.blue,
    this.size = 40.0,
  });

  @override
  State<SyncIndicator> createState() => _SyncIndicatorState();

  /// Показати індикатор, повертає OverlayEntry для видалення
  static OverlayEntry show(BuildContext context) {
    final overlay = Overlay.of(context);
    if (overlay == null) {
      throw Exception('No Overlay found');
    }

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) =>
          const Positioned(bottom: 30, left: 30, child: SyncIndicator()),
    );

    overlay.insert(entry);
    return entry;
  }
}

class _SyncIndicatorState extends State<SyncIndicator>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rotationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotation;

  @override
  void initState() {
    super.initState();

    // Пульсація (scale)
    _scaleController = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);

    // Зменшений діапазон, плавна крива
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOutCubic),
    );

    // Створюємо контролер обертання
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Tween для обертання проти годинникової
    _rotation = Tween<double>(begin: 0.0, end: -1.0).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                widget.color.withOpacity(0.6),
                widget.color.withOpacity(0.15),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.3),
                blurRadius: 15,
                spreadRadius: 3,
              ),
            ],
          ),
          child: RotationTransition(
            turns: _rotation,
            child: const Icon(Icons.sync, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
