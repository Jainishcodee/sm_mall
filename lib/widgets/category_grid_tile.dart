import 'package:flutter/material.dart';

import '../models/category.dart';
import '../theme/app_colors.dart';

class CategoryGridTile extends StatelessWidget {
  final Category category;
  final VoidCallback? onTap;
  final bool isSelected;

  const CategoryGridTile({
    super.key,
    required this.category,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: isSelected
                  ? null
                  : Border.all(color: AppColors.primary.withOpacity(0.15)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              category.iconData,
              color: isSelected ? Colors.white : AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            category.name,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isSelected ? AppColors.primary : AppColors.slate700,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
