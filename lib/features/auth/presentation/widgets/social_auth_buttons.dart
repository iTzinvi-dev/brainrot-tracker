import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../controllers/auth_controller.dart';

/// Social and guest authentication action buttons for Cyber UI.
class SocialAuthButtons extends ConsumerWidget {
  const SocialAuthButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Column(
      children: [
        Row(
          children: [
            const Expanded(
              child: Divider(color: AppColors.border, thickness: 1),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'OR QUICK ACCESS',
                style: TextStyle(
                  color: AppColors.textMuted.withOpacity(0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const Expanded(
              child: Divider(color: AppColors.border, thickness: 1),
            ),
          ],
        ),
        const SizedBox(height: 18),
        // Google Sign In Button
        OutlinedButton(
          key: const Key('google_sign_in_button'),
          onPressed: isLoading
              ? null
              : () => ref.read(authControllerProvider.notifier).signInWithGoogle(),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            backgroundColor: AppColors.surfaceLight,
            side: const BorderSide(color: AppColors.border),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: const Text(
                  'G',
                  style: TextStyle(
                    color: Color(0xFF4285F4),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Continue with Google',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Continue as Guest Button
        TextButton(
          key: const Key('guest_sign_in_button'),
          onPressed: isLoading
              ? null
              : () => ref.read(authControllerProvider.notifier).signInAsGuest(),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.visibility_off_outlined,
                size: 16,
                color: AppColors.textSecondary,
              ),
              SizedBox(width: 8),
              Text(
                'Continue as Guest Operative',
                style: TextStyle(
                  fontSize: 13,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
