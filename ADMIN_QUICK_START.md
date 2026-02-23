# Quick Start: Admin Product Management Flow

## 🔐 Login as Admin

**Prerequisite:** Fill `lib/firebase_options.dart` with Firebase credentials

### Step 1: Open Login Screen
- App opens → Login Screen appears

### Step 2: Enter Admin Phone
- Enter any phone number ending with: `9408362739`
- Example valid numbers:
  - `9408362739`
  - `919408362739` (with country code)
  - `+919408362739` (with + prefix)

### Step 3: Receive OTP
- SMS arrives with OTP code
- (In development/testing, check Firebase Console for test OTP)

### Step 4: Enter OTP
- Copy OTP from SMS
- Paste in OTP Screen → Tap Verify
- Firebase authenticates → You're logged in as Admin

### Step 5: See Admin Dashboard
- Redirected to `AdminDashboardScreen`
- You now have access to admin features

---

## ➕ Add New Product

### From Admin Dashboard
1. Tap **"Add Product"** button
2. Fill product details:
   - **Name:** e.g., "Chicken Biryani"
   - **Category:** e.g., "Main Course"
   - **Price:** e.g., 299 (in rupees)
   - **Unit:** e.g., "per plate"
   - **Stock Note:** e.g., "40 in stock"

3. **Add Description:**
   - Tap description field
   - Enter: e.g., "Fragrant basmati rice cooked with tender chicken pieces, aromatic spices, and fresh herbs"

4. **Pick Image:**
   - Tap **"Pick Image"** button
   - Select from your gallery
   - Image preview appears
   - (Uploading to Firebase during save)

5. **Set Active Status:**
   - Toggle **Product Active** switch
   - ON (green) = Visible to customers
   - OFF (gray) = Hidden from customers

6. **Save Product:**
   - Tap **"Add Product"** button
   - Loading spinner shows upload progress
   - Product saved to Firestore with image URL
   - Automatically returns to Admin Dashboard

### What Happens Behind the Scenes
```
Click "Add Product"
    ↓
Validate: name, price, unit not empty
    ↓
Upload image to: gs://bucket/products/{id}/{timestamp}.jpg
    ↓
Get download URL from Storage
    ↓
Save to Firestore:
{
  name: "Chicken Biryani",
  category: "Main Course",
  price: 299,
  unit: "per plate",
  stockNote: "40 in stock",
  description: "...",
  imageUrl: "https://storage.googleapis.com/...",
  isActive: true,
  storeId: "mall",
  createdAt: Timestamp.now(),
  updatedAt: Timestamp.now()
}
    ↓
Success ✅ → Return to Admin Dashboard
```

---

## ✏️ Edit Product

### From Admin Dashboard
1. Find product in the list
2. Tap the product card or **Edit** button
3. Form opens with current values pre-filled
4. Change any details you want:
   - Name, category, price, unit, stock, description
5. **Change Image (Optional):**
   - Tap **"Change Image"** button (shows current image)
   - Select new image from gallery
   - Old image automatically deleted when you save
6. Tap **"Save Changes"**
7. Product updates in Firestore
8. Returns to Admin Dashboard

---

## 🗑️ Delete Product

### From Admin Dashboard
1. Find product in the list
2. Tap product card to open it
3. Scroll to bottom
4. Tap **"Delete Product"** button
5. Confirmation dialog appears:
   - **"Are you sure you want to delete this product?"**
6. Tap **"Delete"** (red button)
7. Product removed from Firestore
8. Associated image removed from Storage
9. Returns to Admin Dashboard

---

## 👤 Exit Admin Mode (Logout)

1. Tap **Profile** tab
2. Scroll down
3. Tap **"Logout"** button
4. Signed out of Firebase
5. App returns to Login Screen

### Re-login as Different User
- Enter non-admin phone (doesn't end with 9408362739)
- Complete OTP verification
- Redirected to **HomeScreen** (user view, not admin)
- See products you added as admin

---

## 👁️ View Products as User

### Login as Non-Admin
1. Enter phone that doesn't end with `9408362739`
2. Example: `9876543210`
3. Complete OTP
4. Redirected to HomeScreen

### See Admin Products
1. **HomeScreen** shows all active products from Firestore
2. Products have:
   - Product image (from Firebase Storage)
   - Name, price, unit
   - Category chip
   - Add to cart button

### Search/Filter
- Use search bar to find products
- Browse by category
- View products by store

---

## 📱 Product Card Display

When a user views a product (as added by admin):

```
┌─────────────────────────┐
│  [Product Image]        │
│  (from Storage URL)     │
├─────────────────────────┤
│ Chicken Biryani         │
│ Main Course             │
│                         │
│ Rs. 299 / per plate     │
│                         │
│ [Add to Cart] [+] [-]   │
└─────────────────────────┘
```

### Product Info Available
- Product name from Firestore
- Category from Firestore
- Price in rupees from Firestore
- Unit from Firestore
- Image from Storage URL
- Description (shown on tap)

---

## 📊 Data Flow Architecture

### Admin Adds Product
```
Admin Form UI
  ↓
Firebase Storage
(uploads image)
  ↓
Get download URL
  ↓
Firestore
(saves product + URL)
  ↓
Firestore stream
triggers update
```

### User Views Product
```
HomeScreen
  ↓
Watch activeProductsProvider
  ↓
Listen to Firestore stream
  ↓
Load products
  ↓
Display with images
from Storage URLs
```

---

## ⚠️ Important Points

### Who Can Add Products?
- **Only admin** (phone ending in 9408362739)
- Other users: can only view and cart

### Where Are Products Stored?
- **Details:** Firestore database
- **Images:** Firebase Storage
- **Backup:** Mock catalog (if Firestore unavailable)

### Image Size/Format
- Supported: JPG, PNG
- Automatic storage path: `products/{id}/{timestamp}.jpg`
- No size limit enforced (but keep reasonable)

### Product Availability
- Products with `isActive: true` → visible to users
- Products with `isActive: false` → hidden from users

### Real-time Updates
- When admin adds product → Appears immediately in user's HomeScreen
- When admin edits product → Changes reflect instantly
- When admin deletes product → Disappears instantly

---

## 🔑 Firebase Credentials Location

If something isn't working, check these files are filled correctly:
1. `lib/firebase_options.dart` - Platform config (most important)
2. `android/app/google-services.json` - Android-specific
3. `ios/Runner/GoogleService-Info.plist` - iOS-specific

Missing real credentials → App falls back to mock data (no persistence)

---

## 🧪 Test Scenario

### Complete Test Flow
1. **Admin Login**
   - Phone: `9408362739`
   - Verify OTP
   - See AdminDashboardScreen

2. **Add Test Product**
   - Name: "Test Biryani"
   - Price: 299
   - Unit: "per plate"
   - Pick a test image from gallery
   - Tap "Add Product"
   - See success (auto-navigated back)

3. **Verify in Firestore**
   - Open Firebase Console
   - Database → products collection
   - See your new document
   - Check imageUrl field has Storage URL

4. **User View**
   - Logout
   - Login with different number: `9876543210`
   - Go to HomeScreen
   - See "Test Biryani" product card
   - Tap to see full description
   - Image displays correctly

5. **Edit Test**
   - Logout, login as admin again
   - Find product in list
   - Change name to "Updated Biryani"
   - Tap "Save Changes"
   - Verify change in user view

6. **Delete Test**
   - As admin, find product
   - Tap "Delete Product"
   - Confirm deletion
   - Verify removed in user view

---

**Status:** ✅ Ready to test with Firebase credentials filled!
