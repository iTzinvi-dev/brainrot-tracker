import 'package:flutter/material.dart';
import 'package:brainrot_tracker_pro/core/constants/app_colors.dart';

/// Animated expanding/contracting breathing circle for mindfulness intervention.
class AnimatedBreathingCircle extends StatelessWidget {
  final Animation<double> scaleAnimation;
  final int secondsRemaining;
  final bool isInhaling;

  const AnimatedBreathingCircle({
    super.key,
    required this.scaleAnimation,
    required this.secondsRemaining,
    required this.isInhaling,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ScaleTransition(
          scale: scaleAnimation,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withOpacity(0.45),
                  AppColors.primaryDark.withOpacity(0.15),
                  Colors.transparent,
                ],
                stops: const [0.3, 0.7, 1.0],
              ),
              border: Border.all(
                color: AppColors.primary,
                width: 2.5,
              ),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.breatheCircleGlow,
                  blurRadius: 30,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: Center(
              child: Text(
                secondsRemaining > 0 ? '$secondsRemaining' : '✓',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -1.0,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 36),
        Text(
          isInhaling ? 'Breathe in slowly...' : 'Breathe out gently...',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}
