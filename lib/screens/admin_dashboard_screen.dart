import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'admin_analytics_screen.dart';
import 'admin_inventory_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_payments_screen.dart';
import 'admin_products_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final metrics = [
      const _MetricData(
        label: 'Total Orders',
        value: '1,284',
        trend: '+6.4%',
        color: AppColors.primary,
      ),
      const _MetricData(
        label: 'Active Orders',
        value: '42',
        trend: 'Live',
        color: AppColors.success,
      ),
      const _MetricData(
        label: 'Revenue',
        value: 'Rs 3.8L',
        trend: '+12%',
        color: AppColors.success,
      ),
      const _MetricData(
        label: 'Profit',
        value: 'Rs 78k',
        trend: '+9%',
        color: AppColors.success,
      ),
      const _MetricData(
        label: 'Loss',
        value: 'Rs 12k',
        trend: '-3%',
        color: AppColors.primary,
      ),
      const _MetricData(
        label: 'Low Stock',
        value: '14',
        trend: 'Items',
        color: AppColors.primary,
      ),
    ];

    final actions = [
      _ActionData(
        label: 'Orders',
        icon: Icons.receipt_long,
        color: AppColors.primary,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AdminOrdersScreen()),
        ),
      ),
      _ActionData(
        label: 'Products',
        icon: Icons.inventory_2_outlined,
        color: AppColors.success,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AdminProductsScreen()),
        ),
      ),
      _ActionData(
        label: 'Inventory',
        icon: Icons.warehouse_outlined,
        color: AppColors.primary,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AdminInventoryScreen()),
        ),
      ),
      _ActionData(
        label: 'Payments',
        icon: Icons.payments_outlined,
        color: AppColors.success,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AdminPaymentsScreen()),
        ),
      ),
      _ActionData(
        label: 'Analytics',
        icon: Icons.show_chart,
        color: AppColors.primary,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AdminAnalyticsScreen()),
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Overview',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children:
                metrics.map((metric) => _MetricCard(data: metric)).toList(),
          ),
          const SizedBox(height: 20),
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: actions.map((action) => _ActionTile(data: action)).toList(),
          ),
          const SizedBox(height: 20),
          Text(
            'Inventory Health',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          const _AnalyticsBar(
            label: 'In stock',
            value: '78%',
            percent: 0.78,
            color: AppColors.success,
          ),
          const SizedBox(height: 8),
          const _AnalyticsBar(
            label: 'Low stock',
            value: '14%',
            percent: 0.14,
            color: AppColors.primary,
          ),
          const SizedBox(height: 8),
          const _AnalyticsBar(
            label: 'Out of stock',
            value: '8%',
            percent: 0.08,
            color: AppColors.slate500,
          ),
          const SizedBox(height: 20),
          Text(
            'Recent Orders',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          ...List.generate(
            5,
            (index) => _RecentOrderTile(
              orderId: 'MD-14${80 + index}',
              items: '${2 + index} items',
              amount: 'Rs ${320 + index * 40}',
              status: index == 0
                  ? 'Pending'
                  : index == 1
                      ? 'Accepted'
                      : index == 2
                          ? 'Picked up'
                          : index == 3
                              ? 'On the way'
                              : 'Delivered',
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricData {
  final String label;
  final String value;
  final String trend;
  final Color color;

  const _MetricData({
    required this.label,
    required this.value,
    required this.trend,
    required this.color,
  });
}

class _MetricCard extends StatelessWidget {
  final _MetricData data;

  const _MetricCard({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: (MediaQuery.of(context).size.width - 16 * 2 - 12) / 2,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: AppColors.slate500),
          ),
          const SizedBox(height: 6),
          Text(
            data.value,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              data.trend,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: data.color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionData {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _ActionData({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _ActionTile extends StatelessWidget {
  final _ActionData data;

  const _ActionTile({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: data.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: (MediaQuery.of(context).size.width - 16 * 2 - 12) / 2,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.slate200),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: data.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(data.icon, color: data.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                data.label,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsBar extends StatelessWidget {
  final String label;
  final String value;
  final double percent;
  final Color color;

  const _AnalyticsBar({
    required this.label,
    required this.value,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
              Text(
                value,
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: AppColors.slate700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 6,
              backgroundColor: AppColors.slate200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentOrderTile extends StatelessWidget {
  final String orderId;
  final String items;
  final String amount;
  final String status;

  const _RecentOrderTile({
    required this.orderId,
    required this.items,
    required this.amount,
    required this.status,
  });

  Color _statusColor() {
    switch (status) {
      case 'Accepted':
      case 'Picked up':
      case 'On the way':
      case 'Delivered':
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
      margin: const EdgeInsets.only(bottom: 10),
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
            child: Icon(Icons.receipt_long, color: statusColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #$orderId',
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  items,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: AppColors.slate500),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: AppColors.slate700),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  status,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
