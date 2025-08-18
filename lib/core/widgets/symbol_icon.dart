import 'package:flutter/material.dart';

class SymbolIcon extends StatelessWidget {
  final String symbol;
  final double size;
  final Color? color;
  final FontWeight? fontWeight;

  const SymbolIcon({
    super.key,
    required this.symbol,
    this.size = 20.0,
    this.color,
    this.fontWeight = FontWeight.bold,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      symbol,
      style: TextStyle(
        fontSize: size,
        fontWeight: fontWeight,
        color: color,
        height: 1,
      ),
    );
  }
}
