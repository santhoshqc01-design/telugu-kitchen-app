// lib/widgets/category_filter.dart

import 'package:flutter/material.dart';

class CategoryFilter extends StatelessWidget {
  final String? selectedCategory;
  final String? selectedRegion;
  final Function(String?) onCategorySelected;
  final Function(String?) onRegionSelected;

  const CategoryFilter({
    super.key,
    this.selectedCategory,
    this.selectedRegion,
    required this.onCategorySelected,
    required this.onRegionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Category Icons Row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildCategoryItem('Breakfast', 'ఉదయం భోజనం',
                  Icons.breakfast_dining, Colors.orange),
              _buildCategoryItem(
                  'Lunch', 'మధ్యాహ్న భోజనం', Icons.lunch_dining, Colors.green),
              _buildCategoryItem(
                  'Dinner', 'రాత్రి భోజనం', Icons.dinner_dining, Colors.purple),
              _buildCategoryItem(
                  'Snacks', 'స్నాక్స్', Icons.cookie, Colors.pink),
              _buildCategoryItem(
                  'Desserts', 'మిఠాయిలు', Icons.cake, Colors.red),
              _buildCategoryItem(
                  'Beverages', 'పానీయాలు', Icons.local_cafe, Colors.blue),
            ],
          ),
        ),

        // Region Filter Chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildRegionChip('Andhra', 'ఆంధ్ర', Colors.orange),
              const SizedBox(width: 8),
              _buildRegionChip('Telangana', 'తెలంగాణ', Colors.pink),
              const SizedBox(width: 8),
              _buildRegionChip('Rayalaseema', 'రాయలసీమ', Colors.green),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryItem(
      String category, String teluguName, IconData icon, Color color) {
    final isSelected = selectedCategory == category;

    return GestureDetector(
      onTap: () {
        onCategorySelected(isSelected ? null : category);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: isSelected ? color : color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: isSelected ? Border.all(color: color, width: 3) : null,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : color,
                size: 32,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              teluguName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegionChip(String region, String teluguName, Color color) {
    final isSelected = selectedRegion == region;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          onRegionSelected(isSelected ? null : region);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: color,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Text(
            teluguName,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
