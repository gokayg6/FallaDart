import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/pricing_constants.dart';
import '../../core/providers/user_provider.dart';
import '../../providers/theme_provider.dart';

import '../../core/widgets/mystical_button.dart';
import '../../core/widgets/mystical_card.dart';
import '../../core/widgets/mystical_loading.dart';
import '../../core/widgets/zoom_blur_page_route.dart';
import 'tarot_fortune_screen.dart';
import '../kahve_fali/coffee_fortune_reader_screen.dart';
import '../fortune/coffee_fortune_screen.dart';
import 'palm_fortune_screen.dart';
import '../astrology/astrology_screen.dart';
import 'face_fortune_screen.dart';
import 'katina_fortune_screen.dart';
import 'dream_interpretation_screen.dart';

enum FortuneTarget {
  myself,
  someone,
}

class FortuneSelectionScreen extends StatefulWidget {
  const FortuneSelectionScreen({Key? key}) : super(key: key);

  @override
  State<FortuneSelectionScreen> createState() => _FortuneSelectionScreenState();
}

class _FortuneSelectionScreenState extends State<FortuneSelectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _cardController;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _cardAnimation;
  
  FortuneTarget _selectedTarget = FortuneTarget.myself;
  String? _selectedFortuneType;
  bool _isLoading = false;
  
  // GlobalKeys for fortune cards (for zoom animation)
  final Map<String, GlobalKey> _cardKeys = {
    'tarot': GlobalKey(),
    'coffee': GlobalKey(),
    'palm': GlobalKey(),
    'astrology': GlobalKey(),
    'face': GlobalKey(),
    'katina': GlobalKey(),
    'dream': GlobalKey(),
  };
  
  // Card info for animation
  final Map<String, Map<String, dynamic>> _cardInfo = {
    'tarot': {'icon': Icons.auto_awesome, 'gradient': AppColors.mysticalGradient},
    'coffee': {'icon': Icons.local_cafe, 'gradient': AppColors.cardGradient},
    'palm': {'icon': Icons.back_hand, 'gradient': AppColors.secondaryGradient},
    'astrology': {'icon': Icons.star, 'gradient': AppColors.accentGradient},
    'face': {'icon': Icons.face, 'gradient': AppColors.secondaryGradient},
    'katina': {'icon': Icons.auto_awesome, 'gradient': AppColors.mysticalGradient},
    'dream': {'icon': Icons.bedtime, 'gradient': AppColors.cardGradient},
  };

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));
    
    _cardAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: Curves.elasticOut,
    ));
    
    // Blinking animation disabled
    // _backgroundController.repeat(reverse: true);
    _cardController.forward();
  }

  void _selectFortuneType(String fortuneType) {
    // Directly navigate with zoom animation when card is tapped
    _navigateToFortune(fortuneType);
  }
  
  Future<void> _navigateToFortune(String fortuneType) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final requiredKarma = PricingConstants.getFortuneCost(fortuneType);
    
    // Debug modunda karma kontrolü bypass
    if (!kDebugMode) {
      if (!(userProvider.user?.canUseDailyFortune ?? false) && (userProvider.user?.karma ?? 0) < requiredKarma) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.notEnoughKarma}. Gerekli: $requiredKarma karma'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }
    
    // Get fortune screen
    Widget fortuneScreen;
    switch (fortuneType) {
      case 'tarot':
        fortuneScreen = const TarotFortuneScreen();
        break;
      case 'coffee':
        fortuneScreen = const CoffeeFortuneScreen();
        break;
      case 'palm':
        fortuneScreen = const PalmFortuneScreen();
        break;
      case 'astrology':
        fortuneScreen = const AstrologyScreen();
        break;
      case 'face':
        fortuneScreen = const FaceFortuneScreen();
        break;
      case 'katina':
        fortuneScreen = const KatinaFortuneScreen();
        break;
      case 'dream':
        fortuneScreen = const DreamInterpretationScreen();
        break;
      default:
        return;
    }
    
    // Get card rect for zoom animation
    Rect? cardRect;
    final cardKey = _cardKeys[fortuneType];
    if (cardKey?.currentContext != null) {
      final RenderBox? renderBox = cardKey!.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final position = renderBox.localToGlobal(Offset.zero);
        cardRect = Rect.fromLTWH(
          position.dx,
          position.dy,
          renderBox.size.width,
          renderBox.size.height,
        );
      }
    }
    
    final info = _cardInfo[fortuneType];
    
    // Navigate with simple fade+slide animation (same as tarot opening)
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => fortuneScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.15),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _startFortune() async {
    if (_selectedFortuneType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.selectFortuneType),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    // Get the required karma for selected fortune type
    final requiredKarma = PricingConstants.getFortuneCost(_selectedFortuneType!);
    
    // Debug modunda karma kontrolü bypass
    if (!kDebugMode) {
      // Check if user has enough karma or daily fortune available
      if (!(userProvider.user?.canUseDailyFortune ?? false) && (userProvider.user?.karma ?? 0) < requiredKarma) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.notEnoughKarma}. Gerekli: $requiredKarma karma'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Navigate to specific fortune screen based on selection
      Widget fortuneScreen;
      switch (_selectedFortuneType) {
        case 'tarot':
          fortuneScreen = const TarotFortuneScreen();
          break;
        case 'coffee':
          fortuneScreen = const CoffeeFortuneScreen();
          break;
        case 'palm':
          fortuneScreen = const PalmFortuneScreen();
          break;
        case 'astrology':
          fortuneScreen = const AstrologyScreen();
          break;
        case 'face':
          fortuneScreen = const FaceFortuneScreen();
          break;
        case 'katina':
          fortuneScreen = const KatinaFortuneScreen();
          break;
        case 'dream':
          fortuneScreen = const DreamInterpretationScreen();
          break;
        default:
          throw Exception('Unknown fortune type: $_selectedFortuneType');
      }

      // Get card rect for zoom animation
      Rect? cardRect;
      final cardKey = _cardKeys[_selectedFortuneType];
      if (cardKey?.currentContext != null) {
        final RenderBox? renderBox = cardKey!.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final position = renderBox.localToGlobal(Offset.zero);
          cardRect = Rect.fromLTWH(
            position.dx,
            position.dy,
            renderBox.size.width,
            renderBox.size.height,
          );
        }
      }
      
      final info = _cardInfo[_selectedFortuneType];
      
      await Navigator.push(
        context,
        ZoomBlurPageRoute(
          child: fortuneScreen,
          sourceRect: cardRect,
          sourceIcon: info?['icon'] as IconData?,
          sourceGradient: info?['gradient'] as Gradient?,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppStrings.error}: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
              gradient: themeProvider.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
                  _buildAppBar(isDark),
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                                _buildHeader(isDark),
                            const SizedBox(height: 32),
                                _buildTargetSelection(isDark),
                            const SizedBox(height: 32),
                                _buildFortuneTypeSelection(isDark),
                            const SizedBox(height: 32),
                                _buildStartButton(isDark),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
        );
      },
    );
  }

  Widget _buildAppBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios,
              color: AppColors.getIconColor(isDark),
            ),
          ),
          Expanded(
            child: Text(
              AppStrings.selectFortune,
              style: AppTextStyles.headingMedium.copyWith(
                color: AppColors.getTextPrimary(isDark),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          MysticalLoadingWidget.stars(
            size: 80,
            color: AppColors.primary,
            message: AppStrings.preparingFortune,
            showMessage: true,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final cardBgColor = AppColors.getCardBackground(isDark);
    
    return AnimatedBuilder(
      animation: _backgroundAnimation,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cardBgColor.withValues(alpha: isDark ? (0.8 + (_backgroundAnimation.value * 0.2)) : 1.0),
                cardBgColor.withValues(alpha: isDark ? (0.6 + (_backgroundAnimation.value * 0.2)) : 0.95),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: isDark ? (0.2 + (_backgroundAnimation.value * 0.1)) : 0.1),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 48,
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.chooseYourPath,
                style: AppTextStyles.headingMedium.copyWith(
                  color: AppColors.getTextPrimary(isDark),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.selectFortuneDesc,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.getTextSecondary(isDark),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTargetSelection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.fortuneFor,
          style: AppTextStyles.headingSmall.copyWith(
            color: AppColors.getTextPrimary(isDark),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 140,
                child: _buildTargetCard(
                  target: FortuneTarget.myself,
                  title: AppStrings.forMyself,
                  subtitle: AppStrings.forMyselfDesc,
                  icon: Icons.person,
                  isDark: isDark,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 140,
                child: _buildTargetCard(
                  target: FortuneTarget.someone,
                  title: AppStrings.forSomeoneElse,
                  subtitle: AppStrings.forSomeoneDesc,
                  icon: Icons.people,
                  isDark: isDark,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTargetCard({
    required FortuneTarget target,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isDark,
  }) {
    final isSelected = _selectedTarget == target;
    final cardBgColor = AppColors.getCardBackground(isDark);
    
    return MysticalCard(
      onTap: () {
        setState(() {
          _selectedTarget = target;
        });
      },
      isSelected: isSelected,
      showGlow: false,
      toggleFlipOnTap: false,
      padding: EdgeInsets.zero,
        child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          gradient: isSelected 
              ? AppColors.primaryGradient 
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.secondary.withValues(alpha: isDark ? 0.2 : 0.1),
                    cardBgColor.withValues(alpha: isDark ? 0.8 : 1.0),
                  ],
                ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? AppColors.primary.withValues(alpha: 0.5)
                : AppColors.primary.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? Colors.white : AppColors.getIconColor(isDark),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isSelected ? Colors.white : AppColors.getTextPrimary(isDark),
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                subtitle,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isSelected ? Colors.white70 : AppColors.getTextSecondary(isDark),
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFortuneTypeSelection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.fortuneTypes,
          style: AppTextStyles.headingSmall.copyWith(
            color: AppColors.getTextPrimary(isDark),
          ),
        ),
        const SizedBox(height: 16),
        AnimatedBuilder(
          animation: _cardAnimation,
          builder: (context, child) {
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
              children: [
                _buildFortuneTypeCard(
                  type: 'tarot',
                  title: AppStrings.tarot,
                  subtitle: AppStrings.tarotDesc,
                  icon: Icons.auto_awesome,
                  gradient: AppColors.mysticalGradient,
                  delay: 0,
                  isDark: isDark,
                ),
                _buildFortuneTypeCard(
                  type: 'coffee',
                  title: AppStrings.coffee,
                  subtitle: AppStrings.coffeeDesc,
                  icon: Icons.local_cafe,
                  gradient: AppColors.cardGradient,
                  delay: 100,
                  isDark: isDark,
                ),
                _buildFortuneTypeCard(
                  type: 'palm',
                  title: AppStrings.palm,
                  subtitle: AppStrings.palmDesc,
                  icon: Icons.back_hand,
                  gradient: AppColors.secondaryGradient,
                  delay: 200,
                  isDark: isDark,
                ),
                _buildFortuneTypeCard(
                  type: 'astrology',
                  title: AppStrings.astrology,
                  subtitle: AppStrings.astrologyDesc,
                  icon: Icons.star,
                  gradient: AppColors.accentGradient,
                  delay: 300,
                  isDark: isDark,
                ),
                _buildFortuneTypeCard(
                  type: 'face',
                  title: AppStrings.faceFortune,
                  subtitle: AppStrings.faceDesc,
                  icon: Icons.face,
                  gradient: AppColors.secondaryGradient,
                  delay: 400,
                  isDark: isDark,
                ),
                _buildFortuneTypeCard(
                  type: 'katina',
                  title: AppStrings.katinaFortune,
                  subtitle: AppStrings.katinaDesc,
                  icon: Icons.auto_awesome,
                  gradient: AppColors.mysticalGradient,
                  delay: 500,
                  isDark: isDark,
                ),
                _buildFortuneTypeCard(
                  type: 'dream',
                  title: AppStrings.dreamInterpretation,
                  subtitle: AppStrings.dreamDesc,
                  icon: Icons.bedtime,
                  gradient: AppColors.cardGradient,
                  delay: 600,
                  isDark: isDark,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildFortuneTypeCard({
    required String type,
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required int delay,
    required bool isDark,
  }) {
    final isSelected = _selectedFortuneType == type;
    final cardBgColor = AppColors.getCardBackground(isDark);
    
    // Use the GlobalKey for this card type
    final cardKey = _cardKeys[type];
    
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            key: cardKey,
            child: MysticalCard(
              onTap: () => _selectFortuneType(type),
              isSelected: isSelected,
              aspectRatio: 0.85,
              showGlow: false,
              toggleFlipOnTap: false,
              padding: EdgeInsets.zero,
              child: Container(
              width: double.infinity,
              height: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: isSelected 
                    ? (isDark ? gradient : AppColors.moonlightGradient)
                    : null,
                color: isSelected 
                    ? null 
                    : (isDark 
                        ? Colors.white.withOpacity(0.08) 
                        : Colors.white.withOpacity(0.85)),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected 
                      ? (isDark ? AppColors.primary.withOpacity(0.5) : AppColors.aquaIndigo.withOpacity(0.6))
                      : (isDark ? Colors.white.withOpacity(0.12) : Colors.white.withOpacity(0.6)),
                  width: isSelected ? 2 : 1.5,
                ),
                boxShadow: isSelected 
                    ? [
                        BoxShadow(
                          color: (isDark ? AppColors.primary : AppColors.moonlightCyan).withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 40,
                    color: isSelected ? Colors.white : AppColors.getIconColor(isDark),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: Text(
                      title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isSelected ? Colors.white : AppColors.getTextPrimary(isDark),
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Flexible(
                    child: Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isSelected ? Colors.white70 : AppColors.getTextSecondary(isDark),
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStartButton(bool isDark) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        // Get required karma for selected fortune type
        final requiredKarma = _selectedFortuneType != null 
            ? PricingConstants.getFortuneCost(_selectedFortuneType!)
            : 10;
        
        // Debug modunda premium özellikleri ücretsiz
        final canUseFortune = kDebugMode || 
                             (userProvider.user?.canUseDailyFortune ?? false) || 
                             (userProvider.user?.karma ?? 0) >= requiredKarma;
        
        return Column(
          children: [
            if (!(userProvider.user?.canUseDailyFortune ?? false))
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: AppColors.karmaGradient,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.karma.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${AppStrings.karmaRequired}: $requiredKarma ${AppStrings.karma}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Text(
                      '${userProvider.user?.karma ?? 0}',
                      style: AppTextStyles.karmaDisplay,
                    ),
                  ],
                ),
              ),
            MysticalButton.primary(
              text: _selectedFortuneType == null 
                  ? AppStrings.selectFortuneType 
                  : AppStrings.startFortune,
              onPressed: canUseFortune && _selectedFortuneType != null 
                  ? _startFortune 
                  : null,
              isEnabled: canUseFortune && _selectedFortuneType != null,
              showGlow: _selectedFortuneType != null && canUseFortune,
              width: double.infinity,
              size: MysticalButtonSize.large,
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _cardController.dispose();
    super.dispose();
  }
}