class Order {
  final String id;
  final String userId;
  final String customerName;
  final List<Map<String, dynamic>> items;
  final double subtotal;
  final double deliveryFee;
  final double tax;
  final double total;
  final String status; // Pending, Accepted, Ready, On the way, Delivered
  final String paymentStatus; // Pending, Completed, Failed
  final String address;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Order({
    required this.id,
    required this.userId,
    required this.customerName,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.tax,
    required this.total,
    required this.status,
    required this.paymentStatus,
    required this.address,
    required this.createdAt,
    this.updatedAt,
  });

  factory Order.fromFirestore(String id, Map<String, dynamic> data) {
    return Order(
      id: id,
      userId: data['userId'] ?? '',
      customerName: data['customerName'] ?? '',
      items: List<Map<String, dynamic>>.from(data['items'] ?? []),
      subtotal: (data['subtotal'] ?? 0).toDouble(),
      deliveryFee: (data['deliveryFee'] ?? 0).toDouble(),
      tax: (data['tax'] ?? 0).toDouble(),
      total: (data['total'] ?? 0).toDouble(),
      status: data['status'] ?? 'Pending',
      paymentStatus: data['paymentStatus'] ?? 'Pending',
      address: data['address'] ?? '',
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as dynamic)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'customerName': customerName,
      'items': items,
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'tax': tax,
      'total': total,
      'status': status,
      'paymentStatus': paymentStatus,
      'address': address,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
