import 'dart:async';

import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../services/twilio_otp_service.dart';
import '../theme/app_colors.dart';
import '../utils/phone_utils.dart';
import '../widgets/primary_button.dart';
import 'otp_screen.dart';
import 'registration_screen.dart';

class AuthLandingScreen extends StatefulWidget {
  const AuthLandingScreen({super.key});

  @override
  State<AuthLandingScreen> createState() => _AuthLandingScreenState();
}

class _AuthLandingScreenState extends State<AuthLandingScreen>
    with TickerProviderStateMixin {
  final TextEditingController phoneController = TextEditingController();
  late final AnimationController logoController;
  late final AnimationController cardController;
  Timer? _cardTimer;

  late final Animation<Offset> logoOffset;
  late final Animation<double> logoOpacity;
  late final Animation<Offset> cardOffset;
  late final Animation<double> cardOpacity;

  @override
  void initState() {
    super.initState();
    logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    logoOffset = Tween<Offset>(
      begin: const Offset(0.8, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: logoController, curve: Curves.easeOut));
    logoOpacity = CurvedAnimation(parent: logoController, curve: Curves.easeIn);

    cardOffset = Tween<Offset>(
      begin: const Offset(0, 0.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: cardController, curve: Curves.easeOut));
    cardOpacity = CurvedAnimation(parent: cardController, curve: Curves.easeIn);

    logoController.forward();
    _cardTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        cardController.forward();
      }
    });
  }

  @override
  void dispose() {
    phoneController.dispose();
    logoController.dispose();
    cardController.dispose();
    _cardTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 48),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SlideTransition(
                      position: logoOffset,
                      child: FadeTransition(
                        opacity: logoOpacity,
                        child: Image.asset(
                          'assets/images/Malldash.png',
                          width: 220,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'SM Mall delivery app',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SlideTransition(
                position: cardOffset,
                child: FadeTransition(
                  opacity: cardOpacity,
                  child: _AuthCard(phoneController: phoneController),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthCard extends StatefulWidget {
  final TextEditingController phoneController;

  const _AuthCard({required this.phoneController});

  @override
  State<_AuthCard> createState() => _AuthCardState();
}

class _AuthCardState extends State<_AuthCard> {
  bool isSending = false;

  Future<void> _sendOtp() async {
    if (isSending) return;

    final normalized = normalizePhone(widget.phoneController.text.trim());
    if (normalized == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid phone number.')),
      );
      return;
    }

    setState(() => isSending = true);
    final result = await TwilioOtpService.sendOtp(normalized);
    if (!mounted) return;
    setState(() => isSending = false);

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Failed to send OTP.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => OtpScreen(
        phoneNumber: normalized,
        isBottomSheet: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 24,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: widget.phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.phone),
              hintText: 'Enter mobile number',
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: isSending ? 'Sending...' : 'Send OTP',
            onPressed: _sendOtp,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'New to ${AppConstants.appName}?',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.slate500),
              ),
              TextButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    builder: (_) =>
                        const RegistrationScreen(isBottomSheet: true),
                  );
                },
                child: const Text(
                  'Create account',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
