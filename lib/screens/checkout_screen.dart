import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/cart_provider.dart';
import '../providers/user_prefs_provider.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/primary_button.dart';
import '../widgets/progress_stepper.dart';
import 'order_success_screen.dart';

class CheckoutScreen extends ConsumerWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final prefs = ref.watch(userPrefsProvider).valueOrNull ?? const UserPrefs();
    const deliveryFee = 30.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
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
            const Spacer(),
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
              label: 'Place Order',
              onPressed: () {
                ref.read(cartProvider.notifier).clear();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const OrderSuccessScreen()),
                  (route) => route.isFirst,
                );
              },
            ),
          ],
        ),
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
