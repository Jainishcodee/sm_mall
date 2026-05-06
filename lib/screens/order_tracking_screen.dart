import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme/app_colors.dart';

class OrderTrackingScreen extends StatelessWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  static const _steps = [
    _TrackingStepData(
      title: 'Order Confirmed',
      subtitle: 'Your order has been placed',
      icon: Icons.receipt_long_rounded,
    ),
    _TrackingStepData(
      title: 'Partner Assigned',
      subtitle: 'Delivery partner is on the way to pick up',
      icon: Icons.person_pin_circle_rounded,
    ),
    _TrackingStepData(
      title: 'Picked Up',
      subtitle: 'Your order has been picked up from the store',
      icon: Icons.shopping_bag_rounded,
    ),
    _TrackingStepData(
      title: 'On the Way',
      subtitle: 'Your delivery partner is heading to you',
      icon: Icons.delivery_dining_rounded,
    ),
    _TrackingStepData(
      title: 'Delivered',
      subtitle: 'Your order has been delivered!',
      icon: Icons.check_circle_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Track Order',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            Text(
              '#${orderId.substring(0, 8).toUpperCase()}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.slate400,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
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
          final isDelivered = activeStep >= 4;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // ── Live status hero card ──
                _LiveStatusCard(
                  status: status,
                  deliveryStatus: deliveryStatus,
                  partner: partner,
                  isDelivered: isDelivered,
                ),
                const SizedBox(height: 20),

                // ── Vertical timeline ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Order Timeline',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.slate900,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ...List.generate(_steps.length, (i) {
                        final isDone = i < activeStep;
                        final isCurrent = i == activeStep;
                        final isLast = i == _steps.length - 1;
                        return _TimelineStep(
                          data: _steps[i],
                          isDone: isDone,
                          isCurrent: isCurrent,
                          isLast: isLast,
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Help / support card ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.headset_mic_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Need help with your order?',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppColors.slate900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'We\'re here to assist you',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.slate400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Help',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
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
    if (orderStatus == 'Delivered' || deliveryStatus == 'Delivered') return 4;
    switch (deliveryStatus) {
      case 'On the way':
        return 3;
      case 'Picked up':
        return 2;
      case 'Assigned':
        return 1;
      default:
        // Order is confirmed but no delivery action yet.
        if (orderStatus == 'Accepted' || orderStatus == 'Ready') return 1;
        return 0;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────
// Live status hero card
// ─────────────────────────────────────────────────────────────────────

class _LiveStatusCard extends StatefulWidget {
  final String status;
  final String deliveryStatus;
  final String partner;
  final bool isDelivered;

  const _LiveStatusCard({
    required this.status,
    required this.deliveryStatus,
    required this.partner,
    required this.isDelivered,
  });

  @override
  State<_LiveStatusCard> createState() => _LiveStatusCardState();
}

class _LiveStatusCardState extends State<_LiveStatusCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _dotCtrl;

  @override
  void initState() {
    super.initState();
    _dotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    if (!widget.isDelivered) _dotCtrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _LiveStatusCard old) {
    super.didUpdateWidget(old);
    if (widget.isDelivered && _dotCtrl.isAnimating) {
      _dotCtrl.stop();
    } else if (!widget.isDelivered && !_dotCtrl.isAnimating) {
      _dotCtrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _dotCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDelivered
        ? AppColors.success
        : AppColors.primary;

    final statusLabel = widget.isDelivered
        ? 'Delivered'
        : widget.deliveryStatus;

    final emoji = widget.isDelivered
        ? '🎉'
        : widget.deliveryStatus == 'On the way'
            ? '🛵'
            : widget.deliveryStatus == 'Picked up'
                ? '📦'
                : '🍽️';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bgColor, bgColor.withValues(alpha: 0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: bgColor.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          statusLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (!widget.isDelivered) ...[
                          const SizedBox(width: 8),
                          AnimatedBuilder(
                            animation: _dotCtrl,
                            builder: (context, _) => Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(
                                  alpha: 0.5 + _dotCtrl.value * 0.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.isDelivered
                          ? 'Your order has arrived!'
                          : widget.partner.isNotEmpty
                              ? '${widget.partner} is handling your order'
                              : 'Preparing your order...',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!widget.isDelivered) ...[
            const SizedBox(height: 16),
            // Animated progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _progressValue(widget.deliveryStatus),
                minHeight: 5,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation(Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }

  double _progressValue(String deliveryStatus) {
    switch (deliveryStatus) {
      case 'Assigned':
        return 0.25;
      case 'Picked up':
        return 0.5;
      case 'On the way':
        return 0.75;
      case 'Delivered':
        return 1.0;
      default:
        return 0.1;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────
// Vertical timeline step
// ─────────────────────────────────────────────────────────────────────

class _TimelineStep extends StatefulWidget {
  final _TrackingStepData data;
  final bool isDone;
  final bool isCurrent;
  final bool isLast;

  const _TimelineStep({
    required this.data,
    required this.isDone,
    required this.isCurrent,
    required this.isLast,
  });

  @override
  State<_TimelineStep> createState() => _TimelineStepState();
}

class _TimelineStepState extends State<_TimelineStep>
    with SingleTickerProviderStateMixin {
  late AnimationController _ringCtrl;

  @override
  void initState() {
    super.initState();
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    if (widget.isCurrent) _ringCtrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _TimelineStep old) {
    super.didUpdateWidget(old);
    if (widget.isCurrent && !_ringCtrl.isAnimating) {
      _ringCtrl.repeat(reverse: true);
    } else if (!widget.isCurrent && _ringCtrl.isAnimating) {
      _ringCtrl.stop();
      _ringCtrl.reset();
    }
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color iconColor;
    final Color bgColor;

    if (widget.isDone) {
      iconColor = Colors.white;
      bgColor = AppColors.success;
    } else if (widget.isCurrent) {
      iconColor = Colors.white;
      bgColor = AppColors.primary;
    } else {
      iconColor = AppColors.slate400;
      bgColor = const Color(0xFFF3F4F6);
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Left: dot + connecting line ──
          SizedBox(
            width: 40,
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _ringCtrl,
                  builder: (context, child) {
                    final showRing = widget.isCurrent;
                    return Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: bgColor,
                        border: showRing
                            ? Border.all(
                                color: AppColors.primary.withValues(
                                  alpha: 0.3 + _ringCtrl.value * 0.4,
                                ),
                                width: 3,
                              )
                            : null,
                        boxShadow: widget.isCurrent
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        widget.data.icon,
                        size: 18,
                        color: iconColor,
                      ),
                    );
                  },
                ),
                if (!widget.isLast)
                  Expanded(
                    child: Container(
                      width: 2.5,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: widget.isDone
                            ? AppColors.success.withValues(alpha: 0.4)
                            : AppColors.slate200,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // ── Right: text content ──
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: widget.isLast ? 0 : 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Text(
                    widget.data.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: (widget.isDone || widget.isCurrent)
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: (widget.isDone || widget.isCurrent)
                          ? AppColors.slate900
                          : AppColors.slate400,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.data.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: (widget.isDone || widget.isCurrent)
                          ? AppColors.slate500
                          : AppColors.slate300,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Step data model
// ─────────────────────────────────────────────────────────────────────

class _TrackingStepData {
  final String title;
  final String subtitle;
  final IconData icon;

  const _TrackingStepData({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}
