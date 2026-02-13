import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/home_bloc.dart';
import 'reservation_page.dart';
import 'returns_page.dart';
import 'repair_page.dart';
import 'delivery_page.dart';
import '../../../../../core/routes/app_router.dart';
import '../../../../settings/presentation/pages/settings_page.dart';
import '../../../../nomenclatura/advanced_sync_test_page.dart';
import '../catalog/catalog_page.dart';
import 'shift_management_page.dart';

class PageContent extends StatelessWidget {
  const PageContent({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeViewState>(
      builder: (context, state) {
        switch (state.currentPage) {
          case '/shift':
            return const ShiftManagementPage();
          case '/menu':
            return const CatalogPage();
          case '/reservation':
            return const ReservationPage();
          case '/table-services':
          case '/return':
            return const ReturnsPage();
          case '/repair':
            return const RepairPage();
          case '/delivery':
            return const DeliveryPage();
          case AppRouter.advancedSyncTest:
            return const AdvancedSyncTestPage();
          case AppRouter.settings:
            return const SettingsPage();
          default:
            return const CatalogPage(); // За замовчуванням показуємо каталог
        }
      },
    );
  }
}
