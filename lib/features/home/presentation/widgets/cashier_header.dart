import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/routes/app_router.dart';
import '../bloc/home_bloc.dart';

class CashierHeader extends StatelessWidget {
  const CashierHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF4A4A4A), width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Cash Register ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      '#1',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        // Логіка редагування
                      },
                      icon: const Icon(
                        Icons.edit,
                        color: Colors.grey,
                        size: 16,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                BlocBuilder<HomeBloc, HomeState>(
                  builder: (context, state) {
                    return Text(
                      state is HomeLoggedIn ? state.user.name : 'User',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    );
                  },
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              context.read<HomeBloc>().add(const LogoutUser());
            },
            icon: const Icon(Icons.logout, color: Colors.red, size: 20),
          ),
        ],
      ),
    );
  }
}
