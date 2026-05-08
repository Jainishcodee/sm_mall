import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/favorites_provider.dart';
import '../screens/product_detail_screen.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';

class ProductCard extends ConsumerStatefulWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  ConsumerState<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<ProductCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final quantity = cartState.items[widget.product.id]?.quantity ?? 0;
    final inCart = quantity > 0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: widget.product),
          ),
        );
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _isPressed
                ? AppColors.primary
                : AppColors.primary.withOpacity(0.30),
            width: _isPressed ? 2.4 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_isPressed ? 0.10 : 0.05),
              blurRadius: _isPressed ? 10 : 2,
              offset: Offset(0, _isPressed ? 4 : 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image with overlay ADD / quantity stepper ──────────────
            AspectRatio(
              aspectRatio: 1.0,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                      child: widget.product.imageUrl != null &&
                              widget.product.imageUrl!.isNotEmpty
                          ? Image.network(
                              widget.product.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _placeholder(),
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return Container(
                                  color: AppColors.background,
                                );
                              },
                            )
                          : _placeholder(),
                    ),
                  ),
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: inCart
                        ? _CompactQuantity(
                            quantity: quantity,
                            onAdd: () => ref
                                .read(cartProvider.notifier)
                                .addItem(widget.product),
                            onRemove: () => ref
                                .read(cartProvider.notifier)
                                .decrementItem(widget.product),
                          )
                        : _AddButton(
                            onPressed: () => ref
                                .read(cartProvider.notifier)
                                .addItem(widget.product),
                          ),
                  ),
                  // Heart / favorite button — top-left, circular.
                  Positioned(
                    top: 6,
                    left: 6,
                    child: _FavoriteButton(productId: widget.product.id),
                  ),
                ],
              ),
            ),

            // ── Details ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate900,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Price row — left side reserved for future MRP
                  // (strikethrough) once Product gains an `mrp` field.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        formatRupees(widget.product.price),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _UnitPill(unit: widget.product.unit),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.primary.withOpacity(0.08),
      child: const Center(
        child: Icon(Icons.shopping_bag, color: AppColors.primary, size: 28),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _AddButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(6),
      elevation: 1,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.primary, width: 1.2),
          ),
          child: const Text(
            'ADD',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactQuantity extends StatelessWidget {
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _CompactQuantity({
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(6),
      elevation: 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.primary, width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StepperIcon(icon: Icons.remove, onTap: onRemove),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                quantity.toString(),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
            _StepperIcon(icon: Icons.add, onTap: onAdd),
          ],
        ),
      ),
    );
  }
}

class _StepperIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepperIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Icon(icon, size: 14, color: AppColors.primary),
      ),
    );
  }
}

class _UnitPill extends StatelessWidget {
  final String unit;

  const _UnitPill({required this.unit});

  @override
  Widget build(BuildContext context) {
    return Text(
      unit,
      style: const TextStyle(
        fontSize: 11,
        color: AppColors.slate500,
        fontWeight: FontWeight.w500,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _FavoriteButton extends ConsumerWidget {
  final String productId;

  const _FavoriteButton({required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favIds =
        ref.watch(favoriteIdsProvider).valueOrNull ?? const <String>{};
    final isFav = favIds.contains(productId);

    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 1,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () =>
            toggleFavorite(productId, isCurrentlyFavorite: isFav),
        child: SizedBox(
          width: 28,
          height: 28,
          child: Icon(
            isFav ? Icons.favorite : Icons.favorite_border,
            size: 16,
            color: isFav ? AppColors.primary : AppColors.slate500,
          ),
        ),
      ),
    );
  }
}
