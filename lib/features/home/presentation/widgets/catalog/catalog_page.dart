import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'search_bar_widget.dart';
import 'categories_grid.dart';
import '../clients/recent_clients.dart';
import '../../bloc/home_bloc.dart';

class CatalogPage extends StatelessWidget {
  const CatalogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Пошук
        Container(
          padding: const EdgeInsets.all(20),
          child: SearchBarWidget(
            onSearchResults: (results) {
              // Обробка результатів пошуку через BLoC
              context.read<HomeBloc>().add(SetSearchResults(results: results));
            },
            onClearSearch: () {
              // Очищення результатів через BLoC
              context.read<HomeBloc>().add(const ClearSearchResults());
            },
          ),
        ),

        // Grid категорій
        const Expanded(child: CategoriesGrid()),

        // Останні клієнти
        const RecentClients(),
      ],
    );
  }
}
