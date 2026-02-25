import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AdminAnalyticsScreen extends StatelessWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('orders').snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final docs = snap.data?.docs ?? [];
          final orders = docs.map((d) => d.data()).toList();

          // KPIs
          final total = orders.length;
          final delivered = orders.where((o) => o['status'] == 'Delivered').length;
          final cancelled = orders.where((o) => o['status'] == 'Cancelled').length;
          final revenue = orders.fold<double>(
              0, (s, o) => s + ((o['total'] ?? 0) as num).toDouble());
          final collected = orders
              .where((o) => o['paymentStatus'] == 'Completed')
              .fold<double>(
                  0, (s, o) => s + ((o['total'] ?? 0) as num).toDouble());
          final convRate = total > 0
              ? (delivered / total * 100).toStringAsFixed(1)
              : '0.0';
          final cancelRate = total > 0
              ? (cancelled / total * 100).toStringAsFixed(1)
              : '0.0';

          // Category revenue mix
          final catRevenue = <String, double>{};
          for (final o in orders) {
            final items = o['items'] as List? ?? [];
            for (final item in items) {
              final cat = (item['category'] ?? 'Other') as String;
              final price = ((item['price'] ?? 0) as num).toDouble();
              final qty = ((item['quantity'] ?? 1) as num).toInt();
              catRevenue[cat] = (catRevenue[cat] ?? 0) + price * qty;
            }
          }
          final totalCatRev = catRevenue.values.fold(0.0, (s, v) => s + v);
          final sortedCats = catRevenue.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _AnalyticsHeader(
                title: 'Performance',
                subtitle: 'Orders, revenue, and delivery metrics.',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _KpiCard(title: 'Total Orders', value: '$total', change: '${delivered} done', color: AppColors.primary),
                  const SizedBox(width: 12),
                  _KpiCard(title: 'Conversion', value: '$convRate%', change: '$delivered delivered', color: AppColors.success),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _KpiCard(title: 'Revenue', value: '₹${_fmt(revenue)}', change: 'Total', color: AppColors.success),
                  const SizedBox(width: 12),
                  _KpiCard(title: 'Cancellation', value: '$cancelRate%', change: '$cancelled orders', color: AppColors.primary),
                ],
              ),

              const SizedBox(height: 20),
              _AnalyticsHeader(
                title: 'Revenue Mix',
                subtitle: 'Category contribution from all orders.',
              ),
              const SizedBox(height: 12),
              if (sortedCats.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                      child: Text('No category data yet.',
                          style: Theme.of(context).textTheme.bodyMedium)),
                )
              else
                ...sortedCats.take(6).map((e) {
                  final pct = totalCatRev > 0 ? e.value / totalCatRev : 0.0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _CategoryBar(
                      label: e.key,
                      value: '${(pct * 100).toStringAsFixed(0)}%',
                      percent: pct,
                      color: AppColors.primary,
                    ),
                  );
                }),

              const SizedBox(height: 20),
              _AnalyticsHeader(
                title: 'Payment Summary',
                subtitle: 'Collected vs pending amounts.',
              ),
              const SizedBox(height: 12),
              _ProfitLossCard(
                revenue: revenue,
                collected: collected,
                pending: revenue - collected,
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  static String _fmt(double v) {
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}k';
    return '₹${v.toStringAsFixed(0)}';
  }
}

class _AnalyticsHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _AnalyticsHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(subtitle,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: AppColors.slate500)),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String change;
  final Color color;
  const _KpiCard({
    required this.title,
    required this.value,
    required this.change,
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
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: AppColors.slate500)),
            const SizedBox(height: 6),
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(change,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: color, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final String label;
  final String value;
  final double percent;
  final Color color;
  const _CategoryBar({
    required this.label,
    required this.value,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final divColor = Theme.of(context).dividerColor;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: divColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: Theme.of(context).textTheme.labelMedium)),
              Text(value,
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: AppColors.slate500)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percent.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: divColor,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfitLossCard extends StatelessWidget {
  final double revenue;
  final double collected;
  final double pending;
  const _ProfitLossCard({
    required this.revenue,
    required this.collected,
    required this.pending,
  });

  static String _fmt(double v) {
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}k';
    return '₹${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final divColor = Theme.of(context).dividerColor;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: divColor),
      ),
      child: Column(
        children: [
          _Row(label: 'Total Revenue', value: _fmt(revenue), color: AppColors.success),
          const SizedBox(height: 8),
          _Row(label: 'Collected (online)', value: _fmt(collected), color: AppColors.success),
          const SizedBox(height: 8),
          _Row(label: 'Pending / COD', value: _fmt(pending), color: AppColors.primary),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Row({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: AppColors.slate500)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(value,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
