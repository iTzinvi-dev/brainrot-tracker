import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/security/input_sanitizer.dart';
import '../controllers/auth_controller.dart';
import 'password_text_field.dart';

/// Modal dialog allowing a guest operative to permanently secure their account
/// while strictly preserving their local stats, streaks, and brain rot pet data.
class GuestUpgradeDialog extends ConsumerStatefulWidget {
  const GuestUpgradeDialog({super.key});

  @override
  ConsumerState<GuestUpgradeDialog> createState() => _GuestUpgradeDialogState();
}

class _GuestUpgradeDialogState extends ConsumerState<GuestUpgradeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _useGoogle = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _upgradeWithEmail() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(authControllerProvider.notifier).upgradeGuestWithEmail(
            _emailController.text.trim(),
            _passwordController.text,
            displayName: _nameController.text.trim(),
          );
      Navigator.of(context).pop();
    }
  }

  void _upgradeWithGoogle() {
    ref.read(authControllerProvider.notifier).upgradeGuestWithGoogle();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'UPGRADE ACCOUNT',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 0.8,
                            ),
                          ),
                          Text(
                            'Preserve all stats and streaks',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Text(
                    'Upgrading preserves your unique Operative ID and seamlessly links all recorded doomscroll history and streaks.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  enabled: !authState.isLoading,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Operative Name',
                    labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  enabled: !authState.isLoading,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Enter email';
                    if (!InputSanitizer.isValidEmail(value)) return 'Invalid email';
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                PasswordTextField(
                  controller: _passwordController,
                  enabled: !authState.isLoading,
                  label: 'Password',
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Enter password';
                    if (!InputSanitizer.isStrongPassword(value)) {
                      return 'Must meet 5-point requirements';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  key: const Key('guest_upgrade_email_button'),
                  onPressed: authState.isLoading ? null : _upgradeWithEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text(
                    'UPGRADE VIA EMAIL',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  key: const Key('guest_upgrade_google_button'),
                  onPressed: authState.isLoading ? null : _upgradeWithGoogle,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text(
                    'Link Google Account',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
