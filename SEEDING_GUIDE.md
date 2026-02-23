# Database Seeding Guide

## Overview

The `seed_all_collections.dart` file provides comprehensive sample data for all Firestore collections in the SM Mall application.

## Collections Seeded

### 1. **Categories** (16 items)
- Fruits & Veg
- Dairy & Bread
- Snacks
- Bakery
- Breakfast
- Tea & Coffee
- Cold Drinks
- Sweet Tooth
- Atta & Rice
- Masala & Oil
- Sauces
- Chicken & Meat
- Cleaning
- Home & Office
- Personal Care
- Pet Care

**Fields:** id, name, iconName, isActive, createdAt

### 2. **Stores** (5 items)
- Fresh Mart Express
- Quick Bakery
- Mega Supermarket
- Premium Food Store
- Health & Wellness

**Fields:** id, name, category, rating, eta, description, isActive, createdAt

### 3. **Products** (40+ items)
Sample products across all categories with realistic pricing and details.

**Fields:** name, category, storeId, price, unit, stockNote, isActive, description, createdAt

### 4. **Users** (5 test users)
- Amit Shah
- Neha Patel
- Riya Mehta
- Dev Joshi
- Pooja Verma

**Fields:** id, name, email, phone, isActive, createdAt

### 5. **Addresses** (6 addresses)
Delivery addresses linked to users with geolocation data.

**Fields:** userId, label, address, latitude, longitude, isDefault, createdAt

**Location:** `users/{userId}/addresses/{addressId}`

### 6. **Orders** (5 sample orders)
Complete order data with multiple items, pricing breakdown, and status tracking.

**Fields:** userId, customerName, items, subtotal, deliveryFee, tax, total, status, paymentStatus, address, createdAt

**Status Options:** Pending, Accepted, Ready, On the way, Delivered

### 7. **Payments** (5 payment records)
Payment records linked to orders with different payment methods.

**Fields:** orderId, userId, amount, paymentMethod, status, transactionId, createdAt

**Payment Methods:** Credit Card, Debit Card, UPI, Wallet, Net Banking

## How to Run

### Option 1: Using Flutter (Recommended)

```bash
# Navigate to project root
cd g:\Project\SGP-6\SM\ Mall\sm_mall

# Run the seed script
flutter pub run tool/seed_all_collections.dart
```

### Option 2: Using Dart CLI

```bash
# Navigate to tool directory
cd g:\Project\SGP-6\SM\ Mall\sm_mall\tool

# Run the script
dart seed_all_collections.dart
```

### Option 3: Using Command Line in Project Root

```bash
# Make sure Firebase credentials are configured
# Run with proper imports
dart run tool/seed_all_collections.dart
```

## Important Notes

1. **Firebase Configuration**: Make sure your `firebase_options.dart` is properly configured with your Firebase project credentials.

2. **Batch Size**: The script uses Firestore batch operations with a limit of 100 per batch. Products are committed in batches for better performance.

3. **Timestamps**: All records include a server-side timestamp for creation date tracking.

4. **Data Merging**: Uses `SetOptions(merge: true)` for categories and other collections to prevent overwriting existing data accidentally.

5. **Sample Images**: The current seed data doesn't include image URLs. You can add them later by:
   - Uploading images to Firebase Storage
   - Updating product documents with imageUrl field

## Sample Data Relationships

- **Categories → Products**: Products reference categories via `category` field
- **Stores → Products**: Products belong to stores via `storeId` field
- **Users → Addresses**: Addresses are stored as subcollections under users
- **Orders → Items**: Order documents contain embedded item arrays
- **Payments → Orders**: Payments reference orders via `orderId` field
- **Orders → Users**: Orders reference users via `userId` field

## Data Statistics

- Total Documents: ~70+ documents
- Collections: 7 main collections
- Subcollections: 1 (addresses under users)
- Sample Test Accounts: 5 users ready for testing

## Testing the Seed

After running the seed script:

1. Open Firebase Console
2. Go to Cloud Firestore
3. Verify collections appear with data
4. Check sample order flow through checkout
5. Test admin analytics with seeded data

## Customization

You can easily modify the seed data by:

1. Changing product names, prices, and descriptions
2. Adding/removing categories
3. Modifying user information
4. Adjusting order statuses
5. Adding more sample data as needed

Simply edit the respective function and re-run the script.

## Troubleshooting

**Error: "Flutter not found"**
- Make sure Flutter is in your PATH
- Install Flutter SDK if not already installed

**Error: "Firebase not initialized"**
- Verify firebase_options.dart exists
- Check Firebase project settings in Firebase Console
- Ensure you have internet connection

**Error: "Permission denied"**
- Check Firestore security rules
- Make sure rules allow write operations
- Verify Firebase authentication is set up

**Duplicate Data**
- The script uses merge operations
- To completely refresh, delete collections in Firebase Console first
- Then run the seed script

## Additional Resources

- [Firestore Documentation](https://firebase.google.com/docs/firestore)
- [Flutter Firebase Setup](https://firebase.flutter.dev/)
- [Firestore Best Practices](https://firebase.google.com/docs/firestore/best-practices)
