import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Cyber-styled password text field with interactive visibility toggle.
class PasswordTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String? Function(String?)? validator;
  final bool enabled;
  final TextInputAction textInputAction;
  final void Function(String)? onFieldSubmitted;

  const PasswordTextField({
    super.key,
    required this.controller,
    this.label = 'Password',
    this.hint = 'Enter your password',
    this.validator,
    this.enabled = true,
    this.textInputAction = TextInputAction.done,
    this.onFieldSubmitted,
  });

  @override
  State<PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscureText,
      enabled: widget.enabled,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 15,
      ),
      validator: widget.validator,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        filled: true,
        fillColor: AppColors.surfaceLight,
        prefixIcon: const Icon(
          Icons.lock_outline_rounded,
          color: AppColors.primary,
          size: 20,
        ),
        suffixIcon: IconButton(
          key: const Key('password_visibility_toggle'),
          icon: Icon(
            _obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
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
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.healthDanger, width: 1.5),
        ),
      ),
    );
  }
}
