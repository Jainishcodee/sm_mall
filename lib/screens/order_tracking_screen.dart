import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme/app_colors.dart';
import '../widgets/progress_stepper.dart';

class OrderTrackingScreen extends StatelessWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Track Order #${orderId.substring(0, 8).toUpperCase()}'),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading order: ${snapshot.error}'),
            );
          }
          final data = snapshot.data?.data();
          if (data == null) {
            return const Center(child: Text('Order not found.'));
          }

          final status = (data['status'] ?? 'Pending') as String;
          final deliveryStatus =
              (data['deliveryStatus'] ?? 'Pending') as String;
          final partner = (data['deliveryPartner'] ?? '') as String;
          final activeStep = _trackingStep(deliveryStatus, status);

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ProgressStepper(
                  currentStep: activeStep,
                  steps: const [
                    'Assigned',
                    'Picked up',
                    'On the way',
                    'Delivered',
                  ],
                ),
                const SizedBox(height: 20),
                _StatusCard(
                  title: 'Delivery Status: $deliveryStatus',
                  subtitle: partner.isEmpty
                      ? 'Partner assignment pending'
                      : 'Delivery partner: $partner',
                  icon: Icons.delivery_dining,
                ),
                const SizedBox(height: 14),
                _StatusCard(
                  title: 'Order Status: $status',
                  subtitle: 'Live updates are synced from admin panel.',
                  icon: Icons.notifications_active,
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order timeline',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        _TimelineItem(
                          title: 'Order confirmed',
                          time: '-',
                          isActive: true,
                        ),
                        _TimelineItem(
                          title: 'Delivery partner assigned',
                          time: '-',
                          isActive: activeStep >= 0,
                        ),
                        _TimelineItem(
                          title: 'Picked up',
                          time: '-',
                          isActive: activeStep >= 1,
                        ),
                        _TimelineItem(
                          title: 'On the way',
                          time: '-',
                          isActive: activeStep >= 2,
                        ),
                        _TimelineItem(
                          title: 'Delivered',
                          time: '-',
                          isActive: activeStep >= 3,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  int _trackingStep(String deliveryStatus, String orderStatus) {
    if (orderStatus == 'Delivered' || deliveryStatus == 'Delivered') {
      return 3;
    }
    switch (deliveryStatus) {
      case 'Assigned':
        return 0;
      case 'Picked up':
        return 1;
      case 'On the way':
        return 2;
      default:
        return 0;
    }
  }
}

class _StatusCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _StatusCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.slate500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String title;
  final String time;
  final bool isActive;

  const _TimelineItem({
    required this.title,
    required this.time,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : AppColors.slate200,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isActive ? AppColors.slate900 : AppColors.slate500,
              ),
            ),
          ),
          Text(
            time,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppColors.slate500),
          ),
        ],
      ),
    );
  }
}
