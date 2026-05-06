import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../providers/cart_provider.dart';
import '../providers/location_provider.dart';
import '../providers/user_prefs_provider.dart';
import '../services/firestore_service.dart';
import '../services/firestore_service_extensions.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/primary_button.dart';
import '../widgets/progress_stepper.dart';
import 'order_success_screen.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  @override
  void initState() {
    super.initState();
    // Re-check location when entering checkout so the state is fresh.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(locationProvider.notifier).checkLocation();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final locationState = ref.watch(locationProvider);
    final prefs = ref.watch(userPrefsProvider).valueOrNull ?? const UserPrefs();
    const deliveryFee = 30.0;
    final canPlaceOrder = locationState.isServiceable;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const ProgressStepper(
                  currentStep: 2,
                  steps: ['Cart', 'Billing', 'Pay'],
                ),
                const SizedBox(height: 20),
                _InfoCard(
                  title: 'Delivery Address',
                  subtitle: prefs.deliveryAddress.isEmpty
                      ? 'No address set'
                      : prefs.deliveryAddress,
                  trailing: 'Change',
                  onTap: () => Navigator.of(context).pop(),
                ),
                const SizedBox(height: 12),
                _InfoCard(
                  title: 'Delivery Slot',
                  subtitle: prefs.deliverySlot,
                  trailing: 'Edit',
                  onTap: () => Navigator.of(context).pop(),
                ),
                const SizedBox(height: 12),
                _InfoCard(
                  title: 'Payment',
                  subtitle: prefs.paymentMethod,
                  trailing: 'Switch',
                  onTap: () => Navigator.of(context).pop(),
                ),
                if (prefs.paymentMethod == 'UPI') ...[
                  const SizedBox(height: 16),
                  _UpiQrCard(),
                ],
                const SizedBox(height: 24),
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
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                PrimaryButton(
                  label: 'Place Order',
                  onPressed: () async {
                if (!canPlaceOrder) {
                  _showDeliveryBlockedDialog(context, locationState);
                  return;
                }

                final user = FirebaseAuth.instance.currentUser;
                if (user == null) {
                  if (!context.mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please login to place order.'),
                    ),
                  );
                  return;
                }

                final cartItems = cartState.items.values.toList();
                if (cartItems.isEmpty) {
                  if (!context.mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cart is empty.')),
                  );
                  return;
                }

                final itemsPayload = cartItems
                    .map(
                      (item) => {
                        'productId': item.product.id,
                        'name': item.product.name,
                        'unit': item.product.unit,
                        'price': item.product.price,
                        'quantity': item.quantity,
                        'total': item.totalPrice,
                      },
                    )
                    .toList();

                final subtotal = cartState.totalPrice;
                final total = subtotal + deliveryFee;

                try {
                  final customerName =
                      user.displayName?.trim().isNotEmpty == true
                      ? user.displayName!.trim()
                      : (user.email?.trim().isNotEmpty == true
                            ? user.email!
                            : 'Customer');

                  // Atomic transaction: creates order + payment together.
                  // If either fails the whole operation rolls back.
                  final orderId = await ref
                      .read(firestoreServiceProvider)
                      .placeOrderWithPayment(
                        userId: user.uid,
                        customerName: customerName,
                        items: itemsPayload,
                        subtotal: subtotal,
                        deliveryFee: deliveryFee,
                        tax: 0,
                        total: total,
                        address: prefs.deliveryAddress,
                        paymentMethod: prefs.paymentMethod,
                      );

                  ref.read(cartProvider.notifier).clear();
                  if (!context.mounted) {
                    return;
                  }
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => OrderSuccessScreen(orderId: orderId),
                    ),
                    (route) => route.isFirst,
                  );
                } catch (error) {
                  if (!context.mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to place order: $error')),
                  );
                }
              },
            ),
                if (!canPlaceOrder)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Not in the range of mall. Move within delivery radius to place order.',
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: AppColors.primary),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ],
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
      builder: (ctx) => AlertDialog(
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
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String trailing;
  final VoidCallback onTap;

  const _InfoCard({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: AppColors.slate500),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          TextButton(
            onPressed: onTap,
            child: Text(
              trailing,
              style: const TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpiQrCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          Text(
            'Scan to Pay via UPI',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.slate900,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/images/QR.jpeg',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pay using any UPI app',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.slate500,
            ),
          ),
        ],
      ),
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
