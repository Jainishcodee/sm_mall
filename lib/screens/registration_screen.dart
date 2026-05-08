import 'package:flutter/material.dart';

import '../services/twilio_otp_service.dart';
import '../theme/app_colors.dart';
import '../utils/phone_utils.dart';
import '../widgets/primary_button.dart';
import 'otp_screen.dart';

class RegistrationScreen extends StatefulWidget {
  /// When true the screen renders as a draggable bottom-sheet (rounded top,
  /// drag handle, no AppBar). When false it falls back to a full Scaffold —
  /// kept for any future deep-link / direct-push flow.
  final bool isBottomSheet;

  const RegistrationScreen({super.key, this.isBottomSheet = false});

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
    final email = _emailCtrl.text.trim();
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
    final result = await TwilioOtpService.sendOtp(normalized);
    if (!mounted) return;
    setState(() => isSending = false);

    if (!result.success) {
      _snack(result.error ?? 'Failed to send OTP.');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => OtpScreen(
        phoneNumber: normalized,
        isBottomSheet: true,
        firstName: firstName,
        lastName: lastName,
        email: email,
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final content = SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: widget.isBottomSheet ? 12 : 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.isBottomSheet) ...[
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
          ],
          Text(
            'Create account',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tell us a bit about you to get started.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.slate500,
            ),
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
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.slate500,
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: isSending ? 'Sending OTP…' : 'Continue',
            onPressed: isSending ? null : _sendOtp,
          ),
          if (widget.isBottomSheet) ...[
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.slate500),
                ),
              ),
            ),
          ],
        ],
      ),
    );

    if (widget.isBottomSheet) {
      return SafeArea(top: false, child: content);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: content,
    );
  }
}
