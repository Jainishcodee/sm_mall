import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/favorites_provider.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/product_card.dart';
import 'cart_screen.dart';
import 'categories_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favIdsAsync = ref.watch(favoriteIdsProvider);
    final productsAsync = ref.watch(activeProductsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: favIdsAsync.when(
        data: (favIds) {
          if (favIds.isEmpty) return _empty(context);
          return productsAsync.when(
            data: (products) {
              final liked = products
                  .where((p) => favIds.contains(p.id))
                  .toList();
              if (liked.isEmpty) return _empty(context);
              return LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final crossAxisCount = width >= 900
                      ? 5
                      : width >= 700
                      ? 4
                      : width >= 360
                      ? 3
                      : 2;
                  final aspect = crossAxisCount >= 4
                      ? 0.65
                      : crossAxisCount == 3
                      ? 0.56
                      : 0.55;
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: aspect,
                    ),
                    itemCount: liked.length,
                    itemBuilder: (context, i) =>
                        ProductCard(product: liked[i]),
                  );
                },
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: ProductGridSkeleton(
                itemCount: 6,
                crossAxisCount: 3,
                childAspectRatio: 0.56,
                spacing: 12,
              ),
            ),
            error: (_, __) =>
                const Center(child: Text('Unable to load products.')),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, __) =>
            const Center(child: Text('Unable to load favorites.')),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 3,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.slate500,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view),
            label: 'Categories',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
        onTap: (index) {
          if (index == 3) return;
          if (index == 0) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
            return;
          }
          if (index == 1) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const CategoriesScreen()),
            );
            return;
          }
          if (index == 2) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const CartScreen()),
            );
            return;
          }
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          );
        },
      ),
    );
  }

  Widget _empty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_border, size: 56, color: AppColors.slate300),
          const SizedBox(height: 12),
          Text(
            'Your wishlist is empty.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.slate500),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap the heart on any product to save it here.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.slate400),
          ),
        ],
      ),
    );
  }
}
