import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AdminOrderDetailScreen extends StatefulWidget {
  final String orderId;

  const AdminOrderDetailScreen({super.key, required this.orderId});

  @override
  State<AdminOrderDetailScreen> createState() => _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState extends State<AdminOrderDetailScreen> {
  String selectedPartner = 'Ravi (Bike)';
  String selectedStatus = 'Accepted';
  bool paymentCaptured = false;

  final partners = const [
    'Ravi (Bike)',
    'Neel (Scooter)',
    'Aisha (Bike)',
    'Sameer (Car)',
  ];

  final statuses = const [
    'Accepted',
    'Preparing',
    'Ready',
    'Picked up',
    'On the way',
    'Delivered',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${widget.orderId}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            title: 'Customer',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(label: 'Name', value: 'Riya Mehta'),
                _InfoRow(label: 'Phone', value: '+91 98765 43210'),
                _InfoRow(
                    label: 'Address',
                    value: 'Prime Residency, 80 ft road'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Order Summary',
            child: Column(
              children: const [
                _InfoRow(label: 'Items', value: '4'),
                _InfoRow(label: 'Subtotal', value: 'Rs 520'),
                _InfoRow(label: 'Delivery fee', value: 'Rs 20'),
                _InfoRow(label: 'Total', value: 'Rs 540'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Assign Delivery Partner',
            child: DropdownButtonFormField<String>(
              value: selectedPartner,
              items: partners
                  .map(
                    (partner) => DropdownMenuItem(
                      value: partner,
                      child: Text(partner),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => selectedPartner = value);
                }
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Update Delivery Status',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: statuses
                  .map(
                    (status) => ChoiceChip(
                      label: Text(status),
                      selected: selectedStatus == status,
                      selectedColor: AppColors.success.withOpacity(0.16),
                      labelStyle: TextStyle(
                        color: selectedStatus == status
                            ? AppColors.success
                            : AppColors.slate700,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (_) => setState(() => selectedStatus = status),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Payment',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(
                  label: 'Method',
                  value: 'Cash on delivery',
                ),
                _InfoRow(
                  label: 'Status',
                  value: paymentCaptured ? 'Paid' : 'Pending',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            setState(() => paymentCaptured = true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Mark Paid'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Collect Cash'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text('Confirm Delivery'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
  });

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
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
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
