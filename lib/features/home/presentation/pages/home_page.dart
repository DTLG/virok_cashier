import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/storage_service.dart';
import '../bloc/home_bloc.dart';
import '../widgets/sidebar_navigation.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/categories_grid.dart';
import '../widgets/recent_clients.dart';
import '../widgets/cashier_header.dart';
import '../widgets/cart_items_list.dart';
import '../widgets/payment_method_selector.dart';
import '../widgets/checkout_button.dart';
import '../widgets/login_required_widget.dart';
import '../widgets/home_loading_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeBloc(storageService: StorageService()),
      child: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          // Викликаємо перевірку статусу користувача при першому рендері
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (state is HomeInitial) {
              context.read<HomeBloc>().add(const CheckUserLoginStatus());
            }
          });

          // Показуємо відповідний контент залежно від стану
          if (state is HomeLoading) {
            return const HomeLoadingWidget();
          } else if (state is HomeInitial) {
            return const LoginRequiredWidget();
          } else if (state is HomeLoggedIn) {
            // Якщо користувач авторизований, показуємо основний контент
            return Scaffold(
              backgroundColor: const Color(0xFF1E1E1E),
              body: Row(
                children: [
                  // Перша колонка - Sidebar
                  Container(
                    width: 280,
                    color: const Color(0xFF2A2A2A),
                    child: Column(
                      children: [
                        // Логотип Virok
                        Container(
                          padding: const EdgeInsets.all(20),
                          child: const Row(
                            children: [
                              Icon(Icons.menu, color: Colors.white, size: 24),
                              SizedBox(width: 12),
                              Text(
                                'Virok',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Навігація
                        const Expanded(child: SidebarNavigation()),
                      ],
                    ),
                  ),

                  // Друга колонка - Основний контент
                  Expanded(
                    child: Container(
                      color: const Color(0xFF1E1E1E),
                      child: Column(
                        children: [
                          // Пошук
                          Container(
                            padding: const EdgeInsets.all(20),
                            child: const SearchBarWidget(),
                          ),

                          // Grid категорій
                          const Expanded(child: CategoriesGrid()),

                          // Останні клієнти
                          Container(
                            height: 180,
                            padding: const EdgeInsets.all(20),
                            child: const RecentClients(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Третя колонка - Каса
                  Container(
                    width: 350,
                    color: const Color(0xFF2A2A2A),
                    child: Column(
                      children: [
                        // Заголовок каси
                        const CashierHeader(),

                        // Список товарів
                        const Expanded(child: CartItemsList()),

                        // Метод оплати
                        Container(
                          padding: const EdgeInsets.all(20),
                          child: const PaymentMethodSelector(),
                        ),

                        // Кнопка провести чек
                        Container(
                          padding: const EdgeInsets.all(20),
                          child: const CheckoutButton(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          // Fallback - повертаємо loading якщо стан невідомий
          return const HomeLoadingWidget();
        },
      ),
    );
  }
}
