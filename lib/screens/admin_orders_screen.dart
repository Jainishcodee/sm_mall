import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'admin_order_detail_screen.dart';

class AdminOrdersScreen extends StatelessWidget {
  const AdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = [
      _OrderRow(
        id: 'MD-1482',
        customer: 'Amit Shah',
        total: 'Rs 540',
        status: 'Pending',
        items: '4 items',
      ),
      _OrderRow(
        id: 'MD-1483',
        customer: 'Neha Patel',
        total: 'Rs 320',
        status: 'Accepted',
        items: '2 items',
      ),
      _OrderRow(
        id: 'MD-1484',
        customer: 'Riya Mehta',
        total: 'Rs 780',
        status: 'Ready',
        items: '5 items',
      ),
      _OrderRow(
        id: 'MD-1485',
        customer: 'Dev Joshi',
        total: 'Rs 410',
        status: 'On the way',
        items: '3 items',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SummaryStrip(
            title: 'Today',
            subtitle: '42 total · 8 pending · 6 delayed',
          ),
          const SizedBox(height: 16),
          ...orders.map(
            (order) => _OrderTile(
              data: order,
              onView: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AdminOrderDetailScreen(orderId: order.id),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderRow {
  final String id;
  final String customer;
  final String total;
  final String status;
  final String items;

  const _OrderRow({
    required this.id,
    required this.customer,
    required this.total,
    required this.status,
    required this.items,
  });
}

class _SummaryStrip extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SummaryStrip({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.receipt_long, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: AppColors.slate500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final _OrderRow data;
  final VoidCallback onView;

  const _OrderTile({
    required this.data,
    required this.onView,
  });

  Color _statusColor() {
    switch (data.status) {
      case 'Accepted':
      case 'Ready':
      case 'On the way':
        return AppColors.success;
      case 'Pending':
      default:
        return AppColors.primary;
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
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child:
                    const Icon(Icons.shopping_bag, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${data.id}',
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${data.customer} · ${data.items}',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: AppColors.slate500),
                    ),
                  ],
                ),
              ),
              Text(
                data.total,
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: AppColors.slate700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
              const Spacer(),
              TextButton(
                onPressed: onView,
                child: const Text('View'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Accept'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
