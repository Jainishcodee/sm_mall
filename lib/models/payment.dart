class Payment {
  final String id;
  final String orderId;
  final String userId;
  final double amount;
  final String
  paymentMethod; // Credit Card, Debit Card, UPI, Wallet, Net Banking
  final String? cardLast4;
  final String? upiId;
  final String? walletProvider;
  final String? bankName;
  final String status; // Pending, Completed, Failed
  final String transactionId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Payment({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    required this.transactionId,
    required this.createdAt,
    this.cardLast4,
    this.upiId,
    this.walletProvider,
    this.bankName,
    this.updatedAt,
  });

  factory Payment.fromFirestore(String id, Map<String, dynamic> data) {
    return Payment(
      id: id,
      orderId: data['orderId'] ?? '',
      userId: data['userId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      paymentMethod: data['paymentMethod'] ?? '',
      cardLast4: data['cardLast4'],
      upiId: data['upiId'],
      walletProvider: data['walletProvider'],
      bankName: data['bankName'],
      status: data['status'] ?? 'Pending',
      transactionId: data['transactionId'] ?? '',
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as dynamic)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'userId': userId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'cardLast4': cardLast4,
      'upiId': upiId,
      'walletProvider': walletProvider,
      'bankName': bankName,
      'status': status,
      'transactionId': transactionId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
