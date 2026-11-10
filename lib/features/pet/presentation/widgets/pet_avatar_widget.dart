import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:brainrot_tracker_pro/core/constants/app_colors.dart';
import 'package:brainrot_tracker_pro/features/pet/domain/brain_rot_calculator.dart';

/// Animated Brain Rot Pet Avatar with breathing physics and particle overlays.
class PetAvatarWidget extends StatefulWidget {
  final BrainRotPetState petState;
  final double size;

  const PetAvatarWidget({
    super.key,
    required this.petState,
    this.size = 200,
  });

  @override
  State<PetAvatarWidget> createState() => _PetAvatarWidgetState();
}

class _PetAvatarWidgetState extends State<PetAvatarWidget> with TickerProviderStateMixin {
  late AnimationController _breatheController;
  late Animation<double> _breatheAnimation;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    // Idle breathing animation (3.4s cycle)
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _breatheController.reverse();
        } else if (status == AnimationStatus.dismissed) {
          _breatheController.forward();
        }
      });

    _breatheAnimation = Tween<double>(begin: 1.0, end: 1.045).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOutSine),
    );
    _breatheController.forward();

    // Critical stage shake animation
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _shakeAnimation = Tween<double>(begin: -3.0, end: 3.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );

    if (widget.petState.stageIndex >= 6) {
      _shakeController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant PetAvatarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.petState.stageIndex >= 6 && !_shakeController.isAnimating) {
      _shakeController.repeat(reverse: true);
    } else if (widget.petState.stageIndex < 6 && _shakeController.isAnimating) {
      _shakeController.stop();
      _shakeController.reset();
    }
  }

  @override
  void dispose() {
    _breatheController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  Color _getStageColor() {
    switch (widget.petState.stageIndex) {
      case 0:
        return AppColors.healthFresh;
      case 1:
        return AppColors.primary;
      case 2:
        return AppColors.secondary;
      case 3:
        return AppColors.healthWarning;
      case 4:
        return AppColors.healthRotting;
      case 5:
        return AppColors.healthDanger;
      case 6:
      default:
        return AppColors.healthCritical;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stageColor = _getStageColor();
    final isCritical = widget.petState.stageIndex >= 6;

    return Center(
      child: AnimatedBuilder(
        animation: Listenable.merge([_breatheAnimation, _shakeAnimation]),
        builder: (context, child) {
          final double shakeOffset = isCritical ? _shakeAnimation.value : 0.0;
          return Transform.translate(
            offset: Offset(shakeOffset, 0),
            child: Transform.scale(
              scale: _breatheAnimation.value,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer Glow & Pedestal
                  Container(
                    width: widget.size * 1.15,
                    height: widget.size * 1.15,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          stageColor.withOpacity(0.35),
                          stageColor.withOpacity(0.08),
                          Colors.transparent,
                        ],
                        stops: const [0.2, 0.6, 1.0],
                      ),
                    ),
                  ),

                  // Pedestal Ring
                  Container(
                    width: widget.size * 0.9,
                    height: widget.size * 0.9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: stageColor.withOpacity(0.4),
                        width: 2,
                      ),
                    ),
                  ),

                  // Brain Stage Sprite
                  Image.asset(
                    widget.petState.spritePath,
                    width: widget.size * 0.75,
                    height: widget.size * 0.75,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback visual representation if assets are unbundled in headless test
                      return Container(
                        width: widget.size * 0.6,
                        height: widget.size * 0.6,
                        decoration: BoxDecoration(
                          color: stageColor.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: stageColor, width: 2),
                        ),
                        child: Icon(
                          Icons.psychology,
                          size: widget.size * 0.35,
                          color: stageColor,
                        ),
                      );
                    },
                  ),

                  // Particle Overlay: Green Slime Drops for stage >= 4
                  if (widget.petState.isSlimy)
                    Positioned(
                      bottom: widget.size * 0.15,
                      right: widget.size * 0.2,
                      child: Image.asset(
                        'assets/images/fx_drip_green.png',
                        width: 28,
                        height: 28,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.water_drop,
                          size: 20,
                          color: AppColors.healthRotting,
                        ),
                      ),
                    ),

                  // Particle Overlay: Smoke Wisps for stage >= 5
                  if (widget.petState.isSmoking)
                    Positioned(
                      top: widget.size * 0.08,
                      child: Image.asset(
                        'assets/images/fx_smoke_1.png',
                        width: 44,
                        height: 44,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.cloud,
                          size: 28,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),

                  // Particle Overlay: Lightning bolt for critical stage
                  if (isCritical)
                    Positioned(
                      top: widget.size * 0.12,
                      left: widget.size * 0.18,
                      child: Image.asset(
                        'assets/images/fx_bolt.png',
                        width: 32,
                        height: 32,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.flash_on,
                          size: 24,
                          color: AppColors.healthWarning,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
