# Firebase Security Rules & Deployment Guide

## 📋 Firestore Security Rules Deployment

### Rules File Location
File: `firestore.rules` (in project root)

### Rule Authentication Flow

```
┌─────────────────────┐
│ User Makes Request  │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Check isAuthenticated() │──── NO ──> DENY
└──────────┬──────────┘
           │ YES
           ▼
┌─────────────────────┐
│ Check Collection    │
│ Permission Rules    │
└──────────┬──────────┘
           │
    ┌──────┴──────┐
    │             │
    ▼             ▼
┌─────────┐  ┌──────────┐
│ READ    │  │ WRITE    │
│ ALLOWED │  │ (Admin?) │
└─────────┘  └──────────┘
```

## 🔐 Collection-by-Collection Rules Breakdown

### Categories Collection

```firestore
match /categories/{categoryId} {
  allow read: if isAuthenticated();
  allow create, update, delete: if isAdmin();
}
```

**Usage:**
- ✅ Any user can read all categories
- 🔒 Only admin (9408362739) can add/edit/delete categories

**Test Rule:**
```
READ: ✅ Pass (any authenticated user)
CREATE: ❌ Fail (non-admin user)
DELETE: ❌ Fail (non-admin user)
```

---

### Products Collection

```firestore
match /products/{productId} {
  allow read: if isAuthenticated();
  allow create: if isAdmin() && 
                   request.resource.data.name is string &&
                   request.resource.data.category is string &&
                   request.resource.data.price is number &&
                   request.resource.data.unit is string &&
                   request.resource.data.storeId is string;
  allow update: if isAdmin() &&
                   request.resource.data.name is string &&
                   request.resource.data.category is string &&
                   request.resource.data.price is number &&
                   request.resource.data.unit is string;
  allow delete: if isAdmin();
}
```

**Validation:**
- Product must have: name, category, price, unit, storeId
- Only admin can modify

---

### Users Collection

```firestore
match /users/{userId} {
  allow read: if isUserOwner(userId) || isAdmin();
  allow create: if isUserOwner(userId);
  allow update: if isUserOwner(userId);
  allow delete: if isAdmin();

  match /addresses/{addressId} {
    allow read: if isUserOwner(userId) || isAdmin();
    allow create: if isUserOwner(userId);
    allow update: if isUserOwner(userId);
    allow delete: if isUserOwner(userId) || isAdmin();
  }
}
```

**Features:**
- Users can only read/write their own profile
- Admin can read any user profile
- Addresses are nested subcollection

---

### Orders Collection

```firestore
match /orders/{orderId} {
  allow read: if isAdmin() || 
                 (isAuthenticated() && 
                  resource.data.userId == request.auth.uid);
  allow create: if isAuthenticated() && 
                   request.resource.data.userId == request.auth.uid &&
                   request.resource.data.total is number &&
                   request.resource.data.status is string &&
                   request.resource.data.items is list;
  allow update: if isAdmin() || 
                   (isUserOwner(resource.data.userId) && 
                    request.resource.data.userId == resource.data.userId);
  allow delete: if isAdmin();
}
```

**Security:**
- Users can only read their own orders
- Admin can read all orders
- Users can only create orders for themselves
- Only admin can delete orders

---

### Payments Collection

```firestore
match /payments/{paymentId} {
  allow read: if isAdmin() || 
                 (isAuthenticated() && 
                  resource.data.userId == request.auth.uid);
  allow create: if isAuthenticated() && 
                   request.resource.data.userId == request.auth.uid &&
                   request.resource.data.amount is number &&
                   request.resource.data.orderId is string &&
                   request.resource.data.status is string;
  allow update: if isAdmin();
  allow delete: if isAdmin();
}
```

---

## 🚀 Deployment Steps

### Option 1: Firebase CLI (Recommended)

```bash
# 1. Install Firebase CLI (if not already installed)
npm install -g firebase-tools

# 2. Login to Firebase
firebase login

# 3. Initialize Firebase in your project (if not done)
firebase init

# 4. Deploy rules
firebase deploy --only firestore:rules

# 5. Verify deployment
firebase firestore:rules:list
```

### Option 2: Firebase Console (Manual)

