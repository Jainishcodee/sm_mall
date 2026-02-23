# Backend Integration Implementation Guide

## Overview

This guide covers the implementation of the new order, payment, and user profile management system. Follow these steps to integrate the new services into your app.

## 📦 New Files Created

1. **Models:**
   - `lib/models/order.dart` - Order data model
   - `lib/models/payment.dart` - Payment data model
   - `lib/models/user_profile.dart` - User profile data model

2. **Services:**
   - `lib/services/firestore_service_extensions.dart` - Extended Firestore operations

3. **Configuration:**
   - `firestore.rules` - Firebase security rules
   - `BACKEND_REVIEW.md` - Comprehensive backend review
   - `IMPLEMENTATION_GUIDE.md` - This file

## 🔧 Implementation Steps

### Step 1: Update FirestoreService

The main `FirestoreService` already exists. The new extension file (`firestore_service_extensions.dart`) contains additional methods. To use them:

```dart
// In any file that uses FirestoreService
import 'package:sm_mall/services/firestore_service.dart';
import 'package:sm_mall/services/firestore_service_extensions.dart';

// Now you can use all methods including:
final firestoreService = ref.read(firestoreServiceProvider);
final orderId = await firestoreService.createOrder(...);
```

### Step 2: Update Checkout Screen to Create Orders

**File:** `lib/screens/checkout_screen.dart`

Replace the current placeholder order creation with actual Firestore operations:

```dart
// Current code (line 60-65):
PrimaryButton(
  label: 'Place Order',
  onPressed: () {
    ref.read(cartProvider.notifier).clear();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const OrderSuccessScreen()),
      (route) => route.isFirst,
    );
  },
),

// Should become:
PrimaryButton(
  label: 'Place Order',
  onPressed: () async {
    final cartState = ref.watch(cartProvider);
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to place order')),
      );
      return;
    }

    final firestoreService = ref.read(firestoreServiceProvider);
    const deliveryFee = 30.0;
    final tax = (cartState.totalPrice + deliveryFee) * 0.075; // 7.5% tax

    try {
      // Create order
      final orderId = await firestoreService.createOrder(
        userId: user.uid,
        customerName: 'User', // Get from user profile
        items: cartState.items.values
            .map((item) => {
              'id': item.product.id,
              'name': item.product.name,
              'quantity': item.quantity,
              'price': item.product.price,
              'total': item.totalPrice,
            })
            .toList(),
        subtotal: cartState.totalPrice,
        deliveryFee: deliveryFee,
        tax: tax,
        total: cartState.totalPrice + deliveryFee + tax,
        status: 'Pending',
        paymentStatus: 'Pending',
        address: 'User Address', // Get from saved addresses
      );

      // Clear cart
      ref.read(cartProvider.notifier).clear();

      if (!mounted) return;
      
      // Navigate to payment screen (TODO: implement payment gateway)
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => OrderSuccessScreen(orderId: orderId),
        ),
        (route) => route.isFirst,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating order: $e')),
      );
    }
  },
),
```

### Step 3: Create Order History Screen

**New File:** `lib/screens/order_history_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/firestore_service.dart';
import '../models/order.dart';
import '../theme/app_colors.dart';

class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please login to view orders')),
      );
    }

    final firestoreService = ref.read(firestoreServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Order History')),
      body: StreamBuilder<List<Order>>(
        stream: firestoreService.streamUserOrders(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No orders yet'));
          }

          final orders = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return OrderListTile(order: order);
            },
          );
        },
      ),
    );
  }
}

class OrderListTile extends StatelessWidget {
  final Order order;

  const OrderListTile({required this.order, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text('Order #${order.id.substring(0, 8)}'),
        subtitle: Text(order.status),
        trailing: Text('₹${order.total.toStringAsFixed(2)}'),
        onTap: () {
          // Navigate to order details
        },
      ),
    );
  }
}
```

### Step 4: Setup Firebase Custom Claims for Admin

**One-time setup (run in Firebase Console):**

```javascript
// Go to Firebase Console > Functions and create a new function:
const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

exports.setAdminClaim = functions.https.onCall(async (data, context) => {
  const uid = data.uid;
  const isAdmin = data.isAdmin;

  try {
    await admin.auth().setCustomUserClaims(uid, { admin: isAdmin });
    return { message: 'Custom claims set successfully' };
  } catch (error) {
    throw new functions.https.HttpsError('internal', error.message);
  }
});
```

**Or use Firebase Console directly:**

1. Go to Firebase Console
2. Authentication > Users
3. Click on user
4. Custom claims > Click (add custom claim)
5. Add: `{"admin": true}`

### Step 5: Update OTP Screen

Remove bypass codes for production and add user profile creation:

```dart
// In _OtpScreenState._verifyOtp() after successful sign-in:

void _handleSignedIn(String phoneNumber) {
  final firestoreService = ref.read(firestoreServiceProvider);
  final user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    // Create user profile if doesn't exist
    firestoreService.createUserProfile(
      userId: user.uid,
      name: user.displayName ?? 'User',
      email: user.email ?? '',
      phone: phoneNumber,
    );
  }

  // Route based on admin status
  final isAdmin = last10Digits(phoneNumber) == AppConstants.adminPhone;
  
  // ... rest of navigation code
}
```

