import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

/// iOS 26 Premium Glassmorphism Component Library
/// Reusable widgets for the Falla Premium Design System

class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final bool isSelected;
  final bool isHero;
  final VoidCallback? onTap;

  const GlassCard({
    Key? key,
    required this.child,
    this.borderRadius = 24,
    this.padding = const EdgeInsets.all(20),
    this.isSelected = false,
    this.isHero = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isDark = themeProvider.isDarkMode;
        
        return GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutQuart,
            child: RepaintBoundary(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(borderRadius),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: isDark ? (isHero ? 45 : (isSelected ? 40 : 35)) : (isHero ? 20 : 15),
                    sigmaY: isDark ? (isHero ? 45 : (isSelected ? 40 : 35)) : (isHero ? 20 : 15),
                  ),
                  child: Container(
                    padding: padding,
                    decoration: _getDecoration(isDark),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  BoxDecoration _getDecoration(bool isDark) {
    if (isHero) {
      return isDark 
          ? AppColors.premiumHeroCardDecoration
          : _getLightHeroDecoration();
    } else if (isSelected) {
      return isDark
          ? AppColors.premiumSelectedCardDecoration
          : _getLightSelectedDecoration();
    } else {
      return isDark 
          ? AppColors.darkGlassCardDecoration
          : AppColors.pearlGlassCardDecoration;
    }
  }
  
  BoxDecoration _getLightHeroDecoration() {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.92),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.98),
          AppColors.pearlGlassSemi,
        ],
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: AppColors.aquaIndigo.withOpacity(0.25),
        width: 2,
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.aquaIndigo.withOpacity(0.12),
          blurRadius: 30,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
  
  BoxDecoration _getLightSelectedDecoration() {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.95),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: AppColors.moonlightCyan.withOpacity(0.50),
        width: 2,
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.moonlightCyan.withOpacity(0.18),
          blurRadius: 20,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}

class GlassButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double height;
  final double? width;
  final bool useMoonlight; // Use moonlight cyan instead of gold

  const GlassButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.height = 54,
    this.width,
    this.useMoonlight = false,
  }) : super(key: key);

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isDark = themeProvider.isDarkMode;
        final useGold = isDark || !widget.useMoonlight;
        
        final gradient = useGold 
            ? AppColors.champagneGoldGradient
            : AppColors.moonlightGradient;
        final glowColor = useGold 
            ? AppColors.champagneGold
            : AppColors.moonlightCyan;
        final textColor = useGold 
            ? AppColors.premiumDarkBg
            : AppColors.slateText;
        
        return GestureDetector(
          onTapDown: (_) {
            setState(() => _isPressed = true);
            _glowController.forward();
          },
          onTapUp: (_) {
            setState(() => _isPressed = false);
            _glowController.reverse();
            widget.onPressed?.call();
          },
          onTapCancel: () {
            setState(() => _isPressed = false);
            _glowController.reverse();
          },
          child: AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return AnimatedScale(
                scale: _isPressed ? 0.97 : 1.0,
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOutQuart,
                child: RepaintBoundary(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(widget.height / 2),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: isDark ? 25 : 15, 
                        sigmaY: isDark ? 25 : 15,
                      ),
                      child: Container(
                        height: widget.height,
                        width: widget.width,
                        decoration: BoxDecoration(
                          gradient: gradient,
                          borderRadius: BorderRadius.circular(widget.height / 2),
                          boxShadow: [
                            BoxShadow(
                              color: glowColor.withOpacity(0.35 * _glowAnimation.value),
                              blurRadius: 20 * _glowAnimation.value,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: widget.isLoading
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(textColor),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (widget.icon != null) ...[
                                      Icon(
                                        widget.icon,
                                        color: textColor,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Text(
                                      widget.text,
                                      style: TextStyle(
                                        fontFamily: 'SF Pro Display',
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                        color: textColor,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class GlassBadge extends StatelessWidget {
  final String text;
  final bool isGold;
  final IconData? icon;

  const GlassBadge({
    Key? key,
    required this.text,
    this.isGold = true,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: isGold ? AppColors.champagneGoldGradient : null,
        color: isGold ? null : Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        boxShadow: isGold
            ? [
                BoxShadow(
                  color: AppColors.champagneGold.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 14,
              color: isGold ? AppColors.premiumDarkBg : Colors.white,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontFamily: 'SF Pro Text',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isGold ? AppColors.premiumDarkBg : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blurRadius;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const GlassContainer({
    Key? key,
    required this.child,
    this.blurRadius = 35,
    this.borderRadius = 20,
    this.padding,
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurRadius, sigmaY: blurRadius),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                gradient: AppColors.premiumGlassGradient,
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: AppColors.premiumGlassBorder,
                  width: 1,
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class PremiumScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;

  const PremiumScaffold({
    Key? key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: appBar,
      body: Container(
        decoration: BoxDecoration(
          gradient: themeProvider.backgroundGradient,
        ),
        child: body,
      ),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;

  const GlassAppBar({
    Key? key,
    required this.title,
    this.onBackPressed,
    this.actions,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              left: 8,
              right: 8,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.08),
                  Colors.white.withValues(alpha: 0.04),
                ],
              ),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.10),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                if (onBackPressed != null)
                  IconButton(
                    onPressed: onBackPressed,
                    icon: Icon(
                      Icons.arrow_back_ios,
                      color: AppColors.warmIvory,
                      size: 22,
                    ),
                  )
                else
                  const SizedBox(width: 48),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.getTextPrimary(Provider.of<ThemeProvider>(context).isDarkMode),
                    ),
                  ),
                ),
                if (actions != null)
                  Row(mainAxisSize: MainAxisSize.min, children: actions!)
                else
                  const SizedBox(width: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Premium text styles for easy use
class PremiumTextStyles {
  static TextStyle get display => TextStyle(
        fontFamily: 'SF Pro Display',
        fontSize: 42,
        fontWeight: FontWeight.bold,
        color: AppColors.warmIvory,
        letterSpacing: -0.5,
        height: 1.1,
      );

  static TextStyle get headline => TextStyle(
        fontFamily: 'SF Pro Display',
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.warmIvory,
      );

  static TextStyle get section => TextStyle(
        fontFamily: 'SF Pro Display',
        fontSize: 17,
        fontWeight: FontWeight.w500,
        color: Colors.white.withValues(alpha: 0.9),
      );

  static TextStyle get body => TextStyle(
        fontFamily: 'SF Pro Text',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: Colors.white.withValues(alpha: 0.7),
      );

  static TextStyle get caption => TextStyle(
        fontFamily: 'SF Pro Text',
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: Colors.white.withValues(alpha: 0.5),
      );

  static TextStyle get price => TextStyle(
        fontFamily: 'SF Pro Display',
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.champagneGold,
      );

  static TextStyle get karma => TextStyle(
        fontFamily: 'SF Pro Display',
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.champagneGold,
      );
}
