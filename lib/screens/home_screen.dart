import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import '../providers/location_provider.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';
import '../widgets/address_header.dart';
import '../widgets/app_search_bar.dart';
import '../widgets/category_grid_tile.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/product_card.dart';
import '../widgets/view_cart_bar.dart';
import 'categories_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';
import 'wishlist_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool sheetShown = false;
  bool isServiceSheetOpen = false;
  int navIndex = 0;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(locationProvider.notifier).checkLocation();
    });
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final productsAsync = ref.watch(activeProductsStreamProvider);
    final highlightCategory = categoriesAsync.maybeWhen(
      data: (categories) =>
          categories.isNotEmpty ? categories.first.name : null,
      orElse: () => null,
    );

    if (!sheetShown && !isServiceSheetOpen && locationState.isOutOfRange) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? false;
        if (!sheetShown && !isServiceSheetOpen && isCurrentRoute) {
          sheetShown = true;
          _showServiceUnavailable(context, locationState);
        }
      });
    }

    final bottomInset = kBottomNavigationBarHeight + 120;
    final showLocationCard =
        locationState.status == LocationStatus.permissionDenied ||
        locationState.status == LocationStatus.serviceDisabled;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: AddressHeader(),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                child: AppSearchBar(
                  onChanged: (value) {
                    setState(() => searchQuery = value);
                  },
                ),
              ),
            ),
            if (showLocationCard)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: _LocationEnableCard(
                    onEnable: () =>
                        ref.read(locationProvider.notifier).checkLocation(),
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _PromoBanner(highlightCategory: highlightCategory),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  'Shop by category',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            categoriesAsync.when(
              data: (categories) => SliverToBoxAdapter(
                child: SizedBox(
                  height: 96,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      return SizedBox(
                        width: 68,
                        child: CategoryGridTile(category: categories[index]),
                      );
                    },
                  ),
                ),
              ),
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: CategoryHorizontalSkeleton(itemCount: 6),
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
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
                child: const _SectionTitle(
                  title: 'Feel the freshness',
                  subtitle: '18 products · Sponsored',
                ),
              ),
            ),
            productsAsync.when(
              data: (products) {
                final query = searchQuery.trim().toLowerCase();
                final filteredProducts = query.isEmpty
                    ? products
                    : products.where((product) {
                        final productName =
                            (product.name as Object?)?.toString() ?? '';
                        return productName.toLowerCase().contains(query);
                      }).toList();

                if (filteredProducts.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset),
                      child: Center(
                        child: Text(
                          'No products found for "$searchQuery".',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.slate500),
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
                        : width >= 500
                        ? 3
                        : 2;
                    final childAspectRatio = width < 360 ? 0.56 : 0.62;

                    return SliverPadding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          return ProductCard(product: filteredProducts[index]);
                        }, childCount: filteredProducts.length),
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
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
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
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: navIndex,
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
            setState(() => navIndex = 0);
            return;
          }
          if (index == 3) {
            setState(() => navIndex = index);
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const WishlistScreen()))
                .then((_) {
                  if (mounted) {
                    setState(() => navIndex = 0);
                  }
                });
            return;
          }
          setState(() => navIndex = index);
          if (index == 1) {
            Navigator.of(context)
                .push(
                  MaterialPageRoute(builder: (_) => const CategoriesScreen()),
                )
                .then((_) {
                  if (mounted) {
                    setState(() => navIndex = 0);
                  }
                });
          } else if (index == 2) {
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const CartScreen()))
                .then((_) {
                  if (mounted) {
                    setState(() => navIndex = 0);
                  }
                });
          } else if (index == 4) {
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const ProfileScreen()))
                .then((_) {
                  if (mounted) {
                    setState(() => navIndex = 0);
                  }
                });
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: ViewCartBar(
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const CartScreen()));
        },
      ),
    );
  }

  Future<void> _showServiceUnavailable(
    BuildContext context,
    LocationState locationState,
  ) async {
    if (!mounted || isServiceSheetOpen) {
      return;
    }
    isServiceSheetOpen = true;
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: AppColors.slate200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Service Unavailable',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'MallDash currently delivers within ${(locationState.serviceRadiusKm ?? AppConstants.serviceRadiusKm).toStringAsFixed(0)} km of ${locationState.zoneName ?? AppConstants.mallName}.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.slate500),
              ),
              if (locationState.distanceKm != null) ...[
                const SizedBox(height: 10),
                Text(
                  'You are ~${locationState.distanceKm!.toStringAsFixed(1)} km away.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.slate700),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
    if (mounted) {
      isServiceSheetOpen = false;
    }
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: AppColors.slate500),
        ),
      ],
    );
  }
}

class _PromoBanner extends StatelessWidget {
  final String? highlightCategory;

  const _PromoBanner({this.highlightCategory});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Daily essentials, delivered fast',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    highlightCategory == null
                        ? 'Fresh picks from today\'s favorites.'
                        : 'Fresh picks from $highlightCategory.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.slate500),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'Order Now',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 120,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Icon(
                Icons.local_grocery_store,
                color: AppColors.primary,
                size: 36,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationEnableCard extends StatelessWidget {
  final VoidCallback onEnable;

  const _LocationEnableCard({required this.onEnable});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.location_off, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Device location not enabled',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Enable your device location for a better delivery experience',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.slate500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: onEnable,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }
}
