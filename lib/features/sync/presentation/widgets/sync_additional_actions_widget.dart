import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/sync_bloc.dart';
import '../bloc/sync_event.dart';
import '../../domain/constants/sync_constants.dart';

class SyncAdditionalActionsWidget extends StatelessWidget {
  final bool isLoading;

  const SyncAdditionalActionsWidget({super.key, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SyncConstants.defaultPadding),
      decoration: BoxDecoration(
        color: SyncConstants.secondaryColor,
        borderRadius: BorderRadius.circular(SyncConstants.borderRadius),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.settings,
            color: SyncConstants.warningColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('Додаткові дії', style: SyncConstants.subtitleStyle),
          ),
          _buildCompactAction(
            icon: Icons.delete_outline,
            label: SyncConstants.clearLabel,
            color: SyncConstants.errorColor,
            onPressed: isLoading ? null : () => _onClearLocalData(context),
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

  void _onClearLocalData(BuildContext context) {
    context.read<SyncBloc>().add(ClearLocalDataEvent());
  }
}
