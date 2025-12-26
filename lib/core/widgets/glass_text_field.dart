import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../constants/app_colors.dart';

class GlassTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final VoidCallback? onTap;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final AutovalidateMode? autovalidateMode;
  final double borderRadius;

  const GlassTextField({
    Key? key,
    this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onTap,
    this.readOnly = false,
    this.onChanged,
    this.autovalidateMode,
    this.borderRadius = 20,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isDark = themeProvider.isDarkMode;
        final textColor = isDark ? Colors.white : AppColors.slateText;
        final labelColor = isDark ? Colors.white70 : AppColors.slateText.withOpacity(0.8);
        final hintColor = isDark ? Colors.white.withOpacity(0.5) : AppColors.slateText.withOpacity(0.5);
        final fillColor = isDark 
            ? Colors.white.withOpacity(0.05)
            : Colors.white.withOpacity(0.4);
        final borderColor = isDark 
            ? Colors.white.withOpacity(0.1)
            : AppColors.moonlightCyan.withOpacity(0.3);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'SF Pro Text',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: labelColor,
                ),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: fillColor,
                    borderRadius: BorderRadius.circular(borderRadius),
                    border: Border.all(color: borderColor),
                  ),
                  child: TextFormField(
                    controller: controller,
                    obscureText: obscureText,
                    keyboardType: keyboardType,
                    validator: validator,
                    autovalidateMode: autovalidateMode,
                    onTap: onTap,
                    readOnly: readOnly,
                    onChanged: onChanged,
                    style: TextStyle(
                      fontFamily: 'SF Pro Text',
                      color: textColor,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: TextStyle(color: hintColor),
                      filled: false, 
                      prefixIcon: prefixIcon != null 
                          ? Icon(prefixIcon, color: isDark ? Colors.white70 : AppColors.aquaIndigo, size: 20)
                          : null,
                      suffixIcon: suffixIcon,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
