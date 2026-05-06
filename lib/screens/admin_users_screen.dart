import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum _TimeFilter { all, last7Days, last30Days }

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  _TimeFilter _filter = _TimeFilter.all;

  DateTime? get _filterDate {
    final now = DateTime.now();
    switch (_filter) {
      case _TimeFilter.last7Days:
        return now.subtract(const Duration(days: 7));
      case _TimeFilter.last30Days:
        return now.subtract(const Duration(days: 30));
      case _TimeFilter.all:
        return null;
    }
  }

  String get _filterLabel {
    switch (_filter) {
      case _TimeFilter.last7Days:
        return 'Last 7 days';
      case _TimeFilter.last30Days:
        return 'Last 30 days';
      case _TimeFilter.all:
        return 'All time';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              children: _TimeFilter.values.map((f) {
                final sel = f == _filter;
                final label = switch (f) {
                  _TimeFilter.all => 'All Time',
                  _TimeFilter.last7Days => 'Last 7 Days',
                  _TimeFilter.last30Days => 'Last 30 Days',
                };
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: sel,
                    onSelected: (_) => setState(() => _filter = f),
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
            .collection('users')
            .snapshots(),
        builder: (context, usersSnap) {
          if (usersSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (usersSnap.hasError) {
            return Center(child: Text('Error: ${usersSnap.error}'));
          }

          // Also stream orders for counts
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .snapshots(),
            builder: (context, ordersSnap) {
              if (ordersSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final userDocs = usersSnap.data?.docs ?? [];
              final orderDocs = ordersSnap.data?.docs ?? [];

              // Build order count map per user, applying time filter
              final orderCountMap = <String, int>{};
              final orderTotalMap = <String, double>{};
              final cutoff = _filterDate;

              for (final doc in orderDocs) {
                final data = doc.data();
                final userId = data['userId'] as String? ?? '';
                if (userId.isEmpty) continue;

                // Apply time filter
                if (cutoff != null) {
                  final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                  if (createdAt == null || createdAt.isBefore(cutoff)) continue;
                }

                orderCountMap[userId] = (orderCountMap[userId] ?? 0) + 1;
                final total = ((data['total'] ?? 0) as num).toDouble();
                orderTotalMap[userId] = (orderTotalMap[userId] ?? 0) + total;
              }

              // Filter users: in time-filtered mode, only show users with orders
              var users = userDocs.map((doc) {
                final data = doc.data();
                return _UserData(
                  uid: doc.id,
                  name: _buildName(data),
                  phone: (data['phone'] as String?) ?? '',
                  email: (data['email'] as String?) ?? '',
                  isAdmin: data['isAdmin'] == true,
                  createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
                  orderCount: orderCountMap[doc.id] ?? 0,
                  totalSpent: orderTotalMap[doc.id] ?? 0,
                );
              }).toList();

              if (cutoff != null) {
                users = users.where((u) => u.orderCount > 0).toList();
              }

              // Sort: most orders first
              users.sort((a, b) => b.orderCount.compareTo(a.orderCount));

              // Summary
              final totalUsers = userDocs.length;
              final activeUsers = users.where((u) => u.orderCount > 0).length;
              final totalOrdersInPeriod = orderCountMap.values.fold<int>(0, (a, b) => a + b);

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Summary strip
                  _SummaryStrip(
                    totalUsers: totalUsers,
                    activeUsers: activeUsers,
                    totalOrders: totalOrdersInPeriod,
                    filterLabel: _filterLabel,
                  ),
                  const SizedBox(height: 16),
                  if (users.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 32),
                      child: Center(
                        child: Text(
                          cutoff != null
                              ? 'No users with orders in this period.'
                              : 'No users found.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    )
                  else
                    ...users.map((u) => _UserTile(user: u)),
                ],
              );
            },
          );
        },
      ),
    );
  }

  String _buildName(Map<String, dynamic> data) {
    final first = (data['firstName'] as String?) ?? '';
    final last = (data['lastName'] as String?) ?? '';
    final full = '$first $last'.trim();
    if (full.isNotEmpty) return full;
    final legacy = (data['name'] as String?) ?? '';
    if (legacy.isNotEmpty) return legacy;
    return 'Unknown';
  }
}

// ─────────────────────────────────────────────────────────────────────
// Data class
// ─────────────────────────────────────────────────────────────────────

class _UserData {
  final String uid;
  final String name;
  final String phone;
  final String email;
  final bool isAdmin;
  final DateTime? createdAt;
  final int orderCount;
  final double totalSpent;

  const _UserData({
    required this.uid,
    required this.name,
    required this.phone,
    required this.email,
    required this.isAdmin,
    required this.createdAt,
    required this.orderCount,
    required this.totalSpent,
  });
}

// ─────────────────────────────────────────────────────────────────────
// Summary strip
// ─────────────────────────────────────────────────────────────────────

class _SummaryStrip extends StatelessWidget {
  final int totalUsers;
  final int activeUsers;
  final int totalOrders;
  final String filterLabel;

  const _SummaryStrip({
    required this.totalUsers,
    required this.activeUsers,
    required this.totalOrders,
    required this.filterLabel,
  });

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
          _StatItem(label: 'Total Users', value: '$totalUsers', color: AppColors.primary),
          Container(height: 32, width: 1, color: AppColors.slate200),
          _StatItem(label: 'Active', value: '$activeUsers', color: AppColors.success),
          Container(height: 32, width: 1, color: AppColors.slate200),
          _StatItem(label: 'Orders', value: '$totalOrders', color: AppColors.primary),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.slate500,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// User tile
// ─────────────────────────────────────────────────────────────────────

class _UserTile extends StatelessWidget {
  final _UserData user;

  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final initials = user.name.isNotEmpty
        ? user.name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Name + contact
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.name,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (user.isAdmin) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Admin',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  user.phone.isNotEmpty ? user.phone : user.email,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.slate500,
                  ),
                ),
              ],
            ),
          ),
          // Order stats
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: user.orderCount > 0
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.slate200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${user.orderCount} order${user.orderCount != 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: user.orderCount > 0 ? AppColors.success : AppColors.slate500,
                  ),
                ),
              ),
              if (user.totalSpent > 0) ...[
                const SizedBox(height: 4),
                Text(
                  '₹${user.totalSpent.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate700,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
