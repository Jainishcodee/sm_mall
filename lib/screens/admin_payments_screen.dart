import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AdminPaymentsScreen extends StatelessWidget {
  const AdminPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Payments')),
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

          final collected = docs
              .where((d) => d['paymentStatus'] == 'Completed')
              .fold<double>(
                0,
                (s, d) => s + ((d['total'] ?? 0) as num).toDouble(),
              );
          final pending = docs
              .where((d) => d['paymentStatus'] != 'Completed')
              .fold<double>(
                0,
                (s, d) => s + ((d['total'] ?? 0) as num).toDouble(),
              );
          final codCount = docs
              .where(
                (d) =>
                    (d['paymentMethod'] ?? '')
                        .toString()
                        .toLowerCase()
                        .contains('cash') ||
                    (d['paymentMethod'] ?? '')
                        .toString()
                        .toLowerCase()
                        .contains('cod'),
              )
              .length;
          final onlineCount = docs.length - codCount;

          // Sort by createdAt desc client-side
          final sorted = List.of(docs)
            ..sort((a, b) {
              final aT =
                  (a['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
              final bT =
                  (b['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
              return bT.compareTo(aT);
            });

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  _PaymentMetric(
                    title: 'Collected',
                    value: '₹${_fmt(collected)}',
                    sub: '$onlineCount online',
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 12),
                  _PaymentMetric(
                    title: 'Pending / COD',
                    value: '₹${_fmt(pending)}',
                    sub: '$codCount COD orders',
                    color: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('All Transactions', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              if (sorted.isEmpty)
                Center(
                  child: Text(
                    'No transactions yet.',
                    style: theme.textTheme.bodyMedium,
                  ),
                )
              else
                ...sorted
                    .take(30)
                    .map(
                      (doc) => _PaymentTile(docId: doc.id, data: doc.data()),
                    ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  static String _fmt(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }
}

class _PaymentMetric extends StatelessWidget {
  final String title;
  final String value;
  final String sub;
  final Color color;
  const _PaymentMetric({
    required this.title,
    required this.value,
    required this.sub,
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
                sub,
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
  final String docId;
  final Map<String, dynamic> data;
  const _PaymentTile({required this.docId, required this.data});

  Color _statusColor(String s) {
    switch (s) {
      case 'Completed':
        return AppColors.success;
      case 'Failed':
        return AppColors.primary;
      default:
        return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final payStatus = (data['paymentStatus'] ?? 'Pending') as String;
    final method = (data['paymentMethod'] ?? 'Unknown') as String;
    final total = ((data['total'] ?? 0) as num).toDouble();
    final sc = _statusColor(payStatus);
    final surface = Theme.of(context).colorScheme.surface;
    final divColor = Theme.of(context).dividerColor;
    final ts = (data['createdAt'] as Timestamp?)?.toDate();
    final dateStr = ts != null ? '${ts.day}/${ts.month}/${ts.year}' : '';

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
              color: sc.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.payments_outlined, color: sc),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${docId.substring(0, 8).toUpperCase()}',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '$method${dateStr.isNotEmpty ? ' · $dateStr' : ''}',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: AppColors.slate500),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${total.toStringAsFixed(0)}',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: sc.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  payStatus,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: sc,
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
