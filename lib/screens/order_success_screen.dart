import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../widgets/primary_button.dart';
import 'order_tracking_screen.dart';

class OrderSuccessScreen extends StatelessWidget {
  final String orderId;

  const OrderSuccessScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.primary,
                  size: 56,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Congratulations!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your MallDash order has been confirmed.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.slate500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Order ID · ${orderId.substring(0, 8).toUpperCase()}',
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: AppColors.slate700),
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Track Order',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => OrderTrackingScreen(orderId: orderId),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: Text(
                  'Back to ${AppConstants.appName}',
                  style: const TextStyle(color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
