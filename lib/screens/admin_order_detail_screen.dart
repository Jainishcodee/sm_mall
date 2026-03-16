import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AdminOrderDetailScreen extends StatefulWidget {
  final String orderId;

  const AdminOrderDetailScreen({super.key, required this.orderId});

  @override
  State<AdminOrderDetailScreen> createState() => _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState extends State<AdminOrderDetailScreen> {
  static const _deliveryPartners = [
    'Ravi (Bike)',
    'Neel (Scooter)',
    'Aisha (Bike)',
    'Sameer (Car)',
  ];

  static const _orderStatuses = [
    'Pending',
    'Accepted',
    'Ready',
    'On the way',
    'Delivered',
    'Cancelled',
  ];

  static const _deliveryStatuses = [
    'Pending',
    'Assigned',
    'Picked up',
    'On the way',
    'Delivered',
  ];

  Future<void> _updateField(String key, dynamic value) async {
    final update = <String, dynamic>{
      key: value,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (key == 'deliveryStatus' && value == 'Delivered') {
      update['status'] = 'Delivered';
    }

    await FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .update(update);
  }

  Future<void> _markPaid() async {
    await FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .update({
          'paymentStatus': 'Completed',
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${widget.orderId.substring(0, 8).toUpperCase()}'),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(widget.orderId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Failed to load order: ${snapshot.error}'),
            );
          }

          final data = snapshot.data?.data();
          if (data == null) {
            return const Center(child: Text('Order not found.'));
          }

          final customerName = (data['customerName'] ?? 'Customer').toString();
          final address = (data['address'] ?? '-').toString();
          final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
          final subtotal = ((data['subtotal'] ?? 0) as num).toDouble();
          final deliveryFee = ((data['deliveryFee'] ?? 0) as num).toDouble();
          final total = ((data['total'] ?? 0) as num).toDouble();
          final paymentStatus = (data['paymentStatus'] ?? 'Pending').toString();
          final selectedPartner = ((data['deliveryPartner'] ?? '') as String)
              .trim();
          final selectedStatus = (data['status'] ?? 'Pending').toString();
          final selectedDeliveryStatus = (data['deliveryStatus'] ?? 'Pending')
              .toString();

          final partnerValue = _deliveryPartners.contains(selectedPartner)
              ? selectedPartner
              : null;
          final statusValue = _orderStatuses.contains(selectedStatus)
              ? selectedStatus
              : _orderStatuses.first;
          final deliveryStatusValue =
              _deliveryStatuses.contains(selectedDeliveryStatus)
              ? selectedDeliveryStatus
              : _deliveryStatuses.first;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SectionCard(
                title: 'Customer',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(label: 'Name', value: customerName),
                    _InfoRow(label: 'Address', value: address),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Order Summary',
                child: Column(
                  children: [
                    _InfoRow(label: 'Items', value: '${items.length}'),
                    _InfoRow(
                      label: 'Subtotal',
                      value: 'Rs ${subtotal.toStringAsFixed(0)}',
                    ),
                    _InfoRow(
                      label: 'Delivery fee',
                      value: 'Rs ${deliveryFee.toStringAsFixed(0)}',
                    ),
                    _InfoRow(
                      label: 'Total',
                      value: 'Rs ${total.toStringAsFixed(0)}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Assign Delivery Partner',
                child: DropdownButtonFormField<String>(
                  value: partnerValue,
                  items: _deliveryPartners
                      .map(
                        (partner) => DropdownMenuItem(
                          value: partner,
                          child: Text(partner),
                        ),
                      )
                      .toList(),
                  onChanged: (value) async {
                    if (value == null) {
                      return;
                    }
                    await FirebaseFirestore.instance
                        .collection('orders')
                        .doc(widget.orderId)
                        .update({
                          'deliveryPartner': value,
                          if (selectedDeliveryStatus == 'Pending')
                            'deliveryStatus': 'Assigned',
                          'updatedAt': FieldValue.serverTimestamp(),
                        });
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
                title: 'Update Order Status',
                child: DropdownButtonFormField<String>(
                  value: statusValue,
                  items: _orderStatuses
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ),
                      )
                      .toList(),
                  onChanged: (value) async {
                    if (value == null) {
                      return;
                    }
                    await FirebaseFirestore.instance
                        .collection('orders')
                        .doc(widget.orderId)
                        .update({
                          'status': value,
                          if (value == 'Delivered')
                            'deliveryStatus': 'Delivered',
                          'updatedAt': FieldValue.serverTimestamp(),
                        });
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
                  children: _deliveryStatuses
                      .map(
                        (status) => ChoiceChip(
                          label: Text(status),
                          selected: deliveryStatusValue == status,
                          selectedColor: AppColors.success.withOpacity(0.16),
                          labelStyle: TextStyle(
                            color: deliveryStatusValue == status
                                ? AppColors.success
                                : AppColors.slate700,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (_) =>
                              _updateField('deliveryStatus', status),
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
                    _InfoRow(label: 'Status', value: paymentStatus),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: paymentStatus == 'Completed'
                            ? null
                            : _markPaid,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          paymentStatus == 'Completed'
                              ? 'Already Paid'
                              : 'Mark Paid',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

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
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
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

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: AppColors.slate500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
