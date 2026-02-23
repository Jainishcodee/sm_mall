import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/cart_provider.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';

class ViewCartBar extends ConsumerWidget {
  final VoidCallback onTap;

  const ViewCartBar({super.key, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    if (cartState.isEmpty) {
      return const SizedBox.shrink();
    }

    final itemLabel = cartState.totalItems == 1
        ? '1 item'
        : '${cartState.totalItems} items';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.success,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.success.withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Leading cart icon box
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.shopping_bag_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            // Stacked label
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'View cart',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    height: 1.1,
                  ),
                ),
                Text(
                  itemLabel,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontWeight: FontWeight.w500,
                    fontSize: 10,
                    height: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 18),
            // Price + chevron
            Text(
              formatRupees(cartState.totalPrice),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 3),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white,
              size: 17,
            ),
          ],
        ),
      ),
    );
  }
}
