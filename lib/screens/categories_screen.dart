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

/// Sentinel ID used by the "All Products" chip. Never collides with a real
/// Firestore category doc since their IDs are auto-generated or `cat_*`.
const _kAllId = '__all__';

class CategoriesScreen extends ConsumerStatefulWidget {
  /// Optional category **document ID** (e.g. `cat_drinks`) to preselect when
  /// this screen is opened — products store this exact value in their
  /// `category` field, so we filter by ID, not by display name.
  final String? initialCategoryId;

  const CategoriesScreen({super.key, this.initialCategoryId});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  /// Selected category doc ID, or `_kAllId` for "show everything".
  String _selectedId = _kAllId;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialCategoryId?.trim();
    if (initial != null && initial.isNotEmpty) {
      _selectedId = initial;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final catalogAsync = ref.watch(catalogItemsStreamProvider);

    // Resolve the human-readable name for the section header.
    final selectedName = categoriesAsync.maybeWhen(
      data: (categories) {
        if (_selectedId == _kAllId) return 'All products';
        final match = categories
            .where((c) => c.id == _selectedId)
            .toList(growable: false);
        return match.isEmpty ? _selectedId : match.first.name;
      },
      orElse: () => _selectedId == _kAllId ? 'All products' : _selectedId,
    );

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
                  itemCount: categories.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _AllProductsChip(
                        isSelected: _selectedId == _kAllId,
                        onTap: () => setState(() => _selectedId = _kAllId),
                      );
                    }
                    final category = categories[index - 1];
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedId = category.id),
                      child: CategoryChip(
                        category: category,
                        isSelected: _selectedId == category.id,
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
                selectedName,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),

          // ── Filtered products grid ────────────────────────────────────
          catalogAsync.when(
            data: (items) {
              final products = _filterProducts(items, _selectedId);

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
                            _selectedId == _kAllId
                                ? 'No products yet.'
                                : 'No products in "$selectedName" yet.',
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

  /// Match products by their `category` field against the category doc ID.
  /// Comparison is case-insensitive so a product with `"Cat_Drinks"` still
  /// resolves to `cat_drinks`.
  List<Product> _filterProducts(List<CatalogItem> items, String selectedId) {
    final activeOnly = items.where((i) => i.isActive);
    if (selectedId == _kAllId) {
      return activeOnly.map((i) => i.product).toList();
    }
    final needle = selectedId.toLowerCase();
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
              'All Products',
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
