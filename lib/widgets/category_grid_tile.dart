import 'package:flutter/material.dart';

import '../models/category.dart';
import '../theme/app_colors.dart';

class CategoryGridTile extends StatelessWidget {
  final Category category;

  const CategoryGridTile({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(category.iconData, color: AppColors.primary, size: 28),
        ),
        const SizedBox(height: 6),
        Text(
          category.name,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: AppColors.slate700),
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
