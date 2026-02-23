import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/cart_provider.dart';
import '../providers/user_prefs_provider.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/primary_button.dart';
import '../widgets/progress_stepper.dart';
import 'checkout_screen.dart';

// ---------------------------------------------------------------------------
// Delivery slot options
// ---------------------------------------------------------------------------

const _slots = [
  'As soon as possible',
  'Within 30 minutes',
  'Within 1 hour',
  'Today, 12 PM – 2 PM',
  'Today, 4 PM – 6 PM',
  'Today, 7 PM – 9 PM',
  'Tomorrow, 9 AM – 11 AM',
];

// ---------------------------------------------------------------------------
// Payment method options
// ---------------------------------------------------------------------------

const _paymentMethods = [
  'Cash on Delivery',
  'UPI',
  'Debit Card',
  'Credit Card',
  'Net Banking',
  'Wallet',
];

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class BillingScreen extends ConsumerWidget {
  const BillingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final prefsAsync = ref.watch(userPrefsProvider);
    const deliveryFee = 30.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Billing')),
      body: prefsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            const Center(child: Text('Could not load your saved details.')),
        data: (prefs) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const ProgressStepper(
                currentStep: 1,
                steps: ['Cart', 'Billing', 'Pay'],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: [
                    // ── Delivery Address ──────────────────────────────────
                    _InfoCard(
                      icon: Icons.location_on_outlined,
                      title: 'Delivery Address',
                      subtitle: prefs.deliveryAddress.isEmpty
                          ? 'Tap to add your address'
                          : prefs.deliveryAddress,
                      isEmpty: prefs.deliveryAddress.isEmpty,
                      trailing: prefs.deliveryAddress.isEmpty
                          ? 'Add'
                          : 'Change',
                      onTap: () => _showAddressSheet(
                        context,
                        ref,
                        prefs.deliveryAddress,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // ── Delivery Slot ─────────────────────────────────────
                    _InfoCard(
                      icon: Icons.access_time_rounded,
                      title: 'Delivery Slot',
                      subtitle: prefs.deliverySlot,
                      trailing: 'Edit',
                      onTap: () =>
                          _showSlotSheet(context, ref, prefs.deliverySlot),
                    ),
                    const SizedBox(height: 12),
                    // ── Payment Method ────────────────────────────────────
                    _InfoCard(
                      icon: Icons.payment_outlined,
                      title: 'Payment Method',
                      subtitle: prefs.paymentMethod,
                      trailing: 'Switch',
                      onTap: () =>
                          _showPaymentSheet(context, ref, prefs.paymentMethod),
                    ),
                    const SizedBox(height: 24),
                    // ── Bill summary ──────────────────────────────────────
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
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Continue to Payment',
                onPressed: prefs.deliveryAddress.isEmpty
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CheckoutScreen(),
                        ),
                      ),
              ),
              if (prefs.deliveryAddress.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Please add a delivery address to continue.',
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: AppColors.primary),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }

  // ── Address bottom sheet ──────────────────────────────────────────────────
  void _showAddressSheet(BuildContext context, WidgetRef ref, String current) {
    final ctrl = TextEditingController(text: current);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delivery Address',
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              autofocus: true,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'House / flat no., building, street, area…',
                filled: true,
                fillColor: const Color(0xFFF3F4F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  final text = ctrl.text.trim();
                  if (text.isNotEmpty) {
                    ref.read(userPrefsProvider.notifier).saveAddress(text);
                    Navigator.of(ctx).pop();
                  }
                },
                child: const Text('Save Address'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Delivery slot bottom sheet ────────────────────────────────────────────
  void _showSlotSheet(BuildContext context, WidgetRef ref, String current) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose Delivery Slot',
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ..._slots.map((slot) {
              final selected = slot == current;
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: selected ? AppColors.success : AppColors.slate400,
                  size: 20,
                ),
                title: Text(
                  slot,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                onTap: () {
                  ref.read(userPrefsProvider.notifier).saveSlot(slot);
                  Navigator.of(ctx).pop();
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  // ── Payment method bottom sheet ───────────────────────────────────────────
  void _showPaymentSheet(BuildContext context, WidgetRef ref, String current) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payment Method', style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 12),
            ..._paymentMethods.map((method) {
              final selected = method == current;
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: selected ? AppColors.success : AppColors.slate400,
                  size: 20,
                ),
                title: Text(
                  method,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                onTap: () {
                  ref
                      .read(userPrefsProvider.notifier)
                      .savePaymentMethod(method);
                  Navigator.of(ctx).pop();
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared widgets
// ---------------------------------------------------------------------------

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String trailing;
  final bool isEmpty;
  final VoidCallback? onTap;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.isEmpty = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.09),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
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
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isEmpty ? AppColors.slate400 : AppColors.slate900,
                    fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
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
