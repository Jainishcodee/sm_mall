import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AdminAnalyticsScreen extends StatelessWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _AnalyticsHeader(
            title: 'Performance',
            subtitle: 'Orders, revenue, and delivery efficiency.',
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              _KpiCard(
                title: 'Orders',
                value: '1,284',
                change: '+6.4%',
                color: AppColors.primary,
              ),
              SizedBox(width: 12),
              _KpiCard(
                title: 'Conversion',
                value: '12.8%',
                change: '+1.2%',
                color: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              _KpiCard(
                title: 'Avg Delivery',
                value: '28 min',
                change: '-3 min',
                color: AppColors.success,
              ),
              SizedBox(width: 12),
              _KpiCard(
                title: 'Cancellation',
                value: '2.4%',
                change: '-0.3%',
                color: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _AnalyticsHeader(
            title: 'Revenue Mix',
            subtitle: 'Category contribution over the last 7 days.',
          ),
          const SizedBox(height: 12),
          const _CategoryBar(
            label: 'Meals',
            value: '48%',
            percent: 0.48,
            color: AppColors.primary,
          ),
          const SizedBox(height: 8),
          const _CategoryBar(
            label: 'Desserts',
            value: '22%',
            percent: 0.22,
            color: AppColors.success,
          ),
          const SizedBox(height: 8),
          const _CategoryBar(
            label: 'Beverages',
            value: '18%',
            percent: 0.18,
            color: AppColors.primary,
          ),
          const SizedBox(height: 8),
          const _CategoryBar(
            label: 'Snacks',
            value: '12%',
            percent: 0.12,
            color: AppColors.success,
          ),
          const SizedBox(height: 20),
          _AnalyticsHeader(
            title: 'Profit & Loss',
            subtitle: 'Operational cost vs profit trends.',
          ),
          const SizedBox(height: 12),
          const _ProfitLossCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _AnalyticsHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _AnalyticsHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
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
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                change,
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

class _ProfitLossCard extends StatelessWidget {
  const _ProfitLossCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        children: [
          _ProfitLossRow(
            label: 'Gross profit',
            value: 'Rs 78k',
            color: AppColors.success,
          ),
          const SizedBox(height: 8),
          _ProfitLossRow(
            label: 'Operational costs',
            value: 'Rs 22k',
            color: AppColors.primary,
          ),
          const SizedBox(height: 8),
          _ProfitLossRow(
            label: 'Net profit',
            value: 'Rs 56k',
            color: AppColors.success,
          ),
        ],
      ),
    );
  }
}

class _ProfitLossRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ProfitLossRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: AppColors.slate500),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}
