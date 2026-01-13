import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/settings_bloc.dart';

class SyncSettings extends StatelessWidget {
  const SyncSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: const Text(
            'Інтервал синхронізації',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIntervalOption(
                context,
                15,
                '15 хвилин',
                state.syncIntervalMinutes == 15,
              ),
              const SizedBox(height: 12),
              _buildIntervalOption(
                context,
                30,
                '30 хвилин',
                state.syncIntervalMinutes == 30,
              ),
              const SizedBox(height: 12),
              _buildIntervalOption(
                context,
                60,
                '1 година',
                state.syncIntervalMinutes == 60,
              ),
              const SizedBox(height: 12),
              _buildIntervalOption(
                context,
                120,
                '2 години',
                state.syncIntervalMinutes == 120,
              ),
              const SizedBox(height: 12),
              _buildIntervalOption(
                context,
                240,
                '4 години',
                state.syncIntervalMinutes == 240,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Закрити',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildIntervalOption(
    BuildContext context,
    int minutes,
    String title,
    bool isSelected,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          context.read<SettingsBloc>().add(
            UpdateSyncInterval(minutes: minutes),
          );
          Navigator.of(context).pop();
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.blue.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.schedule,
                color: isSelected ? Colors.blue : Colors.white70,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? Colors.blue : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: Colors.blue, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
