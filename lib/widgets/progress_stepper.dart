import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Blinkit-style horizontal progress stepper with animated connectors
/// and a pulsing glow on the current active step.
class ProgressStepper extends StatelessWidget {
  final int currentStep;
  final List<String> steps;

  const ProgressStepper({
    super.key,
    required this.currentStep,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          // Even indices are dots, odd indices are connectors.
          if (i.isEven) {
            final stepIndex = i ~/ 2;
            final isDone = stepIndex < currentStep;
            final isActive = stepIndex == currentStep;
            final isUpcoming = stepIndex > currentStep;
            return _StepCircle(
              label: steps[stepIndex],
              isDone: isDone,
              isActive: isActive,
              isUpcoming: isUpcoming,
              stepNumber: stepIndex + 1,
            );
          } else {
            final leftStep = i ~/ 2;
            final filled = leftStep < currentStep;
            return Expanded(child: _Connector(filled: filled));
          }
        }),
      ),
    );
  }
}

class _StepCircle extends StatefulWidget {
  final String label;
  final bool isDone;
  final bool isActive;
  final bool isUpcoming;
  final int stepNumber;

  const _StepCircle({
    required this.label,
    required this.isDone,
    required this.isActive,
    required this.isUpcoming,
    required this.stepNumber,
  });

  @override
  State<_StepCircle> createState() => _StepCircleState();
}

class _StepCircleState extends State<_StepCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    if (widget.isActive) _pulseCtrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _StepCircle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_pulseCtrl.isAnimating) {
      _pulseCtrl.repeat(reverse: true);
    } else if (!widget.isActive && _pulseCtrl.isAnimating) {
      _pulseCtrl.stop();
      _pulseCtrl.reset();
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color circleColor;
    final Widget circleChild;

    if (widget.isDone) {
      circleColor = AppColors.success;
      circleChild = const Icon(Icons.check, color: Colors.white, size: 16);
    } else if (widget.isActive) {
      circleColor = AppColors.primary;
      circleChild = Text(
        '${widget.stepNumber}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      );
    } else {
      circleColor = AppColors.slate200;
      circleChild = Text(
        '${widget.stepNumber}',
        style: const TextStyle(
          color: AppColors.slate400,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pulsing glow ring for active step
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (context, child) {
            final scale = widget.isActive ? _pulseAnim.value : 1.0;
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: circleColor,
                  boxShadow: widget.isActive
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Center(child: circleChild),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 11,
            fontWeight:
                (widget.isDone || widget.isActive) ? FontWeight.w600 : FontWeight.w400,
            color: widget.isDone
                ? AppColors.success
                : widget.isActive
                    ? AppColors.primary
                    : AppColors.slate400,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _Connector extends StatelessWidget {
  final bool filled;
  const _Connector({required this.filled});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Container(
        height: 3,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          color: filled ? AppColors.success : AppColors.slate200,
        ),
      ),
    );
  }
}
