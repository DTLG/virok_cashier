import 'package:flutter/material.dart';
import '../../domain/constants/sync_constants.dart';

class SyncBackToHomeWidget extends StatelessWidget {
  const SyncBackToHomeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SyncConstants.defaultPadding),
      decoration: BoxDecoration(
        color: SyncConstants.secondaryColor,
        borderRadius: BorderRadius.circular(SyncConstants.borderRadius),
      ),
      child: OutlinedButton(
        onPressed: () => Navigator.of(context).pushReplacementNamed('/home'),
        child: const Text(SyncConstants.backToHomeLabel),
        style: OutlinedButton.styleFrom(
          foregroundColor: SyncConstants.infoColor,
          side: BorderSide(color: SyncConstants.infoColor.withOpacity(0.6)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
