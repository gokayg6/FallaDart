import 'dart:ui';
import 'package:flutter/material.dart';

class ZoomBlurRoute extends PageRouteBuilder {
  final Widget page;

  ZoomBlurRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Curves
            final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
            final secondaryCurve = CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeInCubic);

            // 1. Scale Transition (Zoom In)
            // Starts slightly smaller (0.85) and scales to 1.0
            final scale = Tween<double>(begin: 0.85, end: 1.0).animate(curve);

            // 2. Fade Transition (Opacity)
            final fade = Tween<double>(begin: 0.0, end: 1.0).animate(curve);

            // 3. Background Blur Effect (Backdrop)
            // We can't easily blur the *previous* route without a Stack, 
            // but we can fade in a backdrop filter over it.
            return Stack(
              children: [
                // Blur the underlying screen as we transition in
                 FadeTransition(
                  opacity: curve,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(color: Colors.black.withValues(alpha: 0.2)),
                  ),
                ),
                // The incoming page with Scale + Fade
                ScaleTransition(
                  scale: scale,
                  child: FadeTransition(
                    opacity: fade,
                    child: child,
                  ),
                ),
              ],
            );
          },
          transitionDuration: const Duration(milliseconds: 600),
          reverseTransitionDuration: const Duration(milliseconds: 500),
          opaque: false, // Important for the blur to show underlying screen
          barrierDismissible: false,
          barrierColor: Colors.transparent, // Managed manually above
        );
}
