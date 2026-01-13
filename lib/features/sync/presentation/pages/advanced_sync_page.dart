import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/app_initialization_service.dart';
import '../bloc/sync_bloc.dart';
import '../views/advanced_sync_view.dart';

class AdvancedSyncPage extends StatelessWidget {
  const AdvancedSyncPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AppInitializationService.get<SyncBloc>(),
      child: const AdvancedSyncView(),
    );
  }
}
