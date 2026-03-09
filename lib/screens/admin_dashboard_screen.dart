import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';
import 'admin_delivery_zone_screen.dart';
import 'admin_analytics_screen.dart';
import 'admin_inventory_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_payments_screen.dart';
import 'admin_products_screen.dart';
import 'login_screen.dart';
import 'settings_screen.dart';

// ── Providers ────────────────────────────────────────────────────────────────

final _dashOrdersProvider =
    StreamProvider.autoDispose<List<Map<String, dynamic>>>(
      (ref) => FirebaseFirestore.instance
          .collection('orders')
          .snapshots()
          .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList()),
    );

final _dashProductsProvider =
    StreamProvider.autoDispose<List<Map<String, dynamic>>>(
      (ref) => FirebaseFirestore.instance
          .collection('products')
          .snapshots()
          .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList()),
    );

// ── Screen ───────────────────────────────────────────────────────────────────

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text('Exit the admin panel and return to login.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(_dashOrdersProvider);
    final productsAsync = ref.watch(_dashProductsProvider);
    final orders = ordersAsync.valueOrNull ?? [];
    final products = productsAsync.valueOrNull ?? [];
    final theme = Theme.of(context);

    // ── computed metrics ────────────────────────────────────────────────────
    final totalOrders = orders.length;
    final activeOrders = orders.where((o) {
      final s = (o['status'] ?? '') as String;
      return s == 'Pending' ||
          s == 'Accepted' ||
          s == 'Ready' ||
          s == 'On the way';
    }).length;
    final revenue = orders.fold<double>(
      0,
      (sum, o) => sum + ((o['total'] ?? 0) as num).toDouble(),
    );
    final collected = orders
        .where((o) => o['paymentStatus'] == 'Completed')
        .fold<double>(
          0,
          (sum, o) => sum + ((o['total'] ?? 0) as num).toDouble(),
        );
    final lowStockCount = products.where((p) {
      final q = (p['stockQuantity'] ?? p['stock'] ?? 0) as int;
      return q > 0 && q < 10;
    }).length;
    final outOfStockCount = products.where((p) {
      final q = (p['stockQuantity'] ?? p['stock'] ?? 0) as int;
      return q == 0;
    }).length;

    final recentOrders = List.of(orders)
      ..sort((a, b) {
        final aT = (a['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
        final bT = (b['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
        return bT.compareTo(aT);
      });

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) _confirmLogout(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_none),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Settings',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () => _confirmLogout(context),
            ),
          ],
        ),
        body: ordersAsync.isLoading && productsAsync.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Overview KPIs ─────────────────────────────────────────
                  Text('Overview', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _MetricCard(
                        label: 'Total Orders',
                        value: '$totalOrders',
                        trend: 'All time',
                        color: AppColors.primary,
                      ),
                      _MetricCard(
                        label: 'Active',
                        value: '$activeOrders',
                        trend: 'Live',
                        color: AppColors.success,
                      ),
                      _MetricCard(
                        label: 'Revenue',
                        value: '₹${_fmtAmt(revenue)}',
                        trend: 'Total',
                        color: AppColors.success,
                      ),
                      _MetricCard(
                        label: 'Collected',
                        value: '₹${_fmtAmt(collected)}',
                        trend: 'Online',
                        color: AppColors.success,
                      ),
                      _MetricCard(
                        label: 'Low Stock',
                        value: '$lowStockCount',
                        trend: 'Items',
                        color: AppColors.primary,
                      ),
                      _MetricCard(
                        label: 'Out of Stock',
                        value: '$outOfStockCount',
                        trend: 'Items',
                        color: AppColors.primary,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Quick Actions ─────────────────────────────────────────
                  Text('Quick Actions', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _ActionTile(
                        label: 'Orders',
                        icon: Icons.receipt_long,
                        color: AppColors.primary,
                        badge: activeOrders > 0 ? '$activeOrders' : null,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminOrdersScreen(),
                          ),
                        ),
                      ),
                      _ActionTile(
                        label: 'Products',
                        icon: Icons.inventory_2_outlined,
                        color: AppColors.success,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminProductsScreen(),
                          ),
                        ),
                      ),
                      _ActionTile(
                        label: 'Inventory',
                        icon: Icons.warehouse_outlined,
                        color: AppColors.primary,
                        badge: (lowStockCount + outOfStockCount) > 0
                            ? '${lowStockCount + outOfStockCount}'
                            : null,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminInventoryScreen(),
                          ),
                        ),
                      ),
                      _ActionTile(
                        label: 'Payments',
                        icon: Icons.payments_outlined,
                        color: AppColors.success,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminPaymentsScreen(),
                          ),
                        ),
                      ),
                      _ActionTile(
                        label: 'Analytics',
                        icon: Icons.show_chart,
                        color: AppColors.primary,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminAnalyticsScreen(),
                          ),
                        ),
                      ),
                      _ActionTile(
                        label: 'Delivery Zone',
                        icon: Icons.place_outlined,
                        color: AppColors.primary,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminDeliveryZoneScreen(),
                          ),
                        ),
                      ),
                      _ActionTile(
                        label: 'Settings',
                        icon: Icons.settings_outlined,
                        color: AppColors.success,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // ── Inventory Health ──────────────────────────────────────
                  if (products.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Inventory Health',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    _InventoryHealthBars(products: products),
                  ],

                  // ── Recent Orders ─────────────────────────────────────────
                  const SizedBox(height: 24),
                  Text('Recent Orders', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  if (ordersAsync.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (recentOrders.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'No orders yet.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    )
                  else
                    ...recentOrders
                        .take(5)
                        .map((o) => _RecentOrderTile(order: o)),

                  const SizedBox(height: 24),
                ],
              ),
      ),
    );
  }

  static String _fmtAmt(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }
}

