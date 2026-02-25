import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'admin_order_detail_screen.dart';

const _kStatuses = ['All', 'Pending', 'Accepted', 'Ready', 'On the way', 'Delivered', 'Cancelled'];

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              children: _kStatuses.map((s) {
                final sel = s == _filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(s),
                    selected: sel,
                    onSelected: (_) => setState(() => _filter = s),
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: sel ? Colors.white : null,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          var docs = snap.data?.docs ?? [];
          // Filter
          if (_filter != 'All') {
            docs = docs.where((d) => d['status'] == _filter).toList();
          }
          // Sort by createdAt desc client-side
          docs = List.of(docs)
            ..sort((a, b) {
              final aT = (a['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
              final bT = (b['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
              return bT.compareTo(aT);
            });

          // Summary counts
          final all = snap.data?.docs ?? [];
          final pending = all.where((d) => d['status'] == 'Pending').length;
          final active = all
              .where((d) => d['status'] == 'Accepted' || d['status'] == 'Ready' || d['status'] == 'On the way')
              .length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SummaryStrip(
                total: all.length,
                pending: pending,
                active: active,
              ),
              const SizedBox(height: 16),
              if (docs.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: Center(
                      child: Text('No orders found.',
                          style: theme.textTheme.bodyMedium)),
                )
              else
                ...docs.map((doc) => _OrderTile(
                      docId: doc.id,
                      data: doc.data(),
                      onView: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AdminOrderDetailScreen(orderId: doc.id),
                        ),
                      ),
                    )),
            ],
          );
        },
      ),
    );
  }
}

// ── Widgets ──────────────────────────────────────────────────────────────────

class _SummaryStrip extends StatelessWidget {
  final int total;
  final int pending;
  final int active;
  const _SummaryStrip({required this.total, required this.pending, required this.active});

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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryItem(label: 'Total', value: '$total', color: AppColors.primary),
          _divider(),
          _SummaryItem(label: 'Pending', value: '$pending', color: AppColors.primary),
          _divider(),
          _SummaryItem(label: 'Active', value: '$active', color: AppColors.success),
        ],
      ),
    );
  }

  Widget _divider() => Container(height: 32, width: 1, color: AppColors.slate200);
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: AppColors.slate500)),
      ],
    );
  }
}

class _OrderTile extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final VoidCallback onView;
  const _OrderTile({required this.docId, required this.data, required this.onView});

  Color _statusColor(String s) {
    switch (s) {
      case 'Delivered': return AppColors.success;
      case 'Accepted':
      case 'Ready':
      case 'On the way': return const Color(0xFF3B82F6);
      case 'Cancelled': return AppColors.slate500;
      default: return AppColors.primary;
    }
  }

  Future<void> _updateStatus(BuildContext context, String current) async {
    const all = ['Pending', 'Accepted', 'Ready', 'On the way', 'Delivered', 'Cancelled'];
    final selected = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final surface = Theme.of(ctx).colorScheme.surface;
        return Container(
          color: surface,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Update Status',
                  style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 12),
              ...all.map((s) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _statusColor(s),
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(s),
                    trailing: current == s
                        ? const Icon(Icons.check, color: AppColors.success)
                        : null,
                    onTap: () => Navigator.pop(ctx, s),
                  )),
            ],
          ),
        );
      },
    );
    if (selected != null && selected != current) {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(docId)
          .update({'status': selected, 'updatedAt': FieldValue.serverTimestamp()});
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = (data['status'] ?? 'Pending') as String;
    final sc = _statusColor(status);
    final customer = (data['customerName'] ?? 'Customer') as String;
    final total = ((data['total'] ?? 0) as num).toDouble();
    final items = (data['items'] as List?)?.length ?? 0;
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
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: sc.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.shopping_bag, color: sc),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${docId.substring(0, 8).toUpperCase()}',
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$customer · $items item${items != 1 ? 's' : ''}',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: AppColors.slate500),
                    ),
                  ],
                ),
              ),
              Text('₹${total.toStringAsFixed(0)}',
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                onTap: () => _updateStatus(context, status),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: sc.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(status,
                          style: TextStyle(
                              color: sc, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down, color: sc, size: 16),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              TextButton(
                  onPressed: onView, child: const Text('Details')),
            ],
          ),
        ],
      ),
    );
  }
}
