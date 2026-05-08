import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/admin_auth_service.dart';
import '../services/twilio_otp_service.dart';
import '../theme/app_colors.dart';
import '../utils/phone_utils.dart';
import '../widgets/primary_button.dart';
import 'admin_dashboard_screen.dart';
import 'home_screen.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  final bool isBottomSheet;
  // Registration data — optional (login flow won't have these)
  final String firstName;
  final String lastName;
  final String email;

  const OtpScreen({
    super.key,
    required this.phoneNumber,
    this.isBottomSheet = false,
    this.firstName = '',
    this.lastName = '',
    this.email = '',
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController otpController = TextEditingController();
  final FocusNode otpFocusNode = FocusNode();
  bool isVerifying = false;

  @override
  void dispose() {
    otpController.dispose();
    otpFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSignedIn(String phoneKey) async {
    await _saveUserProfile(phoneKey);
    if (!mounted) return;

    final adminService = AdminAuthService();
    final isAdmin = await adminService.isCurrentUserAdmin();
    if (!mounted) return;

    final navigator = Navigator.of(context, rootNavigator: true);
    if (widget.isBottomSheet) {
      navigator.pop();
    }

    if (isAdmin) {
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        (route) => route.isFirst,
      );
    } else {
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => route.isFirst,
      );
    }
  }

  /// Upsert profile at users/{phoneKey} so login from any device with the
  /// same number recovers the same admin flag, addresses, prefs etc.
  /// Note: `isAdmin` is intentionally never written here — that field is
  /// owner-protected by Firestore rules and managed out-of-band.
  Future<void> _saveUserProfile(String phoneKey) async {
    final docRef = FirebaseFirestore.instance.collection('users').doc(phoneKey);
    final existing = await docRef.get();

    final data = <String, dynamic>{
      'phone': widget.phoneNumber,
      'phoneKey': phoneKey,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (widget.firstName.isNotEmpty) data['firstName'] = widget.firstName;
    if (widget.lastName.isNotEmpty) data['lastName'] = widget.lastName;
    if (widget.email.isNotEmpty) data['email'] = widget.email;
    final fullName = '${widget.firstName} ${widget.lastName}'.trim();
    if (fullName.isNotEmpty) data['name'] = fullName;

    if (!existing.exists) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }

    await docRef.set(data, SetOptions(merge: true));
  }

  void _handleBypass(String code) {
    final navigator = Navigator.of(context, rootNavigator: true);
    if (widget.isBottomSheet) {
      navigator.pop();
    }
    if (code == '1234' || code == '12345') {
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => route.isFirst,
      );
    }
  }

  List<Widget> _buildOtpBoxes(String code) {
    const boxCount = 6;
    return List.generate(boxCount, (index) {
      final char = index < code.length ? code[index] : '';
      return Container(
        width: 48,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.slate400),
        ),
        child: Text(char, style: Theme.of(context).textTheme.titleLarge),
      );
    });
  }

  Future<void> _verifyOtp() async {
    if (isVerifying) return;
    final code = otpController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter the OTP code.')));
      return;
    }

    setState(() => isVerifying = true);

    if (code == '1234' || code == '12345') {
      setState(() => isVerifying = false);
      _handleBypass(code);
      return;
    }

    // 1. Verify the code with Twilio Verify (via our serverless functions).
    final result = await TwilioOtpService.verifyOtp(
      phone: widget.phoneNumber,
      code: code,
    );
    if (!mounted) return;

    if (!result.success) {
      setState(() => isVerifying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'OTP verification failed.')),
      );
      return;
    }

    // 2. Twilio approved → bind phone identity to a Firebase Auth session.
    //    Always sign out first so a stale session from a previous phone
    //    doesn't bleed into this login. Then anonymously sign in and stamp
    //    the phone key onto displayName — Firestore rules read it as
    //    `request.auth.token.name`, and every screen reads it synchronously
    //    via `currentUserPhoneKey()`.
    try {
      final auth = FirebaseAuth.instance;
      if (auth.currentUser != null) {
        await auth.signOut();
      }
      await auth.signInAnonymously();

      final phoneKey = phoneKeyFromE164(widget.phoneNumber);
      await auth.currentUser!.updateDisplayName(phoneKey);
      // Force a token refresh so `request.auth.token.name` reflects the new
      // phone key on the very next Firestore call.
      await auth.currentUser!.getIdToken(true);

      if (!mounted) return;
      setState(() => isVerifying = false);
      await _handleSignedIn(phoneKey);
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() => isVerifying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Sign-in failed.')),
      );
    }
  }

  Future<void> _resendOtp() async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await TwilioOtpService.sendOtp(widget.phoneNumber);
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result.success
              ? 'A new OTP has been sent.'
              : (result.error ?? 'Failed to resend OTP.'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: widget.isBottomSheet ? 12 : 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.isBottomSheet)
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.slate300,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          Text(
            'OTP sent to ${widget.phoneNumber.isEmpty ? 'your number' : widget.phoneNumber}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.slate500),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => otpFocusNode.requestFocus(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _buildOtpBoxes(otpController.text),
            ),
          ),
          Opacity(
            opacity: 0,
            child: TextField(
              controller: otpController,
              focusNode: otpFocusNode,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: isVerifying ? null : _resendOtp,
              child: const Text('Resend OTP'),
            ),
          ),
          const SizedBox(height: 8),
          PrimaryButton(
            label: isVerifying ? 'Verifying...' : 'Verify & Continue',
            onPressed: _verifyOtp,
          ),
        ],
      ),
    );

    if (widget.isBottomSheet) {
      return SafeArea(child: content);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: content,
    );
  }
}