// ── Reusable Widgets ───────────────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String trend;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.trend,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    return Container(
      width: (MediaQuery.of(context).size.width - 16 * 2 - 12) / 2,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
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
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              trend,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? badge;

  const _ActionTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final divColor = Theme.of(context).dividerColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: (MediaQuery.of(context).size.width - 16 * 2 - 12) / 2,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: divColor),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                if (badge != null)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        badge!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryHealthBars extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  const _InventoryHealthBars({required this.products});

  @override
  Widget build(BuildContext context) {
    final total = products.length;
    if (total == 0) return const SizedBox.shrink();
    final outOf = products
        .where((p) => ((p['stockQuantity'] ?? p['stock'] ?? 0) as int) == 0)
        .length;
    final low = products.where((p) {
      final q = (p['stockQuantity'] ?? p['stock'] ?? 0) as int;
      return q > 0 && q < 10;
    }).length;
    final healthy = total - outOf - low;
    return Column(
      children: [
        _AnalyticsBar(
          label: 'In stock',
          value: '${((healthy / total) * 100).toStringAsFixed(0)}%',
          percent: healthy / total,
          color: AppColors.success,
        ),
        const SizedBox(height: 8),
        _AnalyticsBar(
          label: 'Low stock',
          value: '${((low / total) * 100).toStringAsFixed(0)}%',
          percent: low / total,
          color: AppColors.primary,
        ),
        const SizedBox(height: 8),
        _AnalyticsBar(
          label: 'Out of stock',
          value: '${((outOf / total) * 100).toStringAsFixed(0)}%',
          percent: outOf / total,
          color: AppColors.slate500,
        ),
      ],
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
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: AppColors.slate500),
              ),
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

class _RecentOrderTile extends StatelessWidget {
  final Map<String, dynamic> order;
  const _RecentOrderTile({required this.order});

  Color _statusColor(String status) {
    switch (status) {
      case 'Delivered':
        return AppColors.success;
      case 'Accepted':
      case 'Ready':
      case 'On the way':
        return const Color(0xFF3B82F6);
      case 'Cancelled':
        return AppColors.slate500;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = (order['status'] ?? 'Pending') as String;
    final sc = _statusColor(status);
    final total = ((order['total'] ?? 0) as num).toDouble();
    final items = (order['items'] as List?)?.length ?? 0;
    final rawId = (order['id'] as String? ?? '');
    final shortId = rawId.length >= 8
        ? rawId.substring(0, 8).toUpperCase()
        : rawId.toUpperCase();
    final surface = Theme.of(context).colorScheme.surface;
    final divColor = Theme.of(context).dividerColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
            child: Icon(Icons.receipt_long, color: sc),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#$shortId',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '$items item${items != 1 ? 's' : ''}',
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
                  status,
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