### Step 6: Deploy Firebase Rules

**Command to deploy rules:**

```bash
# From project root
firebase deploy --only firestore:rules
```

Or manually in Firebase Console:

1. Go to Firestore Database
2. Rules tab
3. Copy content from `firestore.rules`
4. Publish

### Step 7: Create Providers for New Streams

Add to `lib/providers/` a new file for order and payment providers:

**File:** `lib/providers/order_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/order.dart';
import '../services/firestore_service.dart';

// Stream user orders
final userOrdersStreamProvider = StreamProvider<List<Order>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value([]);
  
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamUserOrders(user.uid);
});

// Stream all orders (admin)
final allOrdersStreamProvider = StreamProvider<List<Order>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamAllOrders();
});

// User addresses stream
final userAddressesStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value([]);
  
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamUserAddresses(user.uid);
});
```

## 🔑 Key Methods Reference

### Order Methods

```dart
// Create order
final orderId = await firestoreService.createOrder(
  userId: 'user123',
  customerName: 'John Doe',
  items: [...],
  subtotal: 500.0,
  deliveryFee: 30.0,
  tax: 42.0,
  total: 572.0,
  status: 'Pending',
  paymentStatus: 'Pending',
  address: '123 Main St',
);

// Get single order
final order = await firestoreService.getOrder('order123');

// Get user orders
final orders = await firestoreService.getUserOrders('user123');

// Stream user orders
firestoreService.streamUserOrders('user123');

// Update order status (admin)
await firestoreService.updateOrderStatus('order123', 'Delivered');

// Update payment status
await firestoreService.updateOrderPaymentStatus('order123', 'Completed');

// Get order stats (admin)
final stats = await firestoreService.getOrderStats();
```

### Payment Methods

```dart
// Create payment
final paymentId = await firestoreService.createPayment(
  orderId: 'order123',
  userId: 'user123',
  amount: 572.0,
  paymentMethod: 'Credit Card',
  transactionId: 'TXN-12345',
  cardLast4: '2408',
);

// Get user payments
final payments = await firestoreService.getUserPayments('user123');

// Update payment status
await firestoreService.updatePaymentStatus('payment123', 'Completed');
```

### User Profile Methods

```dart
// Create profile
await firestoreService.createUserProfile(
  userId: 'user123',
  name: 'John Doe',
  email: 'john@email.com',
  phone: '+91 9408362739',
);

// Get profile
final profile = await firestoreService.getUserProfile('user123');

// Update profile
await firestoreService.updateUserProfile(
  userId: 'user123',
  name: 'Jane Doe',
  email: 'jane@email.com',
);

// Add address
final addressId = await firestoreService.addOrUpdateAddress(
  userId: 'user123',
  label: 'Home',
  address: '123 Main St, City',
  latitude: 12.34,
  longitude: 56.78,
  isDefault: true,
);

// Get addresses
final addresses = await firestoreService.getUserAddresses('user123');

// Delete address
await firestoreService.deleteAddress('user123', 'address123');
```

## 🧪 Testing Checklist

- [ ] Create order from checkout (verify in Firestore)
- [ ] View order history (users see own, admin sees all)
- [ ] Update order status as admin
- [ ] Create payment record
- [ ] View payment history
- [ ] Create user addresses
- [ ] List user addresses
- [ ] Delete addresses
- [ ] Test security rules (non-admin can't create products)
- [ ] Test security rules (user can't view other user's orders)

## 🐛 Common Issues & Solutions

### Issue: "FirestoreService not found"
**Solution:** Make sure to import the service file properly:
```dart
import 'package:sm_mall/services/firestore_service.dart';
import 'package:sm_mall/services/firestore_service_extensions.dart';
```

### Issue: "Permission denied" when creating orders
**Solution:** 
1. Check Firebase rules are deployed
2. User must be authenticated (not null)
3. Check Firestore rules in console

### Issue: Orders not saving
**Solution:**
1. Check internet connection
2. Verify Firebase project ID is correct
3. Check Firestore quota hasn't been exceeded
4. See Firebase console for detailed errors

## 📋 Next Steps

1. Integrate payment gateway (Stripe/Razorpay)
2. Add order notifications
3. Implement real-time tracking
4. Add admin analytics
5. Create review system
6. Setup email notifications

## 📚 Additional Resources

- [Firestore Documentation](https://firebase.flutter.dev/docs/firestore/usage)
- [Firebase Security Rules](https://firebase.google.com/docs/rules)
- [Riverpod Documentation](https://riverpod.dev/)
- [Flutter Streams](https://dart.dev/guides/libraries/async-await)

---

**Document Version:** 1.0  
**Last Updated:** 2024-02-17  
**Status:** Ready for Implementation
