import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AdminInventoryScreen extends StatelessWidget {
  const AdminInventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Inventory')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final docs = snap.data?.docs ?? [];
          final total = docs.length;
          final outOfStock = docs
              .where(
                (d) =>
                    ((d.data()['stockQuantity'] ?? d.data()['stock'] ?? 0)
                            as num)
                        .toInt() ==
                    0,
              )
              .toList();
          final lowStock = docs.where((d) {
            final q =
                ((d.data()['stockQuantity'] ?? d.data()['stock'] ?? 0) as num)
                    .toInt();
            return q > 0 && q < 10;
          }).toList();
          final healthyCount = total - outOfStock.length - lowStock.length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  _InventoryMetric(
                    title: 'Total Items',
                    value: '$total',
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  _InventoryMetric(
                    title: 'Healthy',
                    value: '$healthyCount',
                    color: AppColors.success,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _InventoryMetric(
                    title: 'Low Stock',
                    value: '${lowStock.length}',
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  _InventoryMetric(
                    title: 'Out of Stock',
                    value: '${outOfStock.length}',
                    color: AppColors.primary,
                  ),
                ],
              ),
              if (outOfStock.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text('Out of Stock', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                ...outOfStock.map(
                  (d) =>
                      _InventoryTile(data: d.data(), docId: d.id, label: 'Out'),
                ),
              ],
              if (lowStock.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text('Low Stock Alerts', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                ...lowStock.map(
                  (d) => _InventoryTile(
                    data: d.data(),
                    docId: d.id,
                    label:
                        ((d.data()['stockQuantity'] ?? d.data()['stock'] ?? 0)
                                    as num)
                                .toInt() <=
                            3
                        ? 'Critical'
                        : 'Low',
                  ),
                ),
              ],
              if (outOfStock.isEmpty && lowStock.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 56,
                          color: AppColors.success,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'All items are well-stocked!',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

class _InventoryMetric extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  const _InventoryMetric({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final divColor = Theme.of(context).dividerColor;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: divColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: AppColors.slate500),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Live',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final String label;
  const _InventoryTile({
    required this.data,
    required this.docId,
    required this.label,
  });

  Color _labelColor() {
    switch (label) {
      case 'Out':
        return AppColors.primary;
      case 'Critical':
        return AppColors.primary;
      default:
        return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lc = _labelColor();
    final stock = (data['stockQuantity'] ?? data['stock'] ?? 0) as int;
    final surface = Theme.of(context).colorScheme.surface;
    final divColor = Theme.of(context).dividerColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: divColor),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: lc.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.inventory_2_outlined, color: lc),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['name'] ?? 'Unknown',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  stock == 0 ? 'Out of stock' : '$stock left',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: AppColors.slate500),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: lc.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              label,
              style: TextStyle(color: lc, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
