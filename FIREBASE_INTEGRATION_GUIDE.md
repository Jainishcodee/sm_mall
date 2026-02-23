# Firebase Integration Guide

## ✅ Completed Implementation

### 1. **Firebase Setup & Dependencies**
- ✅ Added Firebase Core, Auth, Firestore, Storage, and Image Picker to `pubspec.yaml`
- ✅ Configured Gradle for Firebase (google-services plugin)
- ✅ Created Firebase configuration files with placeholders (user to fill)
  - `lib/firebase_options.dart` - Platform-specific config
  - `android/app/google-services.json` - Android config
  - `ios/Runner/GoogleService-Info.plist` - iOS config

### 2. **Firebase Auth (Phone OTP)**
- ✅ Integrated Firebase Phone Authentication in `login_screen.dart`
- ✅ OTP verification in `otp_screen.dart` with Firebase Phone Auth Provider
- ✅ Phone number normalization (`lib/utils/phone_utils.dart`)
  - Converts various formats to +91XXXXXXXXXX (India)
  - Extracts last 10 digits for admin detection
- ✅ Admin Routing Logic: Only phone number ending with "9408362739" routes to AdminDashboardScreen; all others go to HomeScreen

### 3. **Firestore Integration**
- ✅ Created `FirestoreService` (`lib/services/firestore_service.dart`)
  - addProduct() - Add new products
  - updateProduct() - Edit existing products
  - deleteProduct() - Delete products
  - streamActiveProducts() - Real-time stream of active products
  - streamStoreProducts(storeId) - Real-time stream of store-specific products
- ✅ Firestore schema ready:
  ```
  Collection: products
  Fields: name, category, price, unit, stockNote, isActive, description, 
          imageUrl, storeId, createdAt, updatedAt
  ```

### 4. **Firebase Storage Integration**
- ✅ Created `StorageService` (`lib/services/storage_service.dart`)
  - uploadProductImage() - Upload product images, returns download URL
  - deleteProductImage() - Delete images by URL
- ✅ Storage path: `products/{productId}/{timestamp}.jpg`

### 5. **Admin Product Form - Image Upload**
- ✅ Modified `admin_product_form_screen.dart`
  - Added image picker UI (gallery selection)
  - Shows image preview after selection
  - Upload image to Firebase Storage before saving product
  - Save product details to Firestore (not mock data anymore)
  - Delete confirmation dialog for products
  - Loading state with spinner during upload/save
- ✅ Works for both Add and Edit modes

### 6. **Composite Provider System**
- ✅ Created fallback providers in `catalog_provider.dart`
  - `activeProductsProvider` - Firestore products with mock fallback
  - `storeProductsCompositeProvider` - Store-specific products with fallback
- ✅ Graceful degradation: If Firestore unavailable/empty, uses mock catalog

### 7. **Permissions**
- ✅ Added iOS permissions: NSPhotoLibraryUsageDescription, NSCameraUsageDescription
- ✅ Android permissions already configured for camera/gallery

---

## ⚙️ Configuration Required (User Must Do)

### Step 1: Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create new project (or use existing)
3. Enable these services:
   - **Authentication** → Enable Phone Number sign-in
   - **Firestore Database** → Create in test mode (or with security rules)
   - **Storage** → Create storage bucket

### Step 2: Download Configuration Files
1. **Android Configuration:**
   - In Firebase Console → Project Settings → Service Accounts → Google Services JSON
   - Download google-services.json
   - Replace content of `android/app/google-services.json`

2. **iOS Configuration:**
   - In Firebase Console → Project Settings → iOS app config
   - Download GoogleService-Info.plist
   - Replace content of `ios/Runner/GoogleService-Info.plist`

3. **Web/Multi-platform Configuration:**
   - Copy Web API Key and other credentials from Firebase Console
   - Update `lib/firebase_options.dart` with real values (replace all REPLACE_WITH_* placeholders)
   - Required values: apiKey, appId, messagingSenderId, projectId, storageBucket

### Step 3: Google Maps API Key (Optional but Recommended)
If using location features:
1. Enable Google Maps API in Google Cloud Console
2. Create API key for Android and iOS
3. Update locations:
   - **Android:** `android/app/src/main/AndroidManifest.xml` (line 9-10)
   - **iOS:** `ios/Runner/Runner/GeneratedPluginRegistrant.m` or `ios/Runner/AppDelegate.swift`

---

## 📋 Pending Tasks

### Priority 1: Update Product Listing Screens (⏳ Not Started)
Update HomeScreen, CategoriesScreen, and StoreScreen to use Firestore streams:

```dart
// Instead of:
final products = ref.watch(productsProvider);

// Use:
final productsAsync = ref.watch(activeProductsProvider);

// And handle AsyncValue:
productsAsync.when(
  data: (products) => ProductGrid(products: products),
  loading: () => const LoadingWidget(),
  error: (err, stack) => ErrorWidget(error: err),
);
```

