import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/admin_auth_service.dart';
import '../theme/app_colors.dart';
import 'admin_dashboard_screen.dart';
import 'auth_landing_screen.dart';
import 'home_screen.dart';

/// Root widget that picks the right landing screen based on the cached
/// Firebase Auth state — so a returning user who's already logged in lands
/// straight on Home (or Admin Dashboard) instead of the login form.
///
/// We listen to `authStateChanges()` so the same widget reacts to sign-out
/// and re-sign-in without needing manual `pushReplacement` calls in those
/// flows: when the OTP screen finishes, it just pops back to root and the
/// gate re-evaluates which screen to show.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // First emission can take a frame on cold start while Firebase
        // hydrates the cached user from disk.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _Splash();
        }

        final user = snapshot.data;
        if (user == null) {
          return const AuthLandingScreen();
        }

        // We have a user — decide if they're an admin. The phone key is
        // stored on `user.displayName` (set by the OTP flow). If it's
        // missing (legacy session pre-Twilio refactor) we fall back to
        // the Home screen rather than getting stuck.
        if ((user.displayName ?? '').isEmpty) {
          return const HomeScreen();
        }

        return FutureBuilder<bool>(
          future: AdminAuthService().isCurrentUserAdmin(),
          builder: (context, adminSnap) {
            if (adminSnap.connectionState == ConnectionState.waiting) {
              return const _Splash();
            }
            final isAdmin = adminSnap.data == true;
            return isAdmin ? const AdminDashboardScreen() : const HomeScreen();
          },
        );
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
}
