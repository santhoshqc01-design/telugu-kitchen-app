// lib/widgets/nutrition_info.dart

import 'package:flutter/material.dart';
import '../models/recipe_model.dart';

class NutritionInfo extends StatelessWidget {
  final Recipe recipe;
  final bool isTelugu;

  const NutritionInfo({
    super.key,
    required this.recipe,
    required this.isTelugu,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNutritionItem(
            value: '${recipe.calories}',
            unit: 'kcal',
            label: isTelugu ? 'క్యాలరీలు' : 'Calories',
            color: Colors.orange,
            icon: Icons.local_fire_department,
          ),
          _buildDivider(),
          _buildNutritionItem(
            value: '${recipe.protein.toStringAsFixed(1)}g',
            unit: '',
            label: isTelugu ? 'ప్రోటీన్' : 'Protein',
            color: Colors.red,
            icon: Icons.fitness_center,
          ),
          _buildDivider(),
          _buildNutritionItem(
            value: '${recipe.carbs.toStringAsFixed(1)}g',
            unit: '',
            label: isTelugu ? 'కార్బ్స్' : 'Carbs',
            color: Colors.green,
            icon: Icons.grain,
          ),
          _buildDivider(),
          _buildNutritionItem(
            value: '${recipe.fat.toStringAsFixed(1)}g',
            unit: '',
            label: isTelugu ? 'కొవ్వు' : 'Fat',
            color: Colors.blue,
            icon: Icons.water_drop,
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionItem({
    required String value,
    required String unit,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        if (unit.isNotEmpty)
          Text(
            unit,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.grey[300],
    );
  }
}