1. Open [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Go to **Firestore Database**
4. Click **Rules** tab
5. Replace existing rules with content from `firestore.rules`
6. Click **Publish**

### Option 3: VS Code Extension

1. Install Firebase extension in VS Code
2. Click Firebase icon
3. Select "Deploy" → "Deploy Firestore Rules"

---

## ✅ Testing Security Rules

### Using Firebase Console Emulator

```bash
# Install emulator
firebase setup:emulators:firestore

# Start emulator
firebase emulators:start

# Connect app to emulator (for development)
# Add to main.dart:
if (kDebugMode) {
  FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
}
```

### Manual Testing Checklist

**Test as Regular User:**
```
Test Case: Read Products
Expected: ✅ PASS
Method: firestoreService.streamActiveProducts()

Test Case: Create Product
Expected: ❌ FAIL (Permission Denied)
Expected Error: "PERMISSION_DENIED: Missing or insufficient permissions"

Test Case: Create Order
Expected: ✅ PASS (when userId == auth.uid)
Note: Order must have userId matching logged-in user

Test Case: Read Other User's Order
Expected: ❌ FAIL
Expected Error: "PERMISSION_DENIED: Missing or insufficient permissions"
```

**Test as Admin (Phone: 9408362739):**
```
Test Case: Create Product
Expected: ✅ PASS
Requirement: name, category, price, unit, storeId

Test Case: Delete Category
Expected: ✅ PASS
Note: Can delete any category

Test Case: Read All Orders
Expected: ✅ PASS
Note: isAdmin() returns true

Test Case: Update Order Status
Expected: ✅ PASS
Note: Admin can update any order
```

---

## 🛡️ Security Best Practices

### 1. **Admin Verification**

✅ **Current Implementation:**
```dart
function isAdmin() {
  return request.auth.token.phone_number == '+916279408362';
}
```

⚠️ **Important:** Phone number in custom claims must be verified

### 2. **Data Validation**

✅ **Products:**
```firestore
request.resource.data.name is string &&
request.resource.data.category is string &&
request.resource.data.price is number
```

### 3. **User Ownership**

✅ **Orders:**
```firestore
isUserOwner(resource.data.userId) && 
request.resource.data.userId == resource.data.userId
```

### 4. **Fail-Secure Default**

✅ **Global Rule:**
```firestore
match /{document=**} {
  allow read, write: if false;
}
```

---

## ❌ Common Security Mistakes (AVOID)

### ❌ WRONG: Anyone can read everything
```firestore
match /{document=**} {
  allow read, write: if true;
}
```

### ❌ WRONG: No validation on fields
```firestore
match /products/{productId} {
  allow write: if isAdmin();  // No field validation!
}
```

### ❌ WRONG: User can write others' data
```firestore
match /orders/{orderId} {
  allow create: if isAuthenticated();  // No userId check!
}
```

### ✅ CORRECT: Proper validation
```firestore
match /orders/{orderId} {
  allow create: if isAuthenticated() && 
                   request.resource.data.userId == request.auth.uid;
}
```

---

## 📊 Rule Performance Impact

| Rule Type | Performance Impact | Notes |
|-----------|------------------|-------|
| Simple auth checks | None | Fast |
| Field validation | Low | Checks before write |
| User ownership checks | Low | Single field compare |
| Nested collection checks | Medium | May require additional reads |
| Complex queries | Higher | Avoid in rules |

---

## 🔄 Rule Update Workflow

### When Updating Rules:

1. **Test locally first**
   ```bash
   firebase emulators:start
   ```

2. **Review changes**
   ```
   Check if rules are more/less restrictive
   Verify admin access
   Confirm user privacy
   ```

3. **Publish gradually**
   - Test in staging environment first
   - Monitor Firestore logs for errors
   - Rollback if issues occur

4. **Notify team**
   - Document rule changes
   - Update client code if needed
   - Test affected features

---

## 📈 Monitoring & Debugging

### Firebase Console Monitoring

1. Go to **Firestore Database**
2. Click **Database Insights**
3. Monitor:
   - Security rule violations
   - Denied reads/writes
   - Error rate

### Debugging Denied Access

**App Side:**
```dart
try {
  await firestore.collection('products').add({...});
} catch (e) {
  print('Error: $e');
  // Look for "PERMISSION_DENIED"
}
```

**Firebase Console:**
1. Go to **Firestore** → **Metrics**
2. Filter by "Rule Violations"
3. See which rules are denying access

---

## 🔐 Environment-Specific Rules

### Development (Emulator)
```firestore
// Relaxed for testing
allow read, write: if true;
```

### Staging
```firestore
// Same as production but with monitoring logs
allow write: if isAdmin() && debug {
  addLog("Admin write to {collection}");
}
```

### Production
```firestore
// Strict rules in firestore.rules
allow write: if isAdmin();
```

---

## 📝 Rule Maintenance

### Version Control
- Keep `firestore.rules` in git
- Comment rule changes with date and reason
- Tag versions that are deployed

### Documentation
- Update BACKEND_REVIEW.md when rules change
- Document any new admin features
- Keep deployment log

### Regular Audits
- Monthly: Review rule violations
- Quarterly: Audit user access patterns
- Annually: Complete security review

---

## 🆘 Troubleshooting

### Problem: "Permission Denied" on read
**Cause:** User not authenticated or rule denies read
**Solution:** Check isAuthenticated() in rule, verify user is logged in

### Problem: Products not loading after rule deployment
**Cause:** New rules more restrictive than old
**Solution:** Verify read permissions for products rule

### Problem: Admin can't update orders
**Cause:** isAdmin() not returning true
**Solution:** Check phone number matches exactly (with country code)

### Problem: Rules won't deploy
**Cause:** Invalid syntax or Firebase CLI issues
**Solution:** 
1. Validate rules syntax in console
2. Check Firebase project is correct: `firebase list`
3. Try: `firebase deploy --debug`

---

## ✨ Next Security Enhancements

1. **Multi-level Admin Roles** (store manager, super admin)
2. **IP Whitelisting** for admin operations
3. **Audit Logging** for sensitive operations
4. **Rate Limiting** to prevent abuse
5. **Data Encryption** at application level
6. **Two-Factor Authentication** for admins

---

**Document Version:** 1.0  
**Last Updated:** 2024-02-17  
**Firebase SDK:** 3.10.0+  
**Security Level:** Production-Ready ✅
