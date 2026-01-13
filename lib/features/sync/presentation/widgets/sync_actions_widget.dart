import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/sync_bloc.dart';
import '../bloc/sync_event.dart';
import '../../domain/constants/sync_constants.dart';

class SyncActionsWidget extends StatelessWidget {
  final bool isLoading;

  const SyncActionsWidget({super.key, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SyncConstants.defaultPadding),
      decoration: BoxDecoration(
        color: SyncConstants.secondaryColor,
        borderRadius: BorderRadius.circular(SyncConstants.borderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.sync, color: SyncConstants.infoColor, size: 20),
              SizedBox(width: 8),
              Text('Дії', style: SyncConstants.subtitleStyle),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildCompactAction(
                icon: Icons.info_outline,
                label: SyncConstants.statusLabel,
                color: SyncConstants.infoColor,
                onPressed: isLoading ? null : () => _onCheckStatus(context),
              ),
              _buildCompactAction(
                icon: Icons.analytics_outlined,
                label: SyncConstants.infoLabel,
                color: SyncConstants.successColor,
                onPressed: isLoading ? null : () => _onGetDetailedInfo(context),
              ),
              _buildCompactAction(
                icon: Icons.sync,
                label: SyncConstants.syncLabel,
                color: SyncConstants.infoColor,
                onPressed: isLoading ? null : () => _onPerformSync(context),
              ),
              _buildCompactAction(
                icon: Icons.sync_alt,
                label: SyncConstants.forceSyncLabel,
                color: SyncConstants.warningColor,
                onPressed: isLoading ? null : () => _onForceSync(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.6)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }

  void _onCheckStatus(BuildContext context) {
    context.read<SyncBloc>().add(CheckSyncStatusEvent());
  }

  void _onGetDetailedInfo(BuildContext context) {
    context.read<SyncBloc>().add(GetDetailedInfoEvent());
  }

  void _onPerformSync(BuildContext context) {
    context.read<SyncBloc>().add(PerformSyncEvent());
  }

  void _onForceSync(BuildContext context) {
    context.read<SyncBloc>().add(PerformSyncEvent(forceSync: true));
  }
}
