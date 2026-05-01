import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';

/// Borderless onboarding input used inside the setup flow.
///
/// The global app theme still uses framed inputs elsewhere. This widget keeps
/// onboarding lighter by removing fill, outlines, and underline borders.
class SetupBorderlessTextField extends StatelessWidget {
  const SetupBorderlessTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.icon,
    this.autofocus = false,
    this.textInputAction,
    this.onSubmitted,
    this.suffixLabel,
    this.suffixEnabled = true,
    this.onSuffixPressed,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final String? suffixLabel;
  final bool suffixEnabled;
  final VoidCallback? onSuffixPressed;

  @override
  Widget build(BuildContext context) {
    final suffixLabel = this.suffixLabel;

    return TextField(
      controller: controller,
      autofocus: autofocus,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      style: const TextStyle(
        color: AppColors.ink,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        filled: false,
        fillColor: Colors.transparent,
        hintText: hintText,
        hintStyle: const TextStyle(
          color: AppColors.subtle,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(icon, color: AppColors.muted),
        suffixIcon: suffixLabel == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(right: 2),
                child: TextButton(
                  onPressed: suffixEnabled ? onSuffixPressed : null,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.emeraldDark,
                    disabledForegroundColor: AppColors.subtle.withValues(
                      alpha: .48,
                    ),
                    minimumSize: const Size(70, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  child: Text(suffixLabel),
                ),
              ),
        suffixIconConstraints: const BoxConstraints(
          minWidth: 82,
          minHeight: 44,
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
      ),
    );
  }
}
