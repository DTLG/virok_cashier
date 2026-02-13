import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/routes/app_router.dart';
import '../../bloc/home_bloc.dart';

class SidebarNavigation extends StatefulWidget {
  const SidebarNavigation({super.key});

  @override
  State<SidebarNavigation> createState() => _SidebarNavigationState();
}

class _SidebarNavigationState extends State<SidebarNavigation> {
  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.point_of_sale,
      title: 'Касова зміна',
      route: '/shift',
    ),
    NavigationItem(
      icon: Icons.library_books_rounded,
      title: 'Каталог',
      route: '/menu',
    ),
    NavigationItem(
      icon: Icons.assignment_return_rounded,
      title: 'Повернення',
      route: '/return',
    ),
    // NavigationItem(
    //   icon: Icons.build_rounded,
    //   title: 'Ремонт',
    //   route: '/repair',
    // ),
    // NavigationItem(
    //   icon: Icons.delivery_dining,
    //   title: 'Доставка',
    //   route: '/delivery',
    // ),
    NavigationItem(
      icon: Icons.settings_rounded,
      title: 'Налаштування',
      route: AppRouter.settings,
    ),
    NavigationItem(
      icon: Icons.sync_rounded,
      title: 'Налаштування Синхронізації',
      route: AppRouter.advancedSyncTest,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeViewState>(
      builder: (context, state) {
        return Column(
          children: [
            // Навігаційні пункти
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _navigationItems.length,
                itemBuilder: (context, index) {
                  final item = _navigationItems[index];
                  final isSelected = item.route == state.currentPage;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF4A4A4A)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      leading: Icon(item.icon, color: Colors.white, size: 20),
                      title: Text(
                        item.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      onTap: () {
                        // Використовуємо BLoC для навігації
                        context.read<HomeBloc>().add(
                          NavigateToPage(pageRoute: item.route),
                        );
                      },
                    ),
                  );
                },
              ),
            ),

            // Користувачі
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // _buildUserAvatar('L', 'Leslie K.', const Color(0xFF9C27B0)),
                  // const SizedBox(height: 8),
                  // _buildUserAvatar('C', 'Cameron W.', const Color(0xFF4CAF50)),
                  // const SizedBox(height: 8),
                  // _buildUserAvatar('J', 'Jacob J.', const Color(0xFFF44336)),
                ],
              ),
            ),
            // SizedBox(
            //   width: 120,
            //   height: 50,
            //   child: ElevatedButton(
            //     onPressed: () async {
            //       context.read<HomeBloc>().add(const XReportEvent());
            //     },
            //     style: ElevatedButton.styleFrom(
            //       backgroundColor: const Color(0xFF2A7F2A),
            //       foregroundColor: Colors.white,
            //       shape: RoundedRectangleBorder(
            //         borderRadius: BorderRadius.circular(8),
            //       ),
            //     ),
            //     child: const Text(
            //       'X-Звіт',
            //       style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            //     ),
            //   ),
            // ),
            const SizedBox(width: 10),
            // Копірайт
            Container(
              padding: const EdgeInsets.all(16),
              child: const Text(
                '© 2025 Virok App',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ],
        );
      },
    );
  }
}

class NavigationItem {
  final IconData icon;
  final String title;
  final String route;

  NavigationItem({
    required this.icon,
    required this.title,
    required this.route,
  });
}
