import 'package:firebase_auth/firebase_auth.dart';

/// Returns the current user's phone-derived identity key, or null when no one
/// is signed in. The OTP flow sets this on `FirebaseAuth.User.displayName`
/// after a successful Twilio verification, so any screen can read it
/// synchronously without an extra Firestore lookup.
///
/// Firestore rules read the same value from `request.auth.token.name`.
String? currentUserPhoneKey() {
  final name = FirebaseAuth.instance.currentUser?.displayName;
  if (name == null || name.isEmpty) return null;
  return name;
}
