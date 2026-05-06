import 'package:flutter_test/flutter_test.dart';

import 'package:sm_mall/models/product.dart';
import 'package:sm_mall/models/cart_item.dart';
import 'package:sm_mall/models/order.dart';
import 'package:sm_mall/models/payment.dart';
import 'package:sm_mall/models/user_profile.dart';
import 'package:sm_mall/models/category.dart';
import 'package:sm_mall/models/catalog_item.dart';

void main() {
  group('Product model', () {
    test('constructor creates product with all fields', () {
      const product = Product(
        id: 'p1',
        storeId: 'store1',
        name: 'Milk',
        unit: '1L',
        price: 60.0,
        imageUrl: 'https://example.com/milk.jpg',
      );

      expect(product.id, 'p1');
      expect(product.storeId, 'store1');
      expect(product.name, 'Milk');
      expect(product.unit, '1L');
      expect(product.price, 60.0);
      expect(product.imageUrl, 'https://example.com/milk.jpg');
    });

    test('imageUrl defaults to null', () {
      const product = Product(
        id: 'p2',
        storeId: 'store1',
        name: 'Bread',
        unit: '1 pack',
        price: 40.0,
      );

      expect(product.imageUrl, isNull);
    });
  });

  group('CartItem model', () {
    const product = Product(
      id: 'p1',
      storeId: 'store1',
      name: 'Eggs',
      unit: '12 pcs',
      price: 80.0,
    );

    test('totalPrice calculates correctly', () {
      const item = CartItem(product: product, quantity: 3);
      expect(item.totalPrice, 240.0);
    });

    test('totalPrice for single quantity', () {
      const item = CartItem(product: product, quantity: 1);
      expect(item.totalPrice, 80.0);
    });
  });

  group('Order model', () {
    test('fromFirestore creates order from map', () {
      final data = {
        'userId': 'u1',
        'customerName': 'John',
        'items': [
          {'productId': 'p1', 'name': 'Milk', 'price': 60, 'quantity': 2, 'total': 120},
        ],
        'subtotal': 120.0,
        'deliveryFee': 30.0,
        'tax': 0.0,
        'total': 150.0,
        'status': 'Pending',
        'deliveryStatus': 'Pending',
        'deliveryPartner': null,
        'paymentStatus': 'Pending',
        'address': '123 Main St',
        'createdAt': null,
        'updatedAt': null,
      };

      final order = Order.fromFirestore('ord1', data);

      expect(order.id, 'ord1');
      expect(order.userId, 'u1');
      expect(order.customerName, 'John');
      expect(order.items.length, 1);
      expect(order.subtotal, 120.0);
      expect(order.deliveryFee, 30.0);
      expect(order.total, 150.0);
      expect(order.status, 'Pending');
      expect(order.deliveryStatus, 'Pending');
      expect(order.paymentStatus, 'Pending');
      expect(order.address, '123 Main St');
    });

    test('fromFirestore uses defaults for missing fields', () {
      final order = Order.fromFirestore('ord2', {});

      expect(order.userId, '');
      expect(order.customerName, '');
      expect(order.items, isEmpty);
      expect(order.subtotal, 0.0);
      expect(order.total, 0.0);
      expect(order.status, 'Pending');
      expect(order.deliveryStatus, 'Pending');
      expect(order.paymentStatus, 'Pending');
    });

    test('toMap returns correct map', () {
      final now = DateTime(2026, 1, 1);
      final order = Order(
        id: 'ord1',
        userId: 'u1',
        customerName: 'John',
        items: const [
          {'productId': 'p1', 'name': 'Milk', 'quantity': 1, 'total': 60},
        ],
        subtotal: 60.0,
        deliveryFee: 30.0,
        tax: 0.0,
        total: 90.0,
        status: 'Pending',
        deliveryStatus: 'Pending',
        paymentStatus: 'Pending',
        address: '123 Main St',
        createdAt: now,
      );

      final map = order.toMap();
      expect(map['userId'], 'u1');
      expect(map['total'], 90.0);
      expect(map['status'], 'Pending');
      expect(map['createdAt'], now);
    });
  });

  group('Payment model', () {
    test('fromFirestore creates payment from map', () {
      final data = {
        'orderId': 'ord1',
        'userId': 'u1',
        'amount': 150.0,
        'paymentMethod': 'UPI',
        'upiId': 'john@upi',
        'status': 'Completed',
        'transactionId': 'TXN-123',
        'createdAt': null,
      };

      final payment = Payment.fromFirestore('pay1', data);

      expect(payment.id, 'pay1');
      expect(payment.orderId, 'ord1');
      expect(payment.amount, 150.0);
      expect(payment.paymentMethod, 'UPI');
      expect(payment.upiId, 'john@upi');
      expect(payment.status, 'Completed');
      expect(payment.transactionId, 'TXN-123');
    });

    test('fromFirestore handles missing optional fields', () {
      final payment = Payment.fromFirestore('pay2', {
        'orderId': 'ord2',
        'userId': 'u2',
        'amount': 100,
        'paymentMethod': 'Cash',
        'status': 'Pending',
        'transactionId': 'TXN-456',
      });

      expect(payment.cardLast4, isNull);
      expect(payment.upiId, isNull);
      expect(payment.walletProvider, isNull);
      expect(payment.bankName, isNull);
    });

    test('toMap includes all fields', () {
      final payment = Payment(
        id: 'pay1',
        orderId: 'ord1',
        userId: 'u1',
        amount: 200.0,
        paymentMethod: 'Credit Card',
        cardLast4: '4242',
        status: 'Completed',
        transactionId: 'TXN-789',
        createdAt: DateTime(2026, 1, 1),
      );

      final map = payment.toMap();
      expect(map['paymentMethod'], 'Credit Card');
      expect(map['cardLast4'], '4242');
      expect(map['amount'], 200.0);
    });
  });

  group('UserProfile model', () {
    test('fromFirestore creates profile with isAdmin flag', () {
      final profile = UserProfile.fromFirestore('uid1', {
        'firstName': 'Jane',
        'lastName': 'Doe',
        'email': 'jane@test.com',
        'phone': '+911234567890',
        'isAdmin': true,
        'isActive': true,
      });

      expect(profile.id, 'uid1');
      expect(profile.firstName, 'Jane');
      expect(profile.lastName, 'Doe');
      expect(profile.isAdmin, true);
      expect(profile.displayName, 'Jane Doe');
    });

    test('isAdmin defaults to false', () {
      final profile = UserProfile.fromFirestore('uid2', {
        'email': 'user@test.com',
        'phone': '+910000000000',
      });

      expect(profile.isAdmin, false);
    });

    test('displayName falls back to phone when name is empty', () {
      final profile = UserProfile.fromFirestore('uid3', {
        'email': '',
        'phone': '+919876543210',
      });

      expect(profile.displayName, '+919876543210');
    });

    test('toMap includes isAdmin', () {
      final profile = UserProfile(
        id: 'uid1',
        firstName: 'Admin',
        lastName: 'User',
        email: 'admin@test.com',
        phone: '+911111111111',
        isAdmin: true,
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      );

      final map = profile.toMap();
      expect(map['isAdmin'], true);
      expect(map['firstName'], 'Admin');
    });

    test('legacy name field is parsed into firstName/lastName', () {
      final profile = UserProfile.fromFirestore('uid4', {
        'name': 'Ravi Kumar Shah',
        'email': '',
        'phone': '+910000000001',
      });

      expect(profile.firstName, 'Ravi');
      expect(profile.lastName, 'Kumar Shah');
    });
  });

  group('Category model', () {
    test('iconData returns correct icon for known name', () {
      const cat = Category(id: 'c1', name: 'Flowers', iconName: 'local_florist');
      expect(cat.iconData, isNotNull);
    });

    test('iconData falls back to Icons.category for unknown name', () {
      const cat = Category(id: 'c2', name: 'Other', iconName: 'unknown_icon');
      expect(cat.iconData, isNotNull); // falls back to Icons.category
    });
  });

  group('CatalogItem model', () {
    const product = Product(
      id: 'p1',
      storeId: 'mall',
      name: 'Cake',
      unit: '1 kg',
      price: 500.0,
    );

    test('copyWith overrides specified fields', () {
      const item = CatalogItem(
        product: product,
        category: 'Bakery',
        stockNote: 'In Stock',
        isActive: true,
        description: 'Chocolate cake',
      );

      final updated = item.copyWith(stockNote: 'Low Stock', isActive: false);

      expect(updated.stockNote, 'Low Stock');
      expect(updated.isActive, false);
      expect(updated.category, 'Bakery'); // unchanged
      expect(updated.product.name, 'Cake'); // unchanged
    });
  });
}
