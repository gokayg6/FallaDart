import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/pricing_constants.dart';
import '../../core/providers/user_provider.dart';
import '../../providers/theme_provider.dart';
import '../../core/widgets/mystical_button.dart';
import '../../core/services/purchase_service.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'premium_screen.dart';
import '../main/main_screen.dart';

class PremiumOnboardingScreen extends StatefulWidget {
  const PremiumOnboardingScreen({Key? key}) : super(key: key);

  @override
  State<PremiumOnboardingScreen> createState() => _PremiumOnboardingScreenState();
}

class _PremiumOnboardingScreenState extends State<PremiumOnboardingScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _cardController;
  late AnimationController _particleController;
  late AnimationController _featureController;
  
  late Animation<double> _cardAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _particleAnimation;
  late Animation<double> _featureAnimation;
  
  bool _isLoading = false;
  String _selectedPlan = 'monthly';
  final PurchaseService _purchaseService = PurchaseService();
  int _currentFeatureIndex = 0;

  List<Map<String, dynamic>> _getPremiumFeatures() {
    return [
      {
        'icon': Icons.notifications_off,
        'title': AppStrings.adFreeExperience,
        'description': AppStrings.adFreeExperienceDesc,
        'color': AppColors.primary,
      },
      {
        'icon': Icons.auto_awesome,
        'title': AppStrings.daily25Karma,
        'description': AppStrings.daily25KarmaDesc,
        'color': AppColors.karma,
      },
      {
        'icon': Icons.priority_high,
        'title': AppStrings.priorityFortuneReading,
        'description': AppStrings.priorityFortuneReadingDesc,
        'color': AppColors.accent,
      },
      {
        'icon': Icons.favorite,
        'title': AppStrings.auraMatchAdvantages,
        'description': AppStrings.auraMatchAdvantagesDesc,
        'color': AppColors.secondary,
      },
    ];
  }

  List<Map<String, dynamic>> _getPricingPlans() {
    return [
      {
        'id': 'weekly',
        'title': AppStrings.weekly,
        'price': '39,99',
        'period': AppStrings.week,
        'discount': null,
        'popular': false,
      },
      {
        'id': 'monthly',
        'title': AppStrings.monthly,
        'price': '89,99',
        'period': AppStrings.month,
        'discount': null,
        'popular': true,
      },
      {
        'id': 'yearly',
        'title': AppStrings.yearly,
        'price': '499,99',
        'period': AppStrings.year,
        'discount': AppStrings.bestValue,
        'popular': false,
      },
    ];
  }

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializePurchaseService();
    _startFeatureRotation();
  }

  void _startFeatureRotation() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _currentFeatureIndex = (_currentFeatureIndex + 1) % _getPremiumFeatures().length;
        });
        _featureController.forward(from: 0.0).then((_) {
          _featureController.reverse().then((_) {
            _startFeatureRotation();
          });
        });
      }
    });
  }

  Future<void> _initializePurchaseService() async {
    await _purchaseService.initialize();
    
    _purchaseService.onPurchaseSuccess = (purchaseDetails) {
      _handlePurchaseSuccess(purchaseDetails);
    };
    
    _purchaseService.onPurchaseError = (purchaseDetails) {
      _handlePurchaseError(purchaseDetails);
    };
    
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _handlePurchaseSuccess(PurchaseDetails purchaseDetails) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      final subscriptionId = purchaseDetails.productID;
      
      if (subscriptionId.startsWith('premium_')) {
        final success = await userProvider.upgradeToPremium();
        
        if (success && mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const MainScreen(),
            ),
          );
        } else {
          throw Exception(userProvider.error ?? AppStrings.premiumMembershipNotUpdated);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.purchaseProcessingError} $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _handlePurchaseError(PurchaseDetails purchaseDetails) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppStrings.purchaseError} ${purchaseDetails.error?.message ?? AppStrings.purchaseErrorUnknown}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _initializeAnimations() {
    // Background gradient animation
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    
    // Card entrance animation
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _cardAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    ));

    // Particle animation
    _particleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _particleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _particleController,
      curve: Curves.easeInOut,
    ));

    // Feature rotation animation
    _featureController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _featureAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _featureController,
      curve: Curves.easeInOut,
    ));
    
    _backgroundController.repeat(reverse: true);
    _particleController.repeat(reverse: true);
    _cardController.forward();
  }

  Future<void> _purchasePremium() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      // Debug modunda direkt premium yap
      if (kDebugMode) {
        final success = await userProvider.upgradeToPremium();
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Debug modunda premium aktif edildi'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const MainScreen(),
            ),
          );
        }
        return;
      }
      
      if (!userProvider.isAuthenticated) {
        throw Exception(AppStrings.pleaseLoginFirst);
      }

      final subscriptionId = PricingConstants.premiumProductIds[_selectedPlan];
      if (subscriptionId == null) {
        throw Exception(AppStrings.subscriptionNotFound);
      }

      if (!_purchaseService.isAvailable) {
        throw Exception(AppStrings.purchaseNotAvailableTryLater);
      }

      final success = await _purchaseService.purchaseSubscription(subscriptionId);
      
      if (!success) {
        throw Exception(AppStrings.purchaseCouldNotStart);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.purchaseStarted),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.purchaseError} $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openPremiumScreen() async {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const PremiumScreen(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _cardController.dispose();
    _particleController.dispose();
    _featureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final features = _getPremiumFeatures();
    final currentFeature = features[_currentFeatureIndex];
    final plans = _getPricingPlans();

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark 
              ? AppColors.backgroundGradient 
              : AppColors.lightBackgroundGradient,
        ),
        child: Stack(
          children: [
            // Animated particles
            _buildParticles(isDark),
            
            // Main content
            SafeArea(
              child: Stack(
                children: [
                  AnimatedBuilder(
                    animation: Listenable.merge([
                      _cardAnimation,
                      _fadeAnimation,
                      _slideAnimation,
                    ]),
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fadeAnimation.value,
                        child: Transform.translate(
                          offset: Offset(0, _slideAnimation.value),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 4),
                            
                            // Premium badge
                            Transform.scale(
                              scale: _cardAnimation.value,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  gradient: AppColors.premiumGradient,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.premiumGradient.colors.first.withOpacity(0.4),
                                      blurRadius: 15,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.diamond,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      'PREMIUM',
                                      style: AppTextStyles.headingSmall.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Title
                            Text(
                              AppStrings.goPremium,
                              style: AppTextStyles.headingLarge.copyWith(
                                color: isDark ? AppColors.textPrimary : Colors.grey[900],
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            
                            const SizedBox(height: 6),
                            
                            // Subtitle
                            Text(
                              AppStrings.unlimitedFeaturesAdFree,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: isDark ? AppColors.textSecondary : Colors.grey[700],
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Feature showcase
                            Flexible(
                              child: _buildFeatureShowcase(currentFeature, isDark),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Pricing plans
                            _buildPricingPlans(plans, isDark),
                            
                            const SizedBox(height: 12),
                            
                            // Purchase button
                            _buildPurchaseButton(),
                            const SizedBox(height: 6),
                            _buildPolicyLinks(),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
                  // Close button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Consumer<ThemeProvider>(
                      builder: (context, themeProvider, child) {
                        final isDarkMode = themeProvider.isDarkMode;
                        return IconButton(
                          icon: Icon(
                            Icons.close,
                            color: isDarkMode ? AppColors.textPrimary : Colors.grey[800],
                            size: 32,
                          ),
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => const MainScreen(),
                              ),
                            );
                          },
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticles(bool isDark) {
    return AnimatedBuilder(
      animation: _particleAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: _ParticlePainter(
            _particleAnimation.value,
            isDark: isDark,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }

  Widget _buildFeatureShowcase(Map<String, dynamic> feature, bool isDark) {
    return AnimatedBuilder(
      animation: _featureAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: 1.0 - _featureAnimation.value.abs(),
          child: Transform.scale(
            scale: 1.0 - (_featureAnimation.value.abs() * 0.1),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark 
                    ? AppColors.surface.withOpacity(0.6)
                    : Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (feature['color'] as Color).withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (feature['color'] as Color).withOpacity(0.2),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          (feature['color'] as Color),
                          (feature['color'] as Color).withOpacity(0.6),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (feature['color'] as Color).withOpacity(0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      feature['icon'] as IconData,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    feature['title'] as String,
                    style: AppTextStyles.headingMedium.copyWith(
                      color: isDark ? AppColors.textPrimary : Colors.grey[900],
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    feature['description'] as String,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark ? AppColors.textSecondary : Colors.grey[700],
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPricingPlans(List<Map<String, dynamic>> plans, bool isDark) {
    return Row(
      children: plans.map((plan) {
        final isSelected = plan['id'] == _selectedPlan;
        final isPopular = plan['popular'] == true;
        
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedPlan = plan['id'] as String;
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark 
                        ? AppColors.surface 
                        : Colors.white)
                    : (isDark 
                        ? AppColors.surface.withOpacity(0.3)
                        : Colors.white.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppColors.premiumGradient.colors.first
                      : (isDark 
                          ? Colors.white.withOpacity(0.1)
                          : Colors.grey[300]!),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.premiumGradient.colors.first.withOpacity(0.3),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isPopular)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: AppColors.premiumGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        AppStrings.popular,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 4),
                  const SizedBox(height: 4),
                  Text(
                    plan['title'] as String,
                    style: TextStyle(
                      color: isDark ? AppColors.textPrimary : Colors.grey[900],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${plan['price']} ₺',
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.premiumGradient.colors.first
                          : (isDark ? AppColors.textSecondary : Colors.grey[700]),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '/ ${plan['period']}',
                    style: TextStyle(
                      color: isDark ? AppColors.textTertiary : Colors.grey[600],
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPurchaseButton() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        if (userProvider.user?.isPremium == true) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: AppColors.successGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    AppStrings.alreadyPremium,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            MysticalButton.premium(
              text: AppStrings.goPremium,
              icon: Icons.diamond,
              onPressed: _isLoading ? null : _purchasePremium,
              width: double.infinity,
              size: MysticalButtonSize.large,
              isLoading: _isLoading,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _openPremiumScreen,
              child: Text(
                AppStrings.seeAllFeatures,
                style: TextStyle(
                  color: AppColors.premiumGradient.colors.first,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPolicyLinks() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final textSecondaryColor = AppColors.getTextSecondary(isDark);
    final linkColor = AppColors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AppStrings.byPurchasingYouAccept,
          style: AppTextStyles.bodySmall.copyWith(
            color: textSecondaryColor,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          runSpacing: 2,
          children: [
            _buildPolicyLink(
              AppStrings.privacyPolicyLink,
              'https://www.loegs.com/falla/PrivacyPolicy.html',
              linkColor,
            ),
            Text(
              ', ',
              style: AppTextStyles.bodySmall.copyWith(
                color: textSecondaryColor,
                fontSize: 10,
              ),
            ),
            _buildPolicyLink(
              AppStrings.userAgreementLink,
              'https://www.loegs.com/falla/UserAgreement.html',
              linkColor,
            ),
            Text(
              ', ',
              style: AppTextStyles.bodySmall.copyWith(
                color: textSecondaryColor,
                fontSize: 10,
              ),
            ),
            _buildPolicyLink(
              AppStrings.termsOfServiceLink,
              'https://www.loegs.com/falla/TermsOfService.html',
              linkColor,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPolicyLink(String text, String url, Color color) {
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Text(
        text,
        style: AppTextStyles.bodySmall.copyWith(
          color: color,
          decoration: TextDecoration.underline,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double animationValue;
  final bool isDark;

  _ParticlePainter(this.animationValue, {required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark 
          ? AppColors.primary 
          : AppColors.primary.withOpacity(0.3))
          .withOpacity(0.2 * (1 - (animationValue - 0.5).abs() * 2))
      ..style = PaintingStyle.fill;

    final particleCount = 12;
    for (int i = 0; i < particleCount; i++) {
      final radius = size.width * 0.4;
      final offset = Offset(
        size.width / 2 + 
            radius * 
            (animationValue - 0.5) * 
            2 * 
            (i.isEven ? 1 : -1) * 
            (i % 3 == 0 ? 0.5 : 1) * 
            (animationValue * 2 - 1) *
            (0.5 + (i % 2) * 0.3),
        size.height / 2 + 
            radius * 
            (animationValue - 0.5) * 
            2 * 
            (i.isOdd ? 1 : -1) * 
            (i % 2 == 0 ? 0.7 : 1) *
            (animationValue * 2 - 1) *
            (0.5 + (i % 3) * 0.2),
      );
      
      canvas.drawCircle(
        offset,
        6 * (1 - (animationValue - 0.5).abs() * 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || 
           oldDelegate.isDark != isDark;
  }
}

