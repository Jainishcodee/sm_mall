import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AdminInventoryScreen extends StatelessWidget {
  const AdminInventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lowStock = const [
      _InventoryRow(name: 'Masala Chaas', stock: '5 left', status: 'Low'),
      _InventoryRow(name: 'Paneer Butter', stock: '2 left', status: 'Critical'),
      _InventoryRow(name: 'Gulab Jamun', stock: '0 left', status: 'Out'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: const [
              _InventoryMetric(
                title: 'Items',
                value: '132',
                color: AppColors.primary,
              ),
              SizedBox(width: 12),
              _InventoryMetric(
                title: 'Low stock',
                value: '14',
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              _InventoryMetric(
                title: 'Out of stock',
                value: '4',
                color: AppColors.primary,
              ),
              SizedBox(width: 12),
              _InventoryMetric(
                title: 'Healthy',
                value: '114',
                color: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Low Stock Alerts',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          ...lowStock.map(
            (item) => _InventoryTile(data: item),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _InventoryRow {
  final String name;
  final String stock;
  final String status;

  const _InventoryRow({
    required this.name,
    required this.stock,
    required this.status,
  });
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
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.slate200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: AppColors.slate500),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'This week',
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
  final _InventoryRow data;

  const _InventoryTile({
    required this.data,
  });

  Color _statusColor() {
    switch (data.status) {
      case 'Critical':
      case 'Out':
        return AppColors.primary;
      case 'Low':
      default:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.inventory_2_outlined, color: statusColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.name,
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  data.stock,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: AppColors.slate500),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              data.status,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
