import 'package:flutter/material.dart';
import '../../domain/entities/sync_status_info.dart';
import '../../domain/constants/sync_constants.dart';

class SyncStatusWidget extends StatelessWidget {
  final SyncStatusInfo? syncInfo;
  final bool isLoading;

  const SyncStatusWidget({super.key, this.syncInfo, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SyncConstants.defaultPadding),
      decoration: BoxDecoration(
        color: SyncConstants.secondaryColor,
        borderRadius: BorderRadius.circular(SyncConstants.borderRadius),
        border: Border.all(color: _getBorderColor().withOpacity(0.6)),
      ),
      child: Row(
        children: [
          Icon(_getStatusIcon(), color: _getStatusColor(), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _getStatusText(),
              style: SyncConstants.bodyStyle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isLoading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  SyncConstants.infoColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getBorderColor() {
    if (syncInfo == null) return SyncConstants.errorColor;
    return syncInfo!.isConnected
        ? SyncConstants.successColor
        : SyncConstants.errorColor;
  }

  IconData _getStatusIcon() {
    if (syncInfo == null) return Icons.wifi_off;
    return syncInfo!.isConnected ? Icons.wifi : Icons.wifi_off;
  }

  Color _getStatusColor() {
    if (syncInfo == null) return SyncConstants.errorColor;
    return syncInfo!.isConnected
        ? SyncConstants.successColor
        : SyncConstants.errorColor;
  }

  String _getStatusText() {
    if (syncInfo == null) return SyncConstants.serviceNotInitializedMessage;
    return syncInfo!.status;
  }
}
