import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/pricing_constants.dart';
import '../../core/providers/user_provider.dart';
import '../../providers/theme_provider.dart';
import '../../core/widgets/mystical_button.dart';
import '../../core/services/purchase_service.dart';
import '../main/main_screen.dart';


class PremiumScreen extends StatefulWidget {
  const PremiumScreen({Key? key}) : super(key: key);

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _cardController;
  late Animation<double> _cardAnimation;
  
  bool _isLoading = false;
  String _selectedPlan = 'monthly';
  final PurchaseService _purchaseService = PurchaseService();

  List<Map<String, dynamic>> _getPremiumFeatures() {
    return [
      {
        'icon': Icons.notifications_off,
        'title': AppStrings.adFreeExperience,
        'description': AppStrings.adFreeExperienceDesc,
      },
      {
        'icon': Icons.auto_awesome,
        'title': AppStrings.daily25Karma,
        'description': AppStrings.daily25KarmaDesc,
      },
      {
        'icon': Icons.priority_high,
        'title': AppStrings.priorityFortuneReading,
        'description': AppStrings.priorityFortuneReadingDesc,
      },
      {
        'icon': Icons.favorite,
        'title': AppStrings.auraMatchAdvantages,
        'description': AppStrings.auraMatchAdvantagesDesc,
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
  }

  Future<void> _initializePurchaseService() async {
    await _purchaseService.initialize();
    
    // Set up purchase callbacks
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
      
      // Premium subscription purchase
      final subscriptionId = purchaseDetails.productID;
      
      if (subscriptionId.startsWith('premium_')) {
        // Upgrade user to premium
        final success = await userProvider.upgradeToPremium();
        
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.purchaseSuccessful),
              backgroundColor: AppColors.success,
            ),
          );
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
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
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
    
    // Blinking animation disabled
    // _backgroundController.repeat(reverse: true);
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
          Navigator.pop(context);
        }
        return;
      }
      
      // Check if user is authenticated
      if (!userProvider.isAuthenticated) {
        throw Exception(AppStrings.pleaseLoginFirst);
      }

      // Get subscription ID
      final subscriptionId = PricingConstants.premiumProductIds[_selectedPlan];
      if (subscriptionId == null) {
        throw Exception(AppStrings.subscriptionNotFound);
      }

      // Check if purchase service is available
      if (!_purchaseService.isAvailable) {
        throw Exception(AppStrings.purchaseNotAvailableTryLater);
      }

      // Purchase subscription from Play Store
      final success = await _purchaseService.purchaseSubscription(subscriptionId);
      
      if (!success) {
        throw Exception(AppStrings.purchaseCouldNotStart);
      }

      // Purchase will be handled by PurchaseService callback
      // For now, show success message
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
            content: Text('${AppStrings.error}: $e'),
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 32),
                          _buildFeaturesSection(isDark),
                      const SizedBox(height: 32),
                          _buildPricingSection(isDark),
                      const SizedBox(height: 32),
                      _buildPurchaseButton(),
                      const SizedBox(height: 16),
                      _buildPolicyLinks(),
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
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const MainScreen(),
                ),
              );
            },
            icon: Icon(
              Icons.arrow_back_ios,
              color: AppColors.getIconColor(isDark),
            ),
          ),
          Expanded(
            child: Text(
              AppStrings.premium,
              style: AppTextStyles.headingMedium.copyWith(
                color: AppColors.getTextPrimary(isDark),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Debug modunda iptal butonu
          if (kDebugMode)
            TextButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const MainScreen(),
                  ),
                );
              },
              child: Text(
                AppStrings.cancel,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.getTextPrimary(isDark),
                ),
              ),
            )
          else
            const SizedBox(width: 48), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        
        return AnimatedBuilder(
          animation: _cardAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _cardAnimation.value,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: isDark 
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.premium,
                            AppColors.premium.withOpacity(0.7),
                            const Color(0xFFFFA500).withOpacity(0.5),
                          ],
                        )
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.moonlightCyan,
                            AppColors.aquaIndigo,
                            AppColors.deepAqua.withOpacity(0.8),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? AppColors.premium : AppColors.aquaIndigo).withOpacity(0.35),
                      blurRadius: 35,
                      spreadRadius: 2,
                      offset: const Offset(0, 15),
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: -5,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.2),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.diamond_outlined,
                        size: 64,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      AppStrings.premiumTitle,
                      style: AppTextStyles.headingLarge.copyWith(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppStrings.premiumSubtitle,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        height: 1.5,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFeaturesSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                gradient: AppColors.premiumGradient,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              AppStrings.premiumFeatures,
              style: AppTextStyles.headingMedium.copyWith(
                color: AppColors.getTextPrimary(isDark),
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _getPremiumFeatures().length,
          itemBuilder: (context, index) {
            final feature = _getPremiumFeatures()[index];
            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 400 + (index * 150)),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset((1 - value) * 100, 0),
                  child: Opacity(
                    opacity: value.clamp(0.0, 1.0).toDouble(),
                    child: _buildFeatureItem(feature, isDark),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildFeatureItem(Map<String, dynamic> feature, bool isDark) {
    // Glass card for feature
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: isDark 
                  ? AppColors.premiumGradient 
                  : AppColors.moonlightGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? AppColors.premium : AppColors.moonlightCyan).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              feature['icon'],
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature['title'],
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.getTextPrimary(isDark),
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  feature['description'],
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.getTextSecondary(isDark),
                    height: 1.5,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                gradient: AppColors.premiumGradient,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              AppStrings.choosePlan,
              style: AppTextStyles.headingMedium.copyWith(
                color: AppColors.getTextPrimary(isDark),
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _getPricingPlans().length,
          itemBuilder: (context, index) {
            final plan = _getPricingPlans()[index];
            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 600 + (index * 200)),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: _buildPricingCard(plan, isDark),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildPricingCard(Map<String, dynamic> plan, bool isDark) {
    final isSelected = _selectedPlan == plan['id'];
    final isPopular = plan['popular'] == true;
    
    // Theme-aware colors
    final activeGradient = isDark 
        ? AppColors.premiumGradient 
        : AppColors.moonlightGradient;
        
    final activeColor = isDark 
        ? AppColors.premium 
        : AppColors.moonlightCyan;
        
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlan = plan['id'];
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: isSelected ? activeGradient : null,
          color: isSelected 
              ? null 
              : (isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withOpacity(0.4),
                    blurRadius: 25,
                    spreadRadius: 2,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            if (isPopular)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      AppStrings.mostPopular,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan['title'],
                        style: AppTextStyles.headingMedium.copyWith(
                          color: isSelected ? Colors.white : AppColors.getTextPrimary(isDark),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '₺${plan['price']}',
                            style: AppTextStyles.headingLarge.copyWith(
                              color: isSelected ? Colors.white : activeColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 32,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '/ ${plan['period']}',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isSelected ? Colors.white.withOpacity(0.8) : AppColors.getTextSecondary(isDark),
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      if (plan['discount'] != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white.withOpacity(0.2) : AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            plan['discount'],
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isSelected ? Colors.white : AppColors.success,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? Colors.white : null,
                    border: Border.all(
                      color: isSelected ? Colors.white : (isDark ? Colors.white54 : Colors.black45),
                      width: 2,
                    ),
                  ),
                  child: isSelected 
                      ? Icon(Icons.check, size: 18, color: activeColor) 
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseButton() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        if (userProvider.user?.isPremium == true) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.successGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  AppStrings.alreadyPremium,
                  style: AppTextStyles.headingMedium.copyWith(
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return MysticalButton.premium(
          text: AppStrings.goPremium,
          icon: Icons.diamond,
          onPressed: _isLoading ? null : _purchasePremium,
          width: double.infinity,
          size: MysticalButtonSize.large,
          isLoading: _isLoading,
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
      children: [
        Text(
          AppStrings.byPurchasingYouAccept,
          style: AppTextStyles.bodySmall.copyWith(
            color: textSecondaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _buildPolicyLink(
              AppStrings.privacyPolicyLink,
              'https://www.loegs.com/falla/PrivacyPolicy.html',
              linkColor,
            ),
            Text(
              ', ',
              style: AppTextStyles.bodySmall.copyWith(color: textSecondaryColor),
            ),
            _buildPolicyLink(
              AppStrings.userAgreementLink,
              'https://www.loegs.com/falla/UserAgreement.html',
              linkColor,
            ),
            Text(
              ', ',
              style: AppTextStyles.bodySmall.copyWith(color: textSecondaryColor),
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
        ),
      ),
    );
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _cardController.dispose();
    super.dispose();
  }
}