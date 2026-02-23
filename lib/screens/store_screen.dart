import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/store.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/product_card.dart';
import '../widgets/view_cart_bar.dart';
import 'cart_screen.dart';

class StoreScreen extends ConsumerWidget {
  final Store store;

  const StoreScreen({super.key, required this.store});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(storeProductsStreamProvider(store.id));

    return Scaffold(
      appBar: AppBar(title: Text(store.name)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE8EEFF), Color(0xFFC7D6FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(
                      Icons.storefront,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store.category,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: AppColors.slate500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          store.description,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.timer,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              store.eta,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: AppColors.slate700),
                            ),
                            const SizedBox(width: 10),
                            const Icon(
                              Icons.star,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              store.rating.toStringAsFixed(1),
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: AppColors.slate700),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: productsAsync.when(
                data: (products) => GridView.builder(
                  padding: const EdgeInsets.only(bottom: 120),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    return ProductCard(product: products[index]);
                  },
                ),
                loading: () => const ProductGridSkeleton(
                  itemCount: 6,
                  crossAxisCount: 2,
                  childAspectRatio: 0.72,
                  spacing: 14,
                ),
                error: (error, stack) =>
                    const Center(child: Text('Unable to load products.')),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: ViewCartBar(
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const CartScreen()));
        },
      ),
    );
  }
}
