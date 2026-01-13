import 'package:flutter/material.dart';
import '../../domain/constants/sync_constants.dart';

class SyncHelpWidget extends StatelessWidget {
  const SyncHelpWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SyncConstants.largePadding),
      decoration: BoxDecoration(
        color: SyncConstants.secondaryColor,
        borderRadius: BorderRadius.circular(SyncConstants.largeBorderRadius),
        border: Border.all(color: SyncConstants.infoColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.help_outline,
                color: SyncConstants.infoColor,
                size: 24,
              ),
              SizedBox(width: 12),
              Text('Довідка', style: SyncConstants.titleStyle),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            SyncConstants.helpText,
            style: TextStyle(color: Colors.white70, height: 1.5),
          ),
        ],
      ),
    );
  }
}
