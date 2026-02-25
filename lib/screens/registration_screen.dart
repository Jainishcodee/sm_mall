import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../utils/phone_utils.dart';
import '../widgets/primary_button.dart';
import 'otp_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool isSending = false;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (isSending) return;

    final firstName = _firstNameCtrl.text.trim();
    final lastName = _lastNameCtrl.text.trim();
    final email = _emailCtrl.text.trim(); // optional
    final normalized = normalizePhone(_phoneCtrl.text.trim());

    if (firstName.isEmpty) {
      _snack('Please enter your first name.');
      return;
    }
    if (normalized == null) {
      _snack('Enter a valid phone number.');
      return;
    }

    setState(() => isSending = true);
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: normalized,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
          if (!mounted) return;
          setState(() => isSending = false);
        },
        verificationFailed: (error) {
          if (!mounted) return;
          setState(() => isSending = false);
          _snack(error.message ?? 'Failed to send OTP.');
        },
        codeSent: (verificationId, _) {
          if (!mounted) return;
          setState(() => isSending = false);
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (_) => OtpScreen(
              phoneNumber: normalized,
              verificationId: verificationId,
              isBottomSheet: true,
              firstName: firstName,
              lastName: lastName,
              email: email,
            ),
          );
        },
        codeAutoRetrievalTimeout: (_) {
          if (!mounted) return;
          setState(() => isSending = false);
        },
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => isSending = false);
      _snack('Failed to send OTP: $error');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tell us about you',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              'Enter your name and phone to get started.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _firstNameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      hintText: 'First name *',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _lastNameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(hintText: 'Last name'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: 'Mobile number *',
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'Email address (optional)',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '* Required fields',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: isSending ? 'Sending OTP…' : 'Continue',
              onPressed: isSending ? null : _sendOtp,
            ),
          ],
        ),
      ),
    );
  }
}
