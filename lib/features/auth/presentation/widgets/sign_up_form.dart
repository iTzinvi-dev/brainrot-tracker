import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/security/input_sanitizer.dart';
import '../controllers/auth_controller.dart';
import 'password_text_field.dart';

class SignUpForm extends ConsumerStatefulWidget {
  const SignUpForm({super.key});

  @override
  ConsumerState<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends ConsumerState<SignUpForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String _password = '';

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      setState(() {
        _password = _passwordController.text;
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      if (!InputSanitizer.isStrongPassword(_password)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password must meet all 5 security requirements.'),
            backgroundColor: AppColors.healthDanger,
          ),
        );
        return;
      }

      ref.read(authControllerProvider.notifier).signUpWithEmail(
            _emailController.text.trim(),
            _password,
            displayName: _nameController.text.trim(),
          );
    }
  }

  Widget _buildRequirement(String label, bool satisfied) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            satisfied ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 14,
            color: satisfied ? AppColors.healthSuccess : AppColors.textMuted,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: satisfied ? AppColors.textPrimary : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    final hasLength = InputSanitizer.hasMinLength(_password, 8);
    final hasUpper = InputSanitizer.hasUppercase(_password);
    final hasLower = InputSanitizer.hasLowercase(_password);
    final hasDigit = InputSanitizer.hasDigit(_password);
    final hasSpecial = InputSanitizer.hasSpecialChar(_password);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (authState.errorMessage != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.healthDanger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.healthDanger.withOpacity(0.6)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.healthDanger,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      authState.errorMessage!,
                      style: const TextStyle(
                        color: AppColors.healthDanger,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          TextFormField(
            key: const Key('sign_up_name_field'),
            controller: _nameController,
            enabled: !authState.isLoading,
            textInputAction: TextInputAction.next,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
            decoration: InputDecoration(
              labelText: 'Operative Codename',
              hintText: 'e.g. CyberAgent007',
              labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              filled: true,
              fillColor: AppColors.surfaceLight,
              prefixIcon: const Icon(
                Icons.person_outline_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('sign_up_email_field'),
            controller: _emailController,
            enabled: !authState.isLoading,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter an email';
              }
              if (!InputSanitizer.isValidEmail(value)) {
                return 'Enter a valid email address';
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: 'Email Address',
              hintText: 'operative@brainrot.app',
              labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              filled: true,
              fillColor: AppColors.surfaceLight,
              prefixIcon: const Icon(
                Icons.email_outlined,
                color: AppColors.primary,
                size: 20,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.healthDanger),
              ),
            ),
          ),
          const SizedBox(height: 16),
          PasswordTextField(
            key: const Key('sign_up_password_field'),
            controller: _passwordController,
            enabled: !authState.isLoading,
            label: 'Create Secure Password',
            onFieldSubmitted: (_) => _submit(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please create a password';
              }
              if (!InputSanitizer.isStrongPassword(value)) {
                return 'Must satisfy all 5 complexity criteria';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Password Requirements:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                _buildRequirement('At least 8 characters', hasLength),
                _buildRequirement('One uppercase letter [A-Z]', hasUpper),
                _buildRequirement('One lowercase letter [a-z]', hasLower),
                _buildRequirement('One numeric digit [0-9]', hasDigit),
                _buildRequirement('One special character (!@#\$%^&*)', hasSpecial),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            key: const Key('sign_up_submit_button'),
            onPressed: authState.isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.background,
              disabledBackgroundColor: AppColors.surfaceLight,
              disabledForegroundColor: AppColors.textMuted,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: authState.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.background),
                    ),
                  )
                : const Text(
                    'CREATE OPERATIVE ACCOUNT',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 1.0,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
