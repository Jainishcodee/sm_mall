import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/cart_provider.dart';
import '../providers/location_provider.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/primary_button.dart';
import '../widgets/quantity_control.dart';
import 'billing_screen.dart';
import 'categories_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'wishlist_screen.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(locationProvider.notifier).checkLocation();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final locationState = ref.watch(locationProvider);
    final items = cartState.items.values.toList();
    const deliveryFee = 30.0;
    final canProceedToCheckout = locationState.isServiceable;

    return Scaffold(
      appBar: AppBar(title: const Text('Your Cart')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: items.isEmpty
            ? Center(
                child: Text(
                  'Your cart is empty. Add items from the mall.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.slate500),
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
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
                              Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: AppColors.background,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child:
                                      item.product.imageUrl != null &&
                                          item.product.imageUrl!.isNotEmpty
                                      ? Image.network(
                                          item.product.imageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(
                                                Icons.shopping_bag,
                                                color: AppColors.primary,
                                              ),
                                        )
                                      : const Icon(
                                          Icons.shopping_bag,
                                          color: AppColors.primary,
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.product.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.product.unit,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(color: AppColors.slate500),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      formatRupees(item.totalPrice),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              QuantityControl(
                                quantity: item.quantity,
                                onAdd: () => ref
                                    .read(cartProvider.notifier)
                                    .addItem(item.product),
                                onRemove: () => ref
                                    .read(cartProvider.notifier)
                                    .decrementItem(item.product),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SummaryRow(
                    label: 'Subtotal',
                    value: formatRupees(cartState.totalPrice),
                  ),
                  const SizedBox(height: 8),
                  const _SummaryRow(label: 'Delivery fee', value: '₹30'),
                  const SizedBox(height: 8),
                  _SummaryRow(
                    label: 'Total',
                    value: formatRupees(cartState.totalPrice + deliveryFee),
                    isEmphasized: true,
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'Proceed to Checkout',
                    onPressed: () {
                      if (!canProceedToCheckout) {
                        _showDeliveryBlockedDialog(context, locationState);
                        return;
                      }
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const BillingScreen(),
                        ),
                      );
                    },
                  ),
                  if (!canProceedToCheckout)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        locationState.status == LocationStatus.outOfRange
                            ? 'Not in the range of mall. Move within delivery radius to place order.'
                            : 'Enable location and try again to place order.',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 6),
                ],
              ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 2,
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
          if (index == 2) {
            return;
          }
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

  Future<void> _showDeliveryBlockedDialog(
    BuildContext context,
    LocationState locationState,
  ) async {
    final distance = locationState.distanceKm;
    final radius = locationState.serviceRadiusKm?.toStringAsFixed(0) ?? '10';
    final zoneName = locationState.zoneName ?? 'the mall';
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Not in the range of mall'),
          content: Text(
            locationState.status == LocationStatus.outOfRange
                ? distance == null
                      ? 'Delivery is available only within $radius km of $zoneName.'
                      : 'You are ${distance.toStringAsFixed(1)} km away. Delivery is available only within $radius km of $zoneName.'
                : 'Please allow location permission and keep location services on to place order.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isEmphasized;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isEmphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontWeight: isEmphasized ? FontWeight.w600 : FontWeight.w400,
      color: isEmphasized ? AppColors.slate900 : AppColors.slate700,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style),
      ],
    );
  }
}
