import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/animation_service.dart';
import 'animated_card.dart';

/// Oracle kartı bileşeni
/// Mistik oracle kartı gösterimi ve animasyonları
class OracleCard extends StatefulWidget {
  final String cardName;
  final String cardDescription;
  final String cardMessage;
  final String cardImagePath;
  final String cardCategory;
  final bool isSelected;
  final bool isRevealed;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool enableFlipAnimation;
  final bool enableGlow;
  final bool enableParticles;
  final bool isPremium;
  final double? width;
  final double? height;

  const OracleCard({
    super.key,
    required this.cardName,
    required this.cardDescription,
    required this.cardMessage,
    required this.cardImagePath,
    required this.cardCategory,
    this.isSelected = false,
    this.isRevealed = false,
    this.onTap,
    this.onLongPress,
    this.enableFlipAnimation = true,
    this.enableGlow = true,
    this.enableParticles = true,
    this.isPremium = false,
    this.width,
    this.height,
  });

  @override
  State<OracleCard> createState() => _OracleCardState();
}

class _OracleCardState extends State<OracleCard>
    with TickerProviderStateMixin {
  late AnimationController _flipController;
  late AnimationController _glowController;
  late AnimationController _particleController;
  late AnimationController _revealController;
  late AnimationController _floatController;

  late Animation<double> _flipAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _particleAnimation;
  late Animation<double> _revealAnimation;
  late Animation<double> _floatAnimation;

  bool _isFlipped = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    // Flip controller
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Glow controller
    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Particle controller
    _particleController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    // Reveal controller
    _revealController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Float controller
    _floatController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Initialize animations
    _flipAnimation = AnimationService.createCardFlipAnimation(_flipController);
    _glowAnimation = AnimationService.createEtherealGlowAnimation(_glowController);
    _particleAnimation = AnimationService.createMagicalParticleAnimation(_particleController);
    _revealAnimation = AnimationService.createFadeInAnimation(_revealController);
    _floatAnimation = AnimationService.createEtherealFloatAnimation(_floatController);
  }

  void _startAnimations() {
    if (widget.enableGlow) {
      // Blinking animation disabled
      // _glowController.repeat(reverse: true);
    }
    if (widget.enableParticles) {
      // Blinking animation disabled
      // _particleController.repeat();
    }
    if (widget.isRevealed) {
      _revealController.forward();
    }
    _floatController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(OracleCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRevealed != oldWidget.isRevealed) {
      if (widget.isRevealed) {
        _revealController.forward();
      } else {
        _revealController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    _glowController.dispose();
    _particleController.dispose();
    _revealController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  void _onTap() {
    if (widget.enableFlipAnimation) {
      setState(() {
        _isFlipped = !_isFlipped;
      });
      if (_isFlipped) {
        _flipController.forward();
      } else {
        _flipController.reverse();
      }
    }
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _flipAnimation,
        _glowAnimation,
        _particleAnimation,
        _revealAnimation,
        _floatAnimation,
      ]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(_flipAnimation.value),
            child: _isFlipped ? _buildCardBack() : _buildCardFront(),
          ),
        );
      },
    );
  }

  Widget _buildCardFront() {
    return AnimatedCard(
      onTap: _onTap,
      onLongPress: widget.onLongPress,
      width: widget.width,
      height: widget.height,
      enableGlow: widget.enableGlow && widget.isSelected,
      enablePulse: widget.isSelected,
      enableShimmer: widget.enableParticles,
      enableFloat: true,
      isPremium: widget.isPremium,
      isMystical: true,
      backgroundColor: _getCardColor(),
      borderColor: _getBorderColor(),
      elevation: widget.isSelected ? 16 : 8,
      child: Stack(
        children: [
          // Card background
          _buildCardBackground(),
          
          // Card content
          _buildCardContent(),
          
          // Particles overlay
          if (widget.enableParticles)
            _buildParticlesOverlay(),
          
          // Glow overlay
          if (widget.enableGlow && widget.isSelected)
            _buildGlowOverlay(),
        ],
      ),
    );
  }

  Widget _buildCardBack() {
    return AnimatedCard(
      onTap: _onTap,
      onLongPress: widget.onLongPress,
      width: widget.width,
      height: widget.height,
      enableGlow: widget.enableGlow,
      enablePulse: false,
      enableShimmer: false,
      enableFloat: true,
      isPremium: widget.isPremium,
      isMystical: true,
      backgroundColor: _getCardBackColor(),
      borderColor: _getBorderColor(),
      elevation: 8,
      child: Stack(
        children: [
          // Card back background
          _buildCardBackBackground(),
          
          // Card back content
          _buildCardBackContent(),
        ],
      ),
    );
  }

  Widget _buildCardBackground() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getCardColor(),
            _getCardColor().withValues(alpha: 0.7),
            _getCardColor().withValues(alpha: 0.9),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }

  Widget _buildCardContent() {
    return Opacity(
      opacity: _revealAnimation.value,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Card image
          _buildCardImage(),
          
          const SizedBox(height: 16),
          
          // Card name
          _buildCardName(),
          
          const SizedBox(height: 8),
          
          // Card category
          _buildCardCategory(),
          
          const SizedBox(height: 12),
          
          // Card description
          _buildCardDescription(),
          
          // Selected indicator
          if (widget.isSelected)
            _buildSelectedIndicator(),
        ],
      ),
    );
  }

  Widget _buildCardImage() {
    return Container(
      width: 100,
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: AssetImage(widget.cardImagePath),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
    );
  }

  Widget _buildCardName() {
    return Text(
      widget.cardName,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: _getTextColor(),
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildCardCategory() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getCategoryColor().withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getCategoryColor(),
          width: 1,
        ),
      ),
      child: Text(
        widget.cardCategory,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _getCategoryColor(),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCardDescription() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        widget.cardDescription,
        style: TextStyle(
          fontSize: 14,
          color: _getTextColor().withValues(alpha: 0.9),
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        textAlign: TextAlign.center,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildSelectedIndicator() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getBorderColor().withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getBorderColor(), width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star,
            size: 16,
            color: _getBorderColor(),
          ),
          const SizedBox(width: 4),
          Text(
            'SEÇİLDİ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _getBorderColor(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardBackBackground() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getCardBackColor(),
            _getCardBackColor().withValues(alpha: 0.8),
            _getCardBackColor().withValues(alpha: 0.6),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }

  Widget _buildCardBackContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Oracle symbol
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getCardBackColor().withValues(alpha: 0.3),
            border: Border.all(
              color: _getBorderColor(),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: _getBorderColor().withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Icon(
            Icons.auto_awesome,
            size: 40,
            color: _getBorderColor(),
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Oracle text
        Text(
          'ORACLE',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _getBorderColor(),
            letterSpacing: 3,
            shadows: [
              Shadow(
                color: _getBorderColor().withValues(alpha: 0.5),
                blurRadius: 10,
                offset: const Offset(0, 0),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 8),
        
        Text(
          AppStrings.mysticalCards,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _getBorderColor().withValues(alpha: 0.8),
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildParticlesOverlay() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _particleAnimation,
        builder: (context, child) {
          return CustomPaint(
            painter: _OracleParticlePainter(
              animation: _particleAnimation.value,
              color: _getBorderColor(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGlowOverlay() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.9 + (_glowAnimation.value * 0.3),
                colors: [
                  _getBorderColor().withValues(alpha: _glowAnimation.value * 0.4),
                  Colors.transparent,
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getCardColor() {
    if (widget.isPremium) {
      return AppColors.premium.withValues(alpha: 0.1);
    }
    if (widget.isSelected) {
      return AppColors.primary.withValues(alpha: 0.1);
    }
    return AppColors.surface;
  }

  Color _getCardBackColor() {
    if (widget.isPremium) {
      return AppColors.premium.withValues(alpha: 0.05);
    }
    return AppColors.surface.withValues(alpha: 0.8);
  }

  Color _getBorderColor() {
    if (widget.isPremium) {
      return AppColors.premium;
    }
    if (widget.isSelected) {
      return AppColors.primary;
    }
    return AppColors.secondary;
  }

  Color _getTextColor() {
    if (widget.isPremium) {
      return AppColors.premium;
    }
    return AppColors.textPrimary;
  }

  Color _getCategoryColor() {
    switch (widget.cardCategory.toLowerCase()) {
      case 'aşk':
        return Colors.pink;
      case 'kariyer':
        return Colors.blue;
      case 'sağlık':
        return Colors.green;
      case 'para':
        return Colors.amber;
      case 'aile':
        return Colors.purple;
      case 'arkadaşlık':
        return Colors.orange;
      case 'spiritüel':
        return Colors.indigo;
      case 'gelecek':
        return Colors.cyan;
      default:
        return AppColors.secondary;
    }
  }
}

class _OracleParticlePainter extends CustomPainter {
  final double animation;
  final Color color;

  _OracleParticlePainter({
    required this.animation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;

    // Draw ethereal particles
    for (int i = 0; i < 12; i++) {
      final angle = (animation * 2 * 3.14159) + (i * 3.14159 / 6);
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      
      final particleSize = 3 + (math.sin(animation * 3.14159 + i) * 2);
      
      canvas.drawCircle(
        Offset(x, y),
        particleSize,
        paint,
      );
    }

    // Draw mystical sparkles
    for (int i = 0; i < 6; i++) {
      final angle = (animation * 3.14159) + (i * 3.14159 / 3);
      final x = center.dx + (radius * 0.6) * math.cos(angle);
      final y = center.dy + (radius * 0.6) * math.sin(angle);
      
      final sparkleSize = 1 + (math.cos(animation * 2 * 3.14159 + i) * 1);
      
      canvas.drawCircle(
        Offset(x, y),
        sparkleSize,
        paint..color = color.withValues(alpha: 0.6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
