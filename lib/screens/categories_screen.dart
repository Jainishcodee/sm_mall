import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/catalog_item.dart';
import '../models/product.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';
import '../widgets/category_chip.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/product_card.dart';
import 'cart_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'wishlist_screen.dart';

/// Sentinel name used by the "All Products" chip. Kept here (not in the
/// `Category` model) so it never collides with a real category created in
/// Firestore.
const _kAllCategory = 'All Products';

class CategoriesScreen extends ConsumerStatefulWidget {
  /// Optional category name to preselect when this screen is opened
  /// (e.g. when tapping a category tile on the home screen).
  final String? initialCategory;

  const CategoriesScreen({super.key, this.initialCategory});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  /// `null` and `_kAllCategory` both mean "show everything". We keep the
  /// state as the human-readable category name so chip equality is trivial.
  String _selected = _kAllCategory;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialCategory?.trim();
    if (initial != null && initial.isNotEmpty) {
      _selected = initial;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final catalogAsync = ref.watch(catalogItemsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: CustomScrollView(
        slivers: [
          // ── Horizontal category chips ─────────────────────────────────
          categoriesAsync.when(
            data: (categories) => SliverToBoxAdapter(
              child: SizedBox(
                height: 60,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  // +1 for the leading "All Products" chip.
                  itemCount: categories.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _AllProductsChip(
                        isSelected: _selected == _kAllCategory,
                        onTap: () =>
                            setState(() => _selected = _kAllCategory),
                      );
                    }
                    final category = categories[index - 1];
                    return GestureDetector(
                      onTap: () => setState(() => _selected = category.name),
                      child: CategoryChip(
                        category: category,
                        isSelected:
                            _selected.toLowerCase() ==
                            category.name.toLowerCase(),
                      ),
                    );
                  },
                ),
              ),
            ),
            loading: () => const SliverToBoxAdapter(
              child: SizedBox(height: 60),
            ),
            error: (_, __) => const SliverToBoxAdapter(
              child: SizedBox(height: 60),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                _selected == _kAllCategory ? 'All products' : _selected,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),

          // ── Filtered products grid ────────────────────────────────────
          catalogAsync.when(
            data: (items) {
              final products = _filterProducts(items, _selected);

              if (products.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 56,
                            color: AppColors.slate300,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _selected == _kAllCategory
                                ? 'No products yet.'
                                : 'No products in "$_selected" yet.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.slate500),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return SliverLayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.crossAxisExtent;
                  final crossAxisCount = width >= 900
                      ? 5
                      : width >= 700
                      ? 4
                      : width >= 360
                      ? 3
                      : 2;
                  final childAspectRatio = crossAxisCount >= 4
                      ? 0.65
                      : crossAxisCount == 3
                      ? 0.56
                      : 0.55;

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            ProductCard(product: products[index]),
                        childCount: products.length,
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: childAspectRatio,
                      ),
                    ),
                  );
                },
              );
            },
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
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (_) => false,
            );
            return;
          }
          if (index == 1) return;
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

  /// Pulls products out of catalog items, filtering by the selected category
  /// name (case-insensitive). When `_kAllCategory` is selected we return
  /// every active product unchanged.
  List<Product> _filterProducts(List<CatalogItem> items, String selected) {
    final activeOnly = items.where((i) => i.isActive);
    if (selected == _kAllCategory) {
      return activeOnly.map((i) => i.product).toList();
    }
    final needle = selected.toLowerCase();
    return activeOnly
        .where((i) => i.category.toLowerCase() == needle)
        .map((i) => i.product)
        .toList();
  }
}

/// "All Products" chip — visually mirrors `CategoryChip` but uses a generic
/// icon since there's no `Category` document for it.
class _AllProductsChip extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const _AllProductsChip({required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
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
              Icons.apps_rounded,
              size: 18,
              color: isSelected ? Colors.white : AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              _kAllCategory,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.slate700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
