import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AdminPaymentsScreen extends StatelessWidget {
  const AdminPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settlements = const [
      _PaymentRow(
        id: 'PAY-204',
        type: 'Online',
        amount: 'Rs 1,240',
        status: 'Captured',
      ),
      _PaymentRow(
        id: 'PAY-205',
        type: 'Cash on delivery',
        amount: 'Rs 540',
        status: 'Pending',
      ),
      _PaymentRow(
        id: 'PAY-206',
        type: 'Online',
        amount: 'Rs 860',
        status: 'Captured',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: const [
              _PaymentMetric(
                title: 'Collected',
                value: 'Rs 12,840',
                color: AppColors.success,
              ),
              SizedBox(width: 12),
              _PaymentMetric(
                title: 'Pending',
                value: 'Rs 1,920',
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Recent Payments',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          ...settlements.map((payment) => _PaymentTile(data: payment)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _PaymentRow {
  final String id;
  final String type;
  final String amount;
  final String status;

  const _PaymentRow({
    required this.id,
    required this.type,
    required this.amount,
    required this.status,
  });
}

class _PaymentMetric extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _PaymentMetric({
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

class _PaymentTile extends StatelessWidget {
  final _PaymentRow data;

  const _PaymentTile({
    required this.data,
  });

  Color _statusColor() {
    switch (data.status) {
      case 'Captured':
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
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.payments_outlined, color: statusColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.id,
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  data.type,
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
                data.amount,
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
                  data.status,
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
