import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/pricing_constants.dart';
import '../../core/providers/user_provider.dart';
import '../../core/services/purchase_service.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/ads_service.dart';
import '../../providers/theme_provider.dart';
import '../../core/widgets/mystical_button.dart';
import 'spin_wheel_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class KarmaPurchaseScreen extends StatefulWidget {
  final int initialTab;
  
  const KarmaPurchaseScreen({
    Key? key,
    this.initialTab = 0,
  }) : super(key: key);

  @override
  State<KarmaPurchaseScreen> createState() => _KarmaPurchaseScreenState();
}

class _KarmaPurchaseScreenState extends State<KarmaPurchaseScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _cardController;
  late Animation<double> _cardAnimation;
  late TabController _tabController;
  
  bool _isLoading = false;
  bool _isInitializing = true;
  String? _selectedKarmaPackage;
  String? _selectedPackage;
  final PurchaseService _purchaseService = PurchaseService();
  final Completer<void> _initCompleter = Completer<void>();
  final AdsService _adsService = AdsService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
    _initializeAnimations();
    _initializePurchaseService();
  }

  Future<void> _initializePurchaseService() async {
    try {
      await _purchaseService.initialize();
      
      // Set up purchase callbacks
      _purchaseService.onPurchaseSuccess = (purchaseDetails) {
        _handlePurchaseSuccess(purchaseDetails);
      };
      
      _purchaseService.onPurchaseError = (purchaseDetails) {
        _handlePurchaseError(purchaseDetails);
      };
      
      if (!_initCompleter.isCompleted) {
        _initCompleter.complete();
      }
    } catch (e) {
      if (!_initCompleter.isCompleted) {
        _initCompleter.completeError(e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  Future<void> _handlePurchaseSuccess(PurchaseDetails purchaseDetails) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      // Determine what was purchased based on product ID
      final productId = purchaseDetails.productID;
      
      if (productId.startsWith('karma_')) {
        // Karma purchase
        final karmaAmount = int.tryParse(productId.split('_')[1]) ?? 0;
        if (karmaAmount > 0) {
          await userProvider.addKarma(karmaAmount, 'Karma satın alma: $karmaAmount karma');
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$karmaAmount ${AppStrings.karmaAddedSuccessfully}'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        }
      } else if (productId.startsWith('package_')) {
        // Package purchase
        final packageKarma = int.tryParse(productId.split('_')[1]) ?? 0;
        if (packageKarma > 0) {
          await userProvider.addKarma(packageKarma, 'Paket satın alma: $packageKarma karma');
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${AppStrings.packagePurchasedSuccessfully.replaceAll('karma', '$packageKarma karma')}'),
                backgroundColor: AppColors.success,
              ),
            );
          }
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
          content: Text('${AppStrings.purchaseError} ${purchaseDetails.error?.message ?? AppStrings.unknownError}'),
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

  Future<void> _purchaseKarma(int karma, double price) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Wait for initialization to complete
      if (_isInitializing) {
        await _initCompleter.future;
      }

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      if (!userProvider.isAuthenticated) {
        throw Exception(AppStrings.pleaseLoginFirst);
      }

      // Get product ID
      final productId = PricingConstants.karmaProductIds[karma];
      if (productId == null) {
        throw Exception(AppStrings.productNotFound);
      }

      // Check if purchase service is available
      if (!_purchaseService.isAvailable) {
        throw Exception(AppStrings.purchaseNotAvailable);
      }

      // Purchase from Play Store
      final success = await _purchaseService.purchaseProduct(productId);
      
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

  Future<void> _purchasePackage(Map<String, dynamic> package) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Wait for initialization to complete
      if (_isInitializing) {
        await _initCompleter.future;
      }

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      if (!userProvider.isAuthenticated) {
        throw Exception(AppStrings.pleaseLoginFirst);
      }

      // Get product ID
      final productId = package['productId'] as String?;
      if (productId == null) {
        throw Exception(AppStrings.productNotFound);
      }

      // Check if purchase service is available
      if (!_purchaseService.isAvailable) {
        throw Exception(AppStrings.purchaseNotAvailable);
      }

      // Purchase from Play Store
      final success = await _purchaseService.purchaseProduct(productId);
      
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: themeProvider.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBuyTab(),
                    _buildEarnTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        final iconColor = AppColors.getIconColor(isDark);
        final textColor = AppColors.getTextPrimary(isDark);
        
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.arrow_back_ios,
                  color: iconColor,
                ),
              ),
              Expanded(
                child: Text(
                  AppStrings.buyKarma,
                  style: AppTextStyles.headingMedium.copyWith(
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        );
      },
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
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: isDark 
                      ? AppColors.karmaGradient
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.moonlightCyan,
                            AppColors.aquaIndigo,
                          ],
                        ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: (isDark ? AppColors.karma : Colors.white).withOpacity(0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? AppColors.karma : AppColors.aquaIndigo).withOpacity(0.35),
                      blurRadius: 30,
                      spreadRadius: 2,
                      offset: const Offset(0, 12),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Karma icon with glow
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/karma/karma.png',
                        width: 56,
                        height: 56,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.auto_awesome,
                          size: 56,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Consumer<UserProvider>(
                      builder: (context, userProvider, child) {
                        final karma = userProvider.user?.karma ?? 0;
                        return Column(
                          children: [
                            Text(
                              '$karma',
                              style: AppTextStyles.headingLarge.copyWith(
                                color: Colors.white,
                                fontSize: 42,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'KARMA',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 3,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        AppStrings.useKarmaForFortunes,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
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

  Widget _buildKarmaPackagesSection() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final textColor = AppColors.getTextPrimary(isDark);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.karmaPackages,
          style: AppTextStyles.headingMedium.copyWith(
            color: textColor,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: PricingConstants.karmaPrices.length,
          itemBuilder: (context, index) {
            final entry = PricingConstants.karmaPrices.entries.toList()[index];
            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 400 + (index * 150)),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset((1 - value) * 100, 0),
                  child: Opacity(
                    opacity: value.clamp(0.0, 1.0).toDouble(),
                    child: _buildKarmaPackageCard(
                      karma: entry.key,
                      price: entry.value,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildKarmaPackageCard({required int karma, required double price}) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final textColor = AppColors.getTextPrimary(isDark);
    
    final isSelected = _selectedKarmaPackage == '$karma';
    final isPopular = karma == 50; // 50 karma en popüler
    
    // Theme-aware active colors
    final activeGradient = isDark 
        ? AppColors.karmaGradient 
        : AppColors.moonlightGradient;
        
    final activeColor = isDark 
        ? AppColors.karma 
        : AppColors.moonlightCyan;

    return GestureDetector(
      onTap: _isLoading ? null : () {
        setState(() {
          _selectedKarmaPackage = '$karma';
        });
        _purchaseKarma(karma, price);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isSelected ? activeGradient : null,
          color: isSelected 
              ? null 
              : (isDark 
                  ? Colors.white.withOpacity(0.05) 
                  : Colors.white.withOpacity(0.6)),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDark 
                    ? Colors.white.withOpacity(0.1) 
                    : Colors.white.withOpacity(0.4)),
            width: isSelected ? 0 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Opacity(
          opacity: _isLoading ? 0.6 : 1.0,
          child: Column(
            children: [
              if (isPopular)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        AppStrings.mostPopular,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              if (isPopular) const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Image.asset(
                      'assets/karma/karma.png',
                      width: 42,
                      height: 42,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.auto_awesome,
                        size: 42,
                        color: isSelected ? Colors.white : activeColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$karma Karma',
                          style: AppTextStyles.headingMedium.copyWith(
                            color: isSelected ? Colors.white : textColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '₺${price.toStringAsFixed(2)}',
                              style: AppTextStyles.headingLarge.copyWith(
                                color: isSelected ? Colors.white : activeColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 24,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (_isLoading && isSelected)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  else
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? Colors.white : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? Colors.white : (isDark ? Colors.white54 : Colors.black26),
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
      ),
    );
  }

  Widget _buildPackageDealsSection() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final textColor = AppColors.getTextPrimary(isDark);
    final textSecondaryColor = AppColors.getTextSecondary(isDark);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.specialPackages,
          style: AppTextStyles.headingMedium.copyWith(
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.specialPackagesDesc,
          style: AppTextStyles.bodyMedium.copyWith(
            color: textSecondaryColor,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: PricingConstants.packages.length,
          itemBuilder: (context, index) {
            final package = PricingConstants.packages[index];
            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 500 + (index * 150)),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: _buildPackageDealCard(package, index),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildPackageDealCard(Map<String, dynamic> package, int index) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final textColor = AppColors.getTextPrimary(isDark);
    
    final isSelected = _selectedPackage == '${package['karma']}';
    final isPopular = index == 1; // Second package is most popular
    
    // Theme-aware active colors
    final activeGradient = isDark 
        ? AppColors.premiumGradient 
        : AppColors.moonlightGradient;
        
    final activeColor = isDark 
        ? AppColors.premium 
        : AppColors.moonlightCyan;

    return GestureDetector(
      onTap: _isLoading ? null : () {
        setState(() {
          _selectedPackage = '${package['karma']}';
        });
        _purchasePackage(package);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: isSelected ? activeGradient : null,
          color: isSelected 
              ? null 
              : (isDark 
                  ? Colors.white.withOpacity(0.05) 
                  : Colors.white.withOpacity(0.6)),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : isPopular
                    ? (isDark ? AppColors.premium.withOpacity(0.5) : AppColors.moonlightCyan.withOpacity(0.4))
                    : (isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.4)),
            width: isSelected || isPopular ? 2 : 1,
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
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Opacity(
          opacity: _isLoading ? 0.6 : 1.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isPopular)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white.withOpacity(0.25) : activeColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: activeColor.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        AppStrings.mostPopular,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              if (isPopular) const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${package['karma']} ${AppStrings.karmaPlusBonus}',
                          style: AppTextStyles.headingMedium.copyWith(
                            color: isSelected ? Colors.white : textColor,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildFeatureRow(
                          Icons.notifications_off,
                          '${package['adFreeDays']} ${AppStrings.daysAdFree}',
                          isSelected,
                        ),
                        const SizedBox(height: 8),
                        _buildFeatureRow(
                          Icons.favorite,
                          '${package['auraMatches']} ${AppStrings.auraMatches}',
                          isSelected,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₺${(package['price'] as double).toStringAsFixed(2)}',
                        style: AppTextStyles.headingLarge.copyWith(
                          color: isSelected ? Colors.white : activeColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 24,
                        ),
                      ),
                      if (isSelected) const SizedBox(height: 8),
                      if (_isLoading && isSelected)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      else
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? Colors.white : Colors.transparent,
                            border: Border.all(
                              color: isSelected ? Colors.white : (isDark ? Colors.white54 : Colors.black26),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text, bool isSelected) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final textSecondaryColor = AppColors.getTextSecondary(isDark);
    
    final activeColor = isDark 
        ? AppColors.premium 
        : AppColors.moonlightCyan;
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isSelected 
                ? Colors.white.withOpacity(0.2) 
                : activeColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon, 
            size: 16, 
            color: isSelected ? Colors.white : activeColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isSelected ? Colors.white.withOpacity(0.9) : textSecondaryColor,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ),
      ],
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

  Widget _buildTabBar() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        final textSecondaryColor = AppColors.getTextSecondary(isDark);
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark 
                ? AppColors.getContainerBackground(isDark)
                : Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark 
                  ? AppColors.getContainerBorder(isDark)
                  : Colors.white.withOpacity(0.6),
              width: 1,
            ),
            boxShadow: isDark ? null : [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              gradient: isDark 
                  ? LinearGradient(colors: [AppColors.primary, AppColors.secondary])
                  : AppColors.moonlightGradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? AppColors.primary : AppColors.moonlightCyan).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: textSecondaryColor,
            labelStyle: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: AppTextStyles.bodyMedium,
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shopping_cart_rounded, size: 18),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        AppStrings.buy,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stars_rounded, size: 18),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        AppStrings.earn,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBuyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 32),
          _buildKarmaPackagesSection(),
          const SizedBox(height: 32),
          _buildPackageDealsSection(),
          const SizedBox(height: 32),
          _buildPolicyLinks(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildEarnTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDailyLoginRewardSection(),
          const SizedBox(height: 24),
          _buildWatchAdsSection(),
          const SizedBox(height: 24),
          _buildSpinWheelSection(),
          const SizedBox(height: 24),
          _buildInviteFriendSection(),
          const SizedBox(height: 24),
          _buildShareOnInstagramSection(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDailyLoginRewardSection() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        final textColor = AppColors.getTextPrimary(isDark);
        final textSecondaryColor = AppColors.getTextSecondary(isDark);
        
        return FutureBuilder<int>(
          future: _getCurrentStreak(),
          builder: (context, snapshot) {
            final currentStreak = snapshot.data ?? 0;
            final todayReward = PricingConstants.getDailyLoginReward(currentStreak);
            
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.15),
                    AppColors.accent.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: AppColors.karmaGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.calendar_today, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppStrings.dailyLoginReward,
                          style: AppTextStyles.headingMedium.copyWith(color: textColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (currentStreak > 0)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: AppColors.karmaGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '🔥',
                            style: TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStrings.streakDays.replaceAll('{0}', '$currentStreak'),
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (todayReward != null)
                                  Text(
                                    AppStrings.todayKarma.replaceAll('{0}', '${todayReward['karma']}'),
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: Colors.white70,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  Text(
                    AppStrings.dailyLoginRewardTable,
                    style: AppTextStyles.headingSmall.copyWith(color: textColor),
                  ),
                  const SizedBox(height: 16),
                  ...PricingConstants.dailyLoginRewards.map((reward) {
                    final day = reward['day'] as int;
                    final karma = reward['karma'] as int;
                    final extraAction = reward['extraAction'] as String?;
                    final isToday = (currentStreak % PricingConstants.maxStreakDays) + 1 == day;
                    final isClaimed = currentStreak >= day;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isToday
                            ? AppColors.primary.withValues(alpha: 0.2)
                            : AppColors.cardBackground.withValues(alpha: isDark ? 0.3 : 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isToday
                              ? AppColors.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: isToday || isClaimed
                                  ? AppColors.karmaGradient
                                  : null,
                              color: isToday || isClaimed
                                  ? null
                                  : AppColors.cardBackground.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '$day',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: isToday || isClaimed
                                      ? Colors.white
                                      : textColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$karma Karma',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: textColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (extraAction != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    _getExtraActionText(extraAction),
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: textSecondaryColor,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (isToday && !isClaimed)
                            Icon(
                              Icons.arrow_forward,
                              color: AppColors.primary,
                              size: 20,
                            )
                          else if (isClaimed)
                            Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                              size: 20,
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getExtraActionText(String action) {
    switch (action) {
      case 'watch_ad_for_2_karma':
        return AppStrings.watchAdForKarma.replaceAll('{0}', '2');
      case 'premium_cta':
        return AppStrings.premiumDiscount;
      case 'watch_ad_for_5_karma_or_free_aura_match':
        return AppStrings.adOrAuraMatch.replaceAll('{0}', '5');
      default:
        return '';
    }
  }

  Future<int> _getCurrentStreak() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.user?.id;
      if (userId == null) return 0;
      
      final firebaseService = FirebaseService();
      return await firebaseService.getLoginStreak(userId);
    } catch (e) {
      return 0;
    }
  }

  Widget _buildWatchAdsSection() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        final textColor = AppColors.getTextPrimary(isDark);
        final textSecondaryColor = AppColors.getTextSecondary(isDark);
        
        return FutureBuilder<int>(
          future: _getDailyVideoCount(),
          builder: (context, snapshot) {
            final videosWatched = snapshot.data ?? 0;
            final remaining = PricingConstants.dailyVideoLimit - videosWatched;
            final canWatch = remaining > 0;
            
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.15),
                    AppColors.accent.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: AppColors.karmaGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.play_circle_outline, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppStrings.watchAd,
                          style: AppTextStyles.headingMedium.copyWith(color: textColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.watchAdDescription,
                    style: AppTextStyles.bodyMedium.copyWith(color: textSecondaryColor),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '${PricingConstants.videoKarmaReward}',
                                  style: AppTextStyles.headingLarge.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  AppStrings.karma,
                                  style: AppTextStyles.headingSmall.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              canWatch
                                  ? AppStrings.remainingLimit.replaceAll('{0}', '$remaining').replaceAll('{1}', '${PricingConstants.dailyVideoLimit}')
                                  : AppStrings.dailyLimitReached,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      MysticalButton.primary(
                        text: AppStrings.watch,
                        onPressed: canWatch ? _watchAdForKarma : null,
                        icon: Icons.play_arrow,
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSpinWheelSection() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        final textColor = AppColors.getTextPrimary(isDark);
        final textSecondaryColor = AppColors.getTextSecondary(isDark);
        
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withValues(alpha: 0.15),
                AppColors.accent.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppColors.karmaGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.casino, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppStrings.spinWheel,
                      style: AppTextStyles.headingMedium.copyWith(color: textColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.spinWheelDescription,
                style: AppTextStyles.bodyMedium.copyWith(color: textSecondaryColor),
              ),
              const SizedBox(height: 20),
              MysticalButton.primary(
                text: AppStrings.spinWheelButton,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SpinWheelScreen()),
                  );
                },
                icon: Icons.casino,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInviteFriendSection() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        final textColor = AppColors.getTextPrimary(isDark);
        final textSecondaryColor = AppColors.getTextSecondary(isDark);
        
        return FutureBuilder<Map<String, dynamic>>(
          future: _getInviteStats(),
          builder: (context, snapshot) {
            final stats = snapshot.data ?? {'invites': 0, 'karmaEarned': 0};
            final invites = stats['invites'] as int;
            final karmaEarned = stats['karmaEarned'] as int;
            
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.15),
                    AppColors.accent.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: AppColors.karmaGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.person_add, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppStrings.inviteFriend,
                          style: AppTextStyles.headingMedium.copyWith(color: textColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.inviteFriendDescription,
                    style: AppTextStyles.bodyMedium.copyWith(color: textSecondaryColor),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground.withValues(alpha: isDark ? 0.3 : 0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppStrings.invitedCount,
                              style: AppTextStyles.bodyMedium.copyWith(color: textColor),
                            ),
                            Text(
                              '$invites',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                AppStrings.karmaEarnedFromSystem,
                                style: AppTextStyles.bodyMedium.copyWith(color: textColor),
                              ),
                            ),
                            Text(
                              '$karmaEarned',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  MysticalButton.primary(
                    text: AppStrings.invite,
                    onPressed: _inviteFriend,
                    icon: Icons.share,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildShareOnInstagramSection() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        final textColor = AppColors.getTextPrimary(isDark);
        final textSecondaryColor = AppColors.getTextSecondary(isDark);
        
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withValues(alpha: 0.15),
                AppColors.accent.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppColors.karmaGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.photo_library, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppStrings.shareOnInstagram,
                      style: AppTextStyles.headingMedium.copyWith(color: textColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.shareOnInstagramDescription,
                style: AppTextStyles.bodyMedium.copyWith(color: textSecondaryColor),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.oneTimeOnly,
                style: AppTextStyles.bodySmall.copyWith(
                  color: textSecondaryColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: MysticalButton.primary(
                      text: AppStrings.instagramStory,
                      onPressed: _shareOnInstagram,
                      icon: Icons.photo_library,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MysticalButton.primary(
                      text: AppStrings.rateApp,
                      onPressed: _rateApp,
                      icon: Icons.star,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<int> _getDailyVideoCount() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.user?.id;
      if (userId == null) return 0;

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('video_watches')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .get();
      
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _watchAdForKarma() async {
    try {
      final loadedCompleter = Completer<bool>();
      await _adsService.createRewardedAd(
        adUnitId: _adsService.rewardedAdUnitId,
        onAdLoaded: (ad) {
          if (!loadedCompleter.isCompleted) loadedCompleter.complete(true);
        },
        onAdFailedToLoad: (error) {
          if (!loadedCompleter.isCompleted) loadedCompleter.complete(false);
        },
      );

      bool isLoaded = false;
      try {
        isLoaded = await loadedCompleter.future.timeout(const Duration(seconds: 2));
      } catch (_) {
        isLoaded = false;
      }

      if (!isLoaded) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.adNotWatched),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      final reward = await _adsService.showRewardedAd();
      if (!mounted) return;
      
      if (reward != null) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final videosWatched = await _getDailyVideoCount();
        
        if (videosWatched >= PricingConstants.dailyVideoLimit) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.dailyVideoLimitReached),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        await userProvider.addKarma(
          PricingConstants.videoKarmaReward,
          'Reklam izleme: Video ${videosWatched + 1}/${PricingConstants.dailyVideoLimit}',
        );

        await _firestore
            .collection('users')
            .doc(userProvider.user!.id)
            .collection('video_watches')
            .add({
          'timestamp': FieldValue.serverTimestamp(),
          'karmaReward': PricingConstants.videoKarmaReward,
        });

        if (mounted) {
          setState(() {}); // Refresh UI
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎉 ${PricingConstants.videoKarmaReward} ${AppStrings.karmaEarned}'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.adNotWatched),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<Map<String, dynamic>> _getInviteStats() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.user?.id;
      if (userId == null) return {'invites': 0, 'karmaEarned': 0};

      final userDoc = await _firestore.collection('users').doc(userId).get();
      final data = userDoc.data();
      
      return {
        'invites': data?['referralInvites'] as int? ?? 0,
        'karmaEarned': data?['referralKarmaEarned'] as int? ?? 0,
      };
    } catch (e) {
      return {'invites': 0, 'karmaEarned': 0};
    }
  }

  Future<void> _inviteFriend() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.user?.id;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.pleaseLoginFirst),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final inviteCode = userId.substring(0, 8).toUpperCase();
      final inviteLink = 'https://falla.app/invite/$inviteCode';
      final shareText = 'Falla uygulamasını keşfet! Mistik fal ve astroloji deneyimi için bu linki kullan: $inviteLink';

      await Share.share(shareText);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.shareError} $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _shareOnInstagram() async {
    try {
      final shareText = 'Falla ile mistik fal ve astroloji deneyimini keşfet! 🔮✨\n\nhttps://falla.app';
      await Share.share(shareText);
      
      // Instagram story paylaşımı için özel işlem yapılabilir
      // Şimdilik genel paylaşım kullanıyoruz
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.shareError} $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _rateApp() async {
    // App Store / Play Store rating için
    // Şimdilik basit bir mesaj gösteriyoruz
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.rateAppMessage),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _backgroundController.dispose();
    _cardController.dispose();
    super.dispose();
  }
}

