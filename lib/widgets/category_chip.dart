import 'package:flutter/material.dart';

import '../models/category.dart';
import '../theme/app_colors.dart';

class CategoryChip extends StatelessWidget {
  final Category category;
  final bool isSelected;

  const CategoryChip({
    super.key,
    required this.category,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            category.iconData,
            size: 18,
            color: isSelected ? Colors.white : AppColors.primary,
          ),
          const SizedBox(width: 8),
          Text(
            category.name,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.slate700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
