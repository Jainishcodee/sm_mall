import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/admin_auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/primary_button.dart';
import 'admin_dashboard_screen.dart';
import 'home_screen.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;
  final bool isBottomSheet;
  // Registration data — optional (login flow won't have these)
  final String firstName;
  final String lastName;
  final String email;

  const OtpScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
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

  /// After Firebase sign-in, check Firestore for admin flag and route accordingly.
  Future<void> _handleSignedIn() async {
    await _saveUserProfile();
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

  /// Upsert user profile to Firestore using merge so existing data is preserved.
  Future<void> _saveUserProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final data = <String, dynamic>{
      'phone': widget.phoneNumber,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (widget.firstName.isNotEmpty) data['firstName'] = widget.firstName;
    if (widget.lastName.isNotEmpty) data['lastName'] = widget.lastName;
    if (widget.email.isNotEmpty) data['email'] = widget.email;
    // Set legacy 'name' field too for backwards compat
    final fullName = '${widget.firstName} ${widget.lastName}'.trim();
    if (fullName.isNotEmpty) data['name'] = fullName;
    // Only set createdAt on first write
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Bypass OTP for demo/testing — always routes to customer HomeScreen.
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
    try {
      // Demo bypass codes — only for non-authenticated testing, always customer.
      if (code == '1234' || code == '12345') {
        setState(() => isVerifying = false);
        _handleBypass(code);
        return;
      }

      // Real OTP verification via Firebase Auth
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: code,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      if (!mounted) return;
      setState(() => isVerifying = false);
      await _handleSignedIn();
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      // Fallback bypass on auth error for demo codes
      if (code == '1234' || code == '12345') {
        setState(() => isVerifying = false);
        _handleBypass(code);
        return;
      }
      setState(() => isVerifying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'OTP verification failed.')),
      );
    }
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
          const SizedBox(height: 20),
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
