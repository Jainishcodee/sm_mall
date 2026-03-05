import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/firestore_service.dart';
import '../theme/app_colors.dart';
import '../widgets/category_grid_tile.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/product_card.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';
import 'wishlist_screen.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final productsAsync = ref.watch(activeProductsStreamProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: CustomScrollView(
        slivers: [
          categoriesAsync.when(
            data: (categories) => SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate((context, index) {
                  return CategoryGridTile(category: categories[index]);
                }, childCount: categories.length),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.78,
                ),
              ),
            ),
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: CategoryGridSkeleton(itemCount: 8),
              ),
            ),
            error: (error, stack) => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: Text('Unable to load categories.')),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                'Popular picks',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          productsAsync.when(
            data: (products) => SliverLayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.crossAxisExtent;
                final crossAxisCount = width >= 900
                    ? 5
                    : width >= 700
                    ? 4
                    : width >= 500
                    ? 3
                    : 2;
                final childAspectRatio = width < 360 ? 0.56 : 0.62;

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return ProductCard(product: products[index]);
                    }, childCount: products.length),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: childAspectRatio,
                    ),
                  ),
                );
              },
            ),
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: ProductGridSkeleton(
                  itemCount: 6,
                  crossAxisCount: 3,
                  childAspectRatio: 0.62,
                  spacing: 12,
                ),
              ),
            ),
            error: (error, stack) => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: Text('Unable to load products.')),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 1,
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
          if (index == 0) {
            Navigator.of(context).pop();
            return;
          }
          if (index == 1) {
            return;
          }
          if (index == 2) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const CartScreen()),
            );
            return;
          }
          if (index == 3) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const WishlistScreen()),
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
}
