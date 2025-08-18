import 'package:flutter/material.dart';

class CategoriesGrid extends StatelessWidget {
  const CategoriesGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = [
      CategoryItem(
        name: 'Breakfast',
        icon: Icons.coffee,
        itemCount: 13,
        color: const Color(0xFF90EE90),
      ),
      CategoryItem(
        name: 'Soups',
        icon: Icons.soup_kitchen,
        itemCount: 8,
        color: const Color(0xFFE6E6FA),
      ),
      CategoryItem(
        name: 'Pasta',
        icon: Icons.ramen_dining,
        itemCount: 10,
        color: const Color(0xFF87CEEB),
      ),
      CategoryItem(
        name: 'Sushi',
        icon: Icons.set_meal,
        itemCount: 15,
        color: const Color(0xFFE6E6FA),
      ),
      CategoryItem(
        name: 'Main course',
        icon: Icons.restaurant,
        itemCount: 7,
        color: const Color(0xFFFFB6C1),
      ),
      CategoryItem(
        name: 'Desserts',
        icon: Icons.cake,
        itemCount: 9,
        color: const Color(0xFFFFC0CB),
      ),
      CategoryItem(
        name: 'Drinks',
        icon: Icons.local_cafe,
        itemCount: 11,
        color: const Color(0xFFFFB6C1),
      ),
      CategoryItem(
        name: 'Alcohol',
        icon: Icons.wine_bar,
        itemCount: 12,
        color: const Color(0xFFE0FFFF),
      ),
    ];

    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return _buildCategoryCard(category);
            },
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'Choose category',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(CategoryItem category) {
    return Container(
      decoration: BoxDecoration(
        color: category.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(category.icon, size: 32, color: Colors.black87),
          const SizedBox(height: 8),
          Text(
            category.name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '${category.itemCount} items',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class CategoryItem {
  final String name;
  final IconData icon;
  final int itemCount;
  final Color color;

  CategoryItem({
    required this.name,
    required this.icon,
    required this.itemCount,
    required this.color,
  });
}