**Files to modify:**
- `lib/screens/home_screen.dart`
- `lib/screens/categories_screen.dart`
- `lib/screens/store_screen.dart`

**Also update:**
- ProductCard widget to display imageUrl from Firestore (if available)
- Handle missing/null images gracefully (show placeholder)

### Priority 2: Test Complete Flow (⏳ Not Started)

When Firebase config is filled in:

1. **Test App Launch**
   ```bash
   flutter pub get
   flutter run
   ```

2. **Test Phone Auth Flow**
   - Open app, go to login
   - Enter test phone number (or provide real number if Firebase SMS enabled)
   - Verify OTP screen appears
   - Enter OTP (Firebase Console → Authentication → Phone - shows test OTP)
   - Verify routing: test number '9408362739' → Admin Dashboard, others → User Home

3. **Test Admin Product Add**
   - Login with number ending in 9408362739
   - Go to Admin Dashboard → Add Product
   - Fill form, pick image, click Add Product
   - Verify: Image uploads to Firebase Storage, product appears in Firestore
   - Refresh app, verify product still shows (persisted to Firestore)

4. **Test User Home**
   - Login with different phone number
   - Go to Home, verify products from Firestore appear (or mock fallback if empty)
   - Verify product images load correctly

5. **Test Edit/Delete**
   - Login as admin
   - Edit existing product (change image/details)
   - Verify Firestore updated, old image deleted
   - Delete product, verify removed from Firestore

### Priority 3: Error Handling & Loading States (⏳ Not Started)
- Add error handling UI for Firestore stream failures
- Show loading skeleton while products load
- Add retry buttons for failed loads
- Add no-products empty state

### Priority 4: Firestore Security Rules (⏳ Not Started)
Set up proper security rules in Firestore:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Admin-only writes
    match /products/{productId} {
      allow read: if true;
      allow create, update, delete: if request.auth.token.phone_number.endsWith('9408362739');
    }
  }
}
```

---

## 🔑 Key Code Locations

| Component | Location | Status |
|-----------|----------|--------|
| Firebase Options | `lib/firebase_options.dart` | ⏳ User fills placeholders |
| Phone Auth | `lib/screens/login_screen.dart` | ✅ Complete |
| OTP Verification | `lib/screens/otp_screen.dart` | ✅ Complete |
| Phone Utils | `lib/utils/phone_utils.dart` | ✅ Complete |
| Firestore Service | `lib/services/firestore_service.dart` | ✅ Complete |
| Storage Service | `lib/services/storage_service.dart` | ✅ Complete |
| Admin Product Form | `lib/screens/admin_product_form_screen.dart` | ✅ Complete |
| Product Providers | `lib/providers/catalog_provider.dart` | ✅ Updated with composite |

---

## 🧪 Test Credentials

**Admin Phone:**
- Number: 9408362739 (or any ending with 9408362739)
- Access: AdminDashboardScreen, can add/edit/delete products
- OTP: Firebase will show in Console during dev

**User Phone:**
- Number: Any valid phone number (different from admin)
- Access: HomeScreen, can view products only
- OTP: Firebase will show in Console during dev

---

## 📱 Android Configuration

**File:** `android/app/build.gradle.kts`
```gradle
plugins {
    id("com.google.gms.google-services")
}
dependencies {
    implementation(platform("com.google.firebase:firebase-bom:32.11.0"))
}
```

**Google Services JSON:** Place actual file at `android/app/google-services.json`

---

## 🍎 iOS Configuration

**File:** `ios/Runner/Info.plist`
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to your photo library to upload product images</string>
<key>NSCameraUsageDescription</key>
<string>We need camera access to take product photos</string>
```

**Google Services Plist:** Place actual file at `ios/Runner/GoogleService-Info.plist`

**Podfile:** May need to run `pod install` after adding Firebase dependencies

---

## 🚀 Running the App

```bash
# Get dependencies
flutter pub get

# Run on device/emulator
flutter run

# Or specific device
flutter run -d <device_id>
```

---

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| "FirebaseOptions not configured" | Fill lib/firebase_options.dart with real values |
| OTP not received | Ensure Firebase Auth is enabled for phone |
| "permission-denied" on Firestore | Check Firebase security rules, set to permissive for testing |
| Image upload fails | Check Firebase Storage bucket exists, permissions set |
| Pods error on iOS | Run `flutter clean && flutter pub get && cd ios && pod install && cd ..` |
| Android build fails | Run `flutter clean && flutter pub get` |

---

## 📚 References

- [Firebase FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firebase Auth Phone](https://firebase.flutter.dev/docs/auth/phone/)
- [Cloud Firestore](https://firebase.flutter.dev/docs/firestore/overview/)
- [Firebase Storage](https://firebase.flutter.dev/docs/storage/overview/)
- [Image Picker Plugin](https://pub.dev/packages/image_picker)

---

**Next Step:** Fill in Firebase configuration files, then test the complete flow!
