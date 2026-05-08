import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/favorites_provider.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/quantity_control.dart';
import 'cart_screen.dart';

class ProductDetailScreen extends ConsumerWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final quantity = cartState.items[product.id]?.quantity ?? 0;
    final favIds =
        ref.watch(favoriteIdsProvider).valueOrNull ?? const <String>{};
    final isFav = favIds.contains(product.id);

    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .doc(product.id)
            .snapshots(),
        builder: (context, snapshot) {
          // Use live data from Firestore, fall back to passed product
          final data = snapshot.data?.data();
          final name = (data?['name'] as String?) ?? product.name;
          final price = ((data?['price'] ?? product.price) as num).toDouble();
          final unit = (data?['unit'] as String?) ?? product.unit;
          final imageUrl = (data?['imageUrl'] as String?) ?? product.imageUrl;
          final description = (data?['description'] as String?) ?? '';
          final category = (data?['category'] as String?) ?? '';
          // `stockNote` is the source of truth for inventory — usually a
          // numeric string like "15" but legacy docs may have plain text
          // ("In Stock"). Parse to int when possible, fall back to showing
          // the raw label.
          final stockNote = (data?['stockNote'] as String?) ?? '';
          final unitsLeft = int.tryParse(stockNote.trim());

          return CustomScrollView(
            slivers: [
              // ── Hero image ──
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
                leading: Padding(
                  padding: const EdgeInsets.all(6),
                  child: CircleAvatar(
                    backgroundColor: Colors.white.withValues(alpha: 0.9),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppColors.slate900),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.all(6),
                    child: CircleAvatar(
                      backgroundColor: Colors.white.withValues(alpha: 0.9),
                      child: IconButton(
                        icon: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav
                              ? AppColors.primary
                              : AppColors.slate900,
                        ),
                        tooltip: isFav
                            ? 'Remove from favorites'
                            : 'Add to favorites',
                        onPressed: () => toggleFavorite(
                          product.id,
                          isCurrentlyFavorite: isFav,
                        ),
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: imageUrl != null
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) => _PlaceholderImage(),
                        )
                      : _PlaceholderImage(),
                ),
              ),

              // ── Details ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category chip
                      if (category.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            category,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),

                      // Name
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.slate900,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Price
                      Text(
                        formatRupees(price),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Units panel — header, unit string, and units left.
                      const Text(
                        'Units',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.slate900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        unit,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.slate700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        unitsLeft == null
                            ? (stockNote.isEmpty ? 'Stock not set' : stockNote)
                            : (unitsLeft > 0
                                ? '$unitsLeft units left'
                                : 'Out of stock'),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: (unitsLeft != null && unitsLeft <= 0)
                              ? AppColors.primary
                              : AppColors.slate500,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Description
                      if (description.isNotEmpty) ...[
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.slate900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          description,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: AppColors.slate700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),

      // ── Bottom bar: Add to cart, or quantity stepper + Go to Cart ──
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: quantity == 0
              ? Row(
                  key: const ValueKey('add'),
                  children: [
                    Expanded(
                      child: Text(
                        formatRupees(product.price),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.slate900,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            ref.read(cartProvider.notifier).addItem(product),
                        icon: const Icon(Icons.add_shopping_cart, size: 18),
                        label: const Text(
                          'Add to Cart',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  key: const ValueKey('inCart'),
                  children: [
                    QuantityControl(
                      quantity: quantity,
                      onAdd: () =>
                          ref.read(cartProvider.notifier).addItem(product),
                      onRemove: () => ref
                          .read(cartProvider.notifier)
                          .decrementItem(product),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const CartScreen(),
                            ),
                          ),
                          icon: const Icon(
                            Icons.shopping_bag_outlined,
                            size: 18,
                          ),
                          label: Text(
                            'Go to Cart · ${formatRupees(product.price * quantity)}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE8EEFF), Color(0xFFCAD8FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.shopping_bag, size: 64, color: AppColors.primary),
      ),
    );
  }
}
