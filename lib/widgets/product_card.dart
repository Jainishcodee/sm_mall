import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import 'quantity_control.dart';

class ProductCard extends ConsumerWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final quantity = cartState.items[product.id]?.quantity ?? 0;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 74,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: product.imageUrl == null
                  ? const LinearGradient(
                      colors: [Color(0xFFE8EEFF), Color(0xFFCAD8FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
            ),
            child: product.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      product.imageUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  )
                : const Center(
                    child: Icon(Icons.shopping_bag, color: AppColors.primary),
                  ),
          ),
          const SizedBox(height: 6),
          Text(
            product.name,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            product.unit,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.slate500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            formatRupees(product.price),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          LayoutBuilder(
            builder: (context, constraints) {
              return Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: quantity == 0
                          ? _AddButton(
                              key: const ValueKey('add'),
                              onPressed: () => ref
                                  .read(cartProvider.notifier)
                                  .addItem(product),
                            )
                          : QuantityControl(
                              key: const ValueKey('qty'),
                              quantity: quantity,
                              onAdd: () => ref
                                  .read(cartProvider.notifier)
                                  .addItem(product),
                              onRemove: () => ref
                                  .read(cartProvider.notifier)
                                  .decrementItem(product),
                            ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _AddButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.success,
        side: const BorderSide(color: AppColors.success),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      ),
      child: const Text('ADD'),
    );
  }
}
