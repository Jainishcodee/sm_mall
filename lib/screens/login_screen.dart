import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../utils/phone_utils.dart';
import '../widgets/primary_button.dart';
import 'admin_dashboard_screen.dart';
import 'home_screen.dart';
import 'otp_screen.dart';
import 'registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController phoneController = TextEditingController();
  bool isSending = false;

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (isSending) {
      return;
    }
    final normalized = normalizePhone(phoneController.text.trim());
    if (normalized == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid phone number.')),
      );
      return;
    }
    setState(() => isSending = true);
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: normalized,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
          if (!mounted) {
            return;
          }
          setState(() => isSending = false);
          _handleSignedIn(normalized);
        },
        verificationFailed: (error) {
          if (!mounted) {
            return;
          }
          setState(() => isSending = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.message ?? 'Failed to send OTP.')),
          );
        },
        codeSent: (verificationId, _) {
          if (!mounted) {
            return;
          }
          setState(() => isSending = false);
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (_) => OtpScreen(
              phoneNumber: normalized,
              verificationId: verificationId,
              isBottomSheet: true,
            ),
          );
        },
        codeAutoRetrievalTimeout: (_) {
          if (!mounted) {
            return;
          }
          setState(() => isSending = false);
        },
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => isSending = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send OTP: $error')));
    }
  }

  void _handleSignedIn(String phoneNumber) {
    final isAdmin = last10Digits(phoneNumber) == AppConstants.adminPhone;
    if (isAdmin) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        (route) => route.isFirst,
      );
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => route.isFirst,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'Welcome to ${AppConstants.appName}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Login with your mobile number',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.slate500),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.phone),
                  hintText: 'Enter mobile number',
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: isSending ? 'Sending...' : 'Send OTP',
                onPressed: _sendOtp,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'New here?',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.slate500),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const RegistrationScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Create account',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Credentials:',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.slate900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Admin: ${AppConstants.adminPhone} + OTP: 1234',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.slate700,
                      ),
                    ),
                    Text(
                      'User: Any phone + OTP: 12345',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.slate700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
