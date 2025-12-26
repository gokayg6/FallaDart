import 'dart:ui';
import 'package:flutter/material.dart';

/// A premium page route that creates a zoom + blur transition effect.
/// The card zooms from its original position to fill the screen while blur increases,
/// then the destination screen unfolds from a scaled-down state.
class ZoomBlurPageRoute<T> extends PageRoute<T> {
  final Widget child;
  final Rect? sourceRect;
  final Color? sourceColor;
  final IconData? sourceIcon;
  final Gradient? sourceGradient;
  
  ZoomBlurPageRoute({
    required this.child,
    this.sourceRect,
    this.sourceColor,
    this.sourceIcon,
    this.sourceGradient,
    super.settings,
  });

  @override
  bool get opaque => false;

  @override
  bool get barrierDismissible => false;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 700);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 500);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return child;
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    final size = MediaQuery.of(context).size;
    
    // Custom curve for premium feel
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: const Cubic(0.25, 0.1, 0.25, 1.0), // Custom cubic bezier
      reverseCurve: Curves.easeOutCubic,
    );

    return AnimatedBuilder(
      animation: curvedAnimation,
      builder: (context, _) {
        final progress = curvedAnimation.value;
        
        // Card zoom phase (0.0 - 0.4)
        final cardZoomProgress = (progress / 0.4).clamp(0.0, 1.0);
        
        // Crossfade phase (0.3 - 0.6)
        final crossfadeProgress = ((progress - 0.3) / 0.3).clamp(0.0, 1.0);
        
        // Unfold phase (0.4 - 1.0)
        final unfoldProgress = ((progress - 0.4) / 0.6).clamp(0.0, 1.0);
        
        // Blur intensity (peaks at 0.4, then decreases)
        final blurPhase1 = (progress / 0.4).clamp(0.0, 1.0); // 0→1 during zoom
        final blurPhase2 = ((progress - 0.4) / 0.6).clamp(0.0, 1.0); // 1→0 during unfold
        final blurIntensity = progress < 0.4 
            ? blurPhase1 * 15.0 
            : (1.0 - blurPhase2) * 15.0;
        
        // Destination screen transform
        // Starts scaled down and blurred, unfolds to normal
        final destinationScale = 0.85 + (unfoldProgress * 0.15);
        final destinationOpacity = crossfadeProgress;
        
        return Stack(
          fit: StackFit.expand,
          children: [
            // Background blur effect
            if (blurIntensity > 0.1)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: blurIntensity,
                    sigmaY: blurIntensity,
                  ),
                  child: Container(
                    color: Colors.black.withOpacity(0.2 * progress),
                  ),
                ),
              ),
            
            // Zooming card overlay (visible during card zoom phase)
            if (cardZoomProgress < 1.0 && sourceRect != null)
              _buildZoomingCard(
                context,
                size,
                cardZoomProgress,
                1.0 - crossfadeProgress,
              ),
            
            // Destination screen (fades in and unfolds)
            if (destinationOpacity > 0)
              Opacity(
                opacity: destinationOpacity,
                child: Transform.scale(
                  scale: destinationScale,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20 * (1.0 - unfoldProgress)),
                    child: child,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildZoomingCard(
    BuildContext context,
    Size screenSize,
    double progress,
    double opacity,
  ) {
    if (sourceRect == null) return const SizedBox.shrink();
    
    // Interpolate from source rect to full screen
    final startRect = sourceRect!;
    final endRect = Rect.fromLTWH(0, 0, screenSize.width, screenSize.height);
    
    // Use a more dramatic easing for the zoom
    final easedProgress = Curves.easeInOutCubic.transform(progress);
    
    final currentLeft = lerpDouble(startRect.left, endRect.left, easedProgress)!;
    final currentTop = lerpDouble(startRect.top, endRect.top, easedProgress)!;
    final currentWidth = lerpDouble(startRect.width, endRect.width, easedProgress)!;
    final currentHeight = lerpDouble(startRect.height, endRect.height, easedProgress)!;
    
    // Border radius animation
    final borderRadius = BorderRadius.circular(
      lerpDouble(16.0, 0.0, easedProgress)!,
    );
    
    return Positioned(
      left: currentLeft,
      top: currentTop,
      width: currentWidth,
      height: currentHeight,
      child: Opacity(
        opacity: opacity,
        child: Container(
          decoration: BoxDecoration(
            gradient: sourceGradient ?? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                (sourceColor ?? Colors.purple).withOpacity(0.9),
                (sourceColor ?? Colors.purple).withOpacity(0.6),
              ],
            ),
            borderRadius: borderRadius,
            boxShadow: [
              BoxShadow(
                color: (sourceColor ?? Colors.purple).withOpacity(0.4 * opacity),
                blurRadius: 30 * easedProgress,
                spreadRadius: 10 * easedProgress,
              ),
            ],
          ),
          child: Center(
            child: Icon(
              sourceIcon ?? Icons.auto_awesome,
              size: lerpDouble(40, 120, easedProgress),
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ),
      ),
    );
  }

  double? lerpDouble(double a, double b, double t) {
    return a + (b - a) * t;
  }
}

/// Helper widget to get GlobalKey and rect for fortune cards
class FortuneCardWrapper extends StatelessWidget {
  final GlobalKey cardKey;
  final Widget child;
  final VoidCallback? onTap;

  const FortuneCardWrapper({
    required this.cardKey,
    required this.child,
    this.onTap,
    super.key,
  });

  /// Get the global rect of this card for animation purposes
  Rect? getCardRect() {
    final RenderBox? renderBox = cardKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;
    final position = renderBox.localToGlobal(Offset.zero);
    return Rect.fromLTWH(
      position.dx,
      position.dy,
      renderBox.size.width,
      renderBox.size.height,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        key: cardKey,
        child: child,
      ),
    );
  }
}
