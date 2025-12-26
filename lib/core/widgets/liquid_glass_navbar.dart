import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import '../constants/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import 'liquid_glass_effect/liquid_glass_lens_shader.dart';
import 'liquid_glass_effect/shader_painter.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

/// iOS 26-style Liquid Glass Navigation Bar
/// 
/// TWO-LAYER ARCHITECTURE (MANDATORY):
/// Layer 1: Static base glass (passive container)
/// Layer 2: Active liquid blob (interactive, moves and deforms)
class LiquidGlassNavbar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavbarItem> items;
  final GlobalKey? backgroundKey;
  
  const LiquidGlassNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.backgroundKey,
  });
  @override
  State<LiquidGlassNavbar> createState() => _LiquidGlassNavbarState();
}
class _LiquidGlassNavbarState extends State<LiquidGlassNavbar> 
    with TickerProviderStateMixin {
  
  // Blob position and animation state
  late AnimationController _moveController;
  late AnimationController _shimmerController;
  late AnimationController _navbarScaleController;
  late AnimationController _glowController;
  late Animation<double> _moveAnimation;
  late Animation<double> _navbarScaleAnimation;
  late Animation<double> _glowAnimation;
  
  double _blobCenterX = 0.0;
  double _targetBlobX = 0.0;
  double _dragOffset = 0.0;
  double _stretchFactor = 1.0;
  double _blobScaleFactor = 1.0;
  bool _isDragging = false;
  
  static const double _blobBaseWidth = 70.0;
  static const double _blobBaseHeight = 45.0;
  static const double _navbarHeight = 56.0;
  
  // Movement velocity for glow intensity
  double _movementVelocity = 0.0;
  
  // Shader & Capture State
  late LiquidGlassLensShader _liquidGlassLensShader;
  ui.Image? _capturedBackground;
  Timer? _captureTimer;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    
    // Movement animation controller - Slowed for premium heavy feel
    _moveController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    
    // Shimmer animation - Slowed for premium heavy feel
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    // Navbar scale animation - Slowed for premium heavy feel
    _navbarScaleController = AnimationController(
      duration: const Duration(milliseconds: 180),
      vsync: this,
    );
    _navbarScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _navbarScaleController,
      curve: Curves.easeOut,
    ));
    
    // White glow animation - Optimized for 120Hz
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 150),
      reverseDuration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeOut,
    ));
    
    _moveAnimation = CurvedAnimation(
      parent: _moveController,
      curve: Curves.easeOutExpo,
    );
    
    _moveController.addListener(_updateStretchFactor);

    // Initialize Shader
    _liquidGlassLensShader = LiquidGlassLensShader();
    _liquidGlassLensShader.initialize();
    
    // Start continuous capture for liquid glass effect (approx 30fps)
    if (widget.backgroundKey != null) {
      // Wait for layout
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _captureTimer = Timer.periodic(const Duration(milliseconds: 33), (_) {
          if (mounted && !_isCapturing) _captureBackground();
        });
      });
    }
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_blobCenterX == 0.0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _blobCenterX = _calculateBlobX(widget.currentIndex);
            _targetBlobX = _blobCenterX;
          });
        }
      });
    }
  }
  
  @override
  void didUpdateWidget(LiquidGlassNavbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex && !_isDragging) {
      _animateBlobToTab(widget.currentIndex);
    }
  }
  
  @override
  void dispose() {
    _captureTimer?.cancel();
    _capturedBackground?.dispose();
    _moveController.dispose();
    _shimmerController.dispose();
    _navbarScaleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  // Background Capture Logic
  Future<void> _captureBackground() async {
    if (_isCapturing || !mounted || widget.backgroundKey == null) return;
    _isCapturing = true;

    try {
      final boundary = widget.backgroundKey!.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      final navbarBox = context.findRenderObject() as RenderBox?;

      if (boundary == null || !boundary.attached || navbarBox == null || !navbarBox.hasSize) {
        _isCapturing = false;
        return;
      }

      // Calculate Blob Position and Size
      final blobWidth = _blobBaseWidth * _stretchFactor;
      final blobHeight = _blobBaseHeight / math.sqrt(_stretchFactor);
      final blobLeft = _blobCenterX - (blobWidth / 2);
      final blobTop = (_navbarHeight - blobHeight) / 2;

      // Find blob's position relative to the RepaintBoundary
      // 1. Get Navbar's global position
      final navbarGlobalPos = navbarBox.localToGlobal(Offset.zero);
      // 2. Add blob's local offset within Navbar
      //    The blob visual is offset by (blobLeft, blobTop) inside this widget.
      
      final blobGlobalTopLeft = navbarGlobalPos + Offset(blobLeft, blobTop);
      final blobRectGlobal = Rect.fromLTWH(blobGlobalTopLeft.dx, blobGlobalTopLeft.dy, blobWidth, blobHeight);

      // Convert to boundary local coordinates
      final boundaryBox = boundary as RenderBox;
      final blobRectInBoundary = Rect.fromPoints(
        boundaryBox.globalToLocal(blobRectGlobal.topLeft),
        boundaryBox.globalToLocal(blobRectGlobal.bottomRight),
      );

      // Intersect with boundary to ensure we don't capture outside
      final boundaryRect = Rect.fromLTWH(0, 0, boundaryBox.size.width, boundaryBox.size.height);
      final regionToCapture = blobRectInBoundary.intersect(boundaryRect);

      if (regionToCapture.isEmpty || regionToCapture.width <= 0 || regionToCapture.height <= 0) {
        _isCapturing = false;
        return;
      }

      final double pixelRatio = MediaQuery.of(context).devicePixelRatio;
      
      // Efficient capture using OffsetLayer
      final OffsetLayer offsetLayer = boundary.debugLayer! as OffsetLayer;
      final ui.Image optimizedImage = await offsetLayer.toImage(
        regionToCapture,
        pixelRatio: pixelRatio,
      );

      if (mounted) {
        setState(() {
          _capturedBackground?.dispose();
          _capturedBackground = optimizedImage;
        });
      } else {
        optimizedImage.dispose();
      }
    } catch (e) {
      // debugPrint('Capture error: $e');
    } finally {
      if (mounted) _isCapturing = false;
    }
  }
  
  double _calculateBlobX(int index) {
    final screenWidth = MediaQuery.of(context).size.width;
    final navbarWidth = screenWidth - 48; // Updated for left: 24, right: 24
    final iconLayerPadding = 6.0;
    final effectiveWidth = navbarWidth - (iconLayerPadding * 2);
    final itemWidth = effectiveWidth / widget.items.length;
    return iconLayerPadding + (index * itemWidth) + (itemWidth / 2);
  }
  
  void _animateBlobToTab(int targetIndex) {
    final endX = _calculateBlobX(targetIndex);
    _targetBlobX = endX;
    
    _glowController.forward(from: 0.0).then((_) {
      _glowController.reverse();
    });
    
    _shimmerController.forward(from: 0.0);
    
    _moveController.forward(from: 0.0).then((_) {
      setState(() {
        _blobCenterX = endX;
        _stretchFactor = 1.0;
        _blobScaleFactor = 1.0;
      });
    });
  }
  
  void _updateStretchFactor() {
    final progress = _moveAnimation.value;
    const maxStretch = 0.65;
    const stretchAmount = 1.0 - maxStretch;
    final stretch = 1.0 + stretchAmount * (1.0 - 4 * math.pow(progress - 0.5, 2));
    
    final blobScale = progress < 0.35
        ? 1.0 + (progress / 0.35) * 0.4
        : 1.4 - ((progress - 0.35) / 0.65) * 0.4;
    
    final velocity = _moveController.velocity.abs();
    
    setState(() {
      _stretchFactor = stretch.clamp(maxStretch, 1.3);
      _blobScaleFactor = blobScale.clamp(1.0, 1.4);
      _movementVelocity = velocity;
      
      if (_targetBlobX != 0.0) {
        final startX = _calculateBlobX(widget.currentIndex);
        _blobCenterX = startX + (_targetBlobX - startX) * progress;
      }
    });
  }
  
  void _handlePanUpdate(DragUpdateDetails details) {
    setState(() {
      _isDragging = true;
      _dragOffset += details.delta.dx;
      
      final targetX = _calculateBlobX(widget.currentIndex) + _dragOffset;
      _blobCenterX = _blobCenterX + (targetX - _blobCenterX) * 0.3;
      
      final velocity = details.delta.dx.abs();
      _stretchFactor = 1.0 + (velocity * 0.015).clamp(0.0, 0.18);
    });
  }
  
  void _handlePanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
      _dragOffset = 0.0;
    });
    _animateBlobToTab(widget.currentIndex);
  }
  
  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Positioned(
      left: 24,
      right: 24,
      bottom: bottomPadding + 18,
      child: GestureDetector(
        onPanUpdate: _handlePanUpdate,
        onPanEnd: _handlePanEnd,
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _navbarScaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _navbarScaleAnimation.value,
                child: child,
              );
            },
            child: _buildTwoLayerNavbar(),
          ),
        ),
      ),
    );
  }
  
  Widget _buildTwoLayerNavbar() {
    return SizedBox(
      height: _navbarHeight,
      child: Stack(
        children: [
          RepaintBoundary(
            child: _buildStaticBaseGlass(),
          ),
          
          // Smooth glow overlay - fixed flickering with stable opacity
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              final glowValue = _glowAnimation.value;
              if (glowValue < 0.01) return const SizedBox.shrink();
              return Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity((0.35 * glowValue).clamp(0.0, 0.35)),
                          Colors.white.withOpacity((0.25 * glowValue).clamp(0.0, 0.25)),
                          Colors.white.withOpacity((0.15 * glowValue).clamp(0.0, 0.15)),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          
          _buildLiquidBlobLayer(),
          
          RepaintBoundary(
            child: _buildIconLayer(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStaticBaseGlass() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: LiquidGlassLayer(
        settings: const LiquidGlassSettings(
          thickness: 20,
          blur: 10,
          glassColor: Color(0x33FFFFFF),
          lightIntensity: 1.0,
        ),
        child: LiquidGlass(
          shape: const LiquidRoundedSuperellipse(borderRadius: 24),
          child: Container(
            height: _navbarHeight,
            // Container color removed as glassColor handles it now
          ),
        ),
      ),
    );
  }
  
  // Use moonlight cyan color for active state (ultra-premium design)
  Color _getActiveColor(bool isDark) => AppColors.getNavbarActiveColor(isDark);
  Color _getInactiveColor(bool isDark) => AppColors.getNavbarInactiveColor(isDark);

  Widget _buildLiquidBlobLayer() {
    final blobWidth = _blobBaseWidth * _stretchFactor;
    final blobHeight = _blobBaseHeight / math.sqrt(_stretchFactor);
    final isMoving = _moveController.isAnimating || _isDragging;
    final glowIntensity = isMoving ? (_movementVelocity * 0.8).clamp(0.0, 1.6) : 0.0;
    
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main blob
        AnimatedPositioned(
          duration: _isDragging 
              ? Duration.zero 
              : const Duration(milliseconds: 400),
          curve: Curves.easeOutBack,
          left: _blobCenterX - (blobWidth / 2),
          top: (_navbarHeight - blobHeight) / 2,
          child: Transform.scale(
            scale: _blobScaleFactor,
            child: LiquidGlassLayer(
              settings: LiquidGlassSettings(
                thickness: 10,
                glassColor: const Color(0x16FFFFFF),
                lightIntensity: 0.9 + (glowIntensity * 0.3),
              ),
              child: LiquidGlass(
                shape: LiquidRoundedSuperellipse(
                  borderRadius: blobHeight * 0.45,
                ),
                child: Container(
                  width: blobWidth,
                  height: blobHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(blobHeight * 0.45),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.22 + (glowIntensity * 0.08)),
                        Colors.white.withOpacity(0.12 + (glowIntensity * 0.05)),
                      ],
                    ),
                    boxShadow: isMoving ? [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.10 * glowIntensity),
                        blurRadius: 14 * glowIntensity,
                        spreadRadius: 2,
                      ),
                    ] : null,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildIconLayer() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(widget.items.length, (index) {
          final item = widget.items[index];
          final isSelected = index == widget.currentIndex;
          
          return Expanded(
            child: _NavbarIconWidget(
              item: item,
              isSelected: isSelected,
              onTap: () {
                HapticFeedback.selectionClick();
                _navbarScaleController.forward().then((_) {
                  _navbarScaleController.reverse();
                });
                widget.onTap(index);
              },
              activeColor: _getActiveColor(isDark),
              inactiveColor: _getInactiveColor(isDark),
            ),
          );
        }),
      ),
    );
  }
}

class NavbarItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  
  const NavbarItem({
    required this.icon,
    this.activeIcon,
    required this.label,
  });
}

class _NavbarIconWidget extends StatefulWidget {
  final NavbarItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final Color activeColor;
  final Color inactiveColor;
  
  const _NavbarIconWidget({
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.activeColor,
    required this.inactiveColor,
  });
  @override
  State<_NavbarIconWidget> createState() => _NavbarIconWidgetState();
}

class _NavbarIconWidgetState extends State<_NavbarIconWidget> 
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: AppTheme.durationFast,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: AppTheme.curveSpring,
    ));
    
    if (widget.isSelected) {
      _scaleController.value = 1.0;
    }
  }
  
  @override
  void didUpdateWidget(_NavbarIconWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _scaleController.forward();
    } else if (!widget.isSelected && oldWidget.isSelected) {
      _scaleController.reverse();
    }
  }
  
  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: SizedBox(
          height: 56,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.isSelected 
                    ? (widget.item.activeIcon ?? widget.item.icon)
                    : widget.item.icon,
                size: 22,
                color: widget.isSelected 
                    ? widget.activeColor 
                    : widget.inactiveColor,
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: AppTheme.durationNormal,
                style: AppTypography.tabLabel(
                  color: widget.isSelected 
                      ? widget.activeColor 
                      : widget.inactiveColor,
                ),
                child: Text(widget.item.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
