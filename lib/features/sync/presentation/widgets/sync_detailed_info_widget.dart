import 'package:flutter/material.dart';
import '../../domain/constants/sync_constants.dart';

class SyncDetailedInfoWidget extends StatelessWidget {
  final Map<String, dynamic> detailedInfo;

  const SyncDetailedInfoWidget({super.key, required this.detailedInfo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SyncConstants.largePadding),
      decoration: BoxDecoration(
        color: SyncConstants.secondaryColor,
        borderRadius: BorderRadius.circular(SyncConstants.largeBorderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info, color: SyncConstants.infoColor, size: 24),
              SizedBox(width: 12),
              Text('Детальна інформація', style: SyncConstants.titleStyle),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: SyncConstants.primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: detailedInfo.entries
                  .map(
                    (entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              entry.key,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              entry.value?.toString() ?? 'null',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
