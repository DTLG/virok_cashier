import 'package:flutter/material.dart';
import '../../../../core/routes/app_router.dart';

class SidebarNavigation extends StatefulWidget {
  const SidebarNavigation({super.key});

  @override
  State<SidebarNavigation> createState() => _SidebarNavigationState();
}

class _SidebarNavigationState extends State<SidebarNavigation> {
  int _selectedIndex = 2; // Menu вибрано за замовчуванням

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.calendar_today,
      title: 'Reservation',
      route: '/reservation',
    ),
    NavigationItem(
      icon: Icons.table_restaurant,
      title: 'Table services',
      route: '/table-services',
    ),
    NavigationItem(icon: Icons.restaurant_menu, title: 'Menu', route: '/menu'),
    NavigationItem(
      icon: Icons.delivery_dining,
      title: 'Delivery',
      route: '/delivery',
    ),
    NavigationItem(
      icon: Icons.account_balance,
      title: 'Accounting',
      route: '/accounting',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Навігаційні пункти
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _navigationItems.length,
            itemBuilder: (context, index) {
              final item = _navigationItems[index];
              final isSelected = index == _selectedIndex;

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
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  onTap: () {
                    setState(() {
                      _selectedIndex = index;
                    });
                    // Тут можна додати навігацію до відповідних сторінок
                    _handleNavigation(item.route);
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
              _buildUserAvatar('L', 'Leslie K.', const Color(0xFF9C27B0)),
              const SizedBox(height: 8),
              _buildUserAvatar('C', 'Cameron W.', const Color(0xFF4CAF50)),
              const SizedBox(height: 8),
              _buildUserAvatar('J', 'Jacob J.', const Color(0xFFF44336)),
            ],
          ),
        ),

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
  }

  void _handleNavigation(String route) {
    // Тут можна додати логіку навігації до різних сторінок
    // Поки що просто показуємо повідомлення
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigating to: $route'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Widget _buildUserAvatar(String initial, String name, Color color) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: color,
          child: Text(
            initial,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      ],
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
