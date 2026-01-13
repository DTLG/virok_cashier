import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/sync_bloc.dart';
import '../bloc/sync_state.dart';
import '../bloc/sync_event.dart';
import '../widgets/sync_status_widget.dart';
import '../widgets/sync_statistics_widget.dart';
import '../widgets/sync_actions_widget.dart';
import '../widgets/sync_additional_actions_widget.dart';
import '../widgets/sync_detailed_info_widget.dart';
import '../widgets/sync_help_widget.dart';
import '../widgets/sync_back_to_home_widget.dart';
import '../../domain/constants/sync_constants.dart';
import '../../domain/entities/sync_status_info.dart';

class AdvancedSyncView extends StatefulWidget {
  const AdvancedSyncView({super.key});

  @override
  State<AdvancedSyncView> createState() => _AdvancedSyncViewState();
}

class _AdvancedSyncViewState extends State<AdvancedSyncView> {
  @override
  void initState() {
    super.initState();
    // Автоматично перевіряємо статус при завантаженні
    context.read<SyncBloc>().add(CheckSyncStatusEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SyncConstants.primaryColor,
      body: BlocListener<SyncBloc, SyncState>(
        listener: (context, state) {
          if (state is SyncError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: SyncConstants.errorColor,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(SyncConstants.largePadding),
          child: BlocBuilder<SyncBloc, SyncState>(
            builder: (context, state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Статус карточка
                  SyncStatusWidget(
                    syncInfo: _getSyncInfoFromState(state),
                    isLoading: state is SyncLoading,
                  ),

                  const SizedBox(height: 24),

                  // Статистика
                  if (_getSyncInfoFromState(state) != null) ...[
                    SyncStatisticsWidget(
                      syncInfo: _getSyncInfoFromState(state),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Основні дії
                  SyncActionsWidget(isLoading: state is SyncLoading),

                  const SizedBox(height: 24),

                  // Додаткові дії
                  SyncAdditionalActionsWidget(isLoading: state is SyncLoading),

                  const SizedBox(height: 24),

                  // Детальна інформація
                  if (state is DetailedInfoLoaded) ...[
                    SyncDetailedInfoWidget(detailedInfo: state.detailedInfo),
                    const SizedBox(height: 24),
                  ],

                  // Довідка
                  const SyncHelpWidget(),

                  const SizedBox(height: 24),

                  // Повернутись на головну
                  const SyncBackToHomeWidget(),

                  const SizedBox(height: 40),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  SyncStatusInfo? _getSyncInfoFromState(SyncState state) {
    if (state is SyncStatusLoaded) {
      return state.syncInfo;
    }
    return null;
  }
}
