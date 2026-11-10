import 'dart:async';
import 'package:flutter/material.dart';
import 'package:brainrot_tracker_pro/core/constants/app_colors.dart';
import 'package:brainrot_tracker_pro/features/interventions/presentation/widgets/animated_breathing_circle.dart';

/// Mindful 5-second pause screen enforcing intentional pauses during doomscrolling sessions.
/// Features a strict countdown lock on dismissal to interrupt dopamine loop inertia.
class BreatheScreen extends StatefulWidget {
  final VoidCallback onResume;
  final VoidCallback onExitToMenu;
  final int initialDurationSeconds;

  const BreatheScreen({
    super.key,
    required this.onResume,
    required this.onExitToMenu,
    this.initialDurationSeconds = 5,
  });

  @override
  State<BreatheScreen> createState() => _BreatheScreenState();
}

class _BreatheScreenState extends State<BreatheScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late int _secondsRemaining;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.initialDurationSeconds;

    // 2.5s Inhale + 2.5s Exhale cycle
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _animController.reverse();
        } else if (status == AnimationStatus.dismissed) {
          _animController.forward();
        }
      });

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.55).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOutSine),
    );
    _animController.forward();

    // 1-second interval countdown timer
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_secondsRemaining > 0) {
            _secondsRemaining--;
          } else {
            timer.cancel();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool canDismiss = _secondsRemaining == 0;
    final bool isInhaling = _animController.status != AnimationStatus.reverse;

    return PopScope(
      canPop: canDismiss,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Back navigation prevented while mindful countdown lock is active.
      },
      child: Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top label
              const Text(
                'MINDFUL PAUSE',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 14,
                  letterSpacing: 2.5,
                  fontWeight: FontWeight.bold,
                ),
              ),

              // Center Breathing animation & prompt
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBreathingCircle(
                    scaleAnimation: _scaleAnimation,
                    secondsRemaining: _secondsRemaining,
                    isInhaling: isInhaling,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Notice your mind. Are you enjoying this, or just scrolling on autopilot?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ],
              ),

              // Action buttons
              Column(
                children: [
                  ElevatedButton(
                    onPressed: canDismiss ? widget.onResume : null,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: const Color(0xFF1E293B),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      canDismiss ? 'Continue Scrolling' : 'Pause for $_secondsRemaining s',
                      style: TextStyle(
                        color: canDismiss ? AppColors.textInverse : const Color(0xFF64748B),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: widget.onExitToMenu,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      side: const BorderSide(color: Color(0xFF334155)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Open Dopamine Menu (Heal Brain +10%)',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
