import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/cart_provider.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/primary_button.dart';
import '../widgets/quantity_control.dart';
import 'billing_screen.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final items = cartState.items.values.toList();
    const deliveryFee = 30.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: items.isEmpty
            ? Center(
                child: Text(
                  'Your cart is empty. Add items from the mall.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.slate500),
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
                                child: const Icon(
                                  Icons.shopping_bag,
                                  color: AppColors.primary,
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
                  const _SummaryRow(
                    label: 'Delivery fee',
                    value: '₹30',
                  ),
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
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const BillingScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                ],
              ),
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
