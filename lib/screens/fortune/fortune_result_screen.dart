import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/pricing_constants.dart';
import '../../core/models/fortune_model.dart';
import '../../core/services/fortune_service.dart';
import '../../core/providers/user_provider.dart';
import '../../providers/theme_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/widgets/mystical_button.dart';
import '../../core/widgets/mystical_loading.dart';
import '../../core/services/ads_service.dart';
import 'dart:async';
import '../../core/widgets/mystical_card.dart';
import '../../core/widgets/cached_falla_logo.dart';
import '../../core/widgets/image_viewer.dart';
import 'dream_draw_screen.dart';
import 'fortune_selection_screen.dart';
import '../../core/utils/share_utils.dart';
import '../../core/utils/helpers.dart';

// Reklam widget'ı - görünür olduğunda reklam gösterir
class _AdWidget extends StatefulWidget {
  final AdsService adsService;
  final VoidCallback? onAdShown;

  const _AdWidget({
    required this.adsService,
    this.onAdShown,
  });

  @override
  State<_AdWidget> createState() => _AdWidgetState();
}

class _AdWidgetState extends State<_AdWidget> {
  bool _adShown = false;

  @override
  void initState() {
    super.initState();
    // Widget görünür olduğunda reklamı göster
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showAd();
    });
  }

  Future<void> _showAd() async {
    if (_adShown) return;
    
    // Reklamı yükle ve göster
    await widget.adsService.createInterstitialAd(
      adUnitId: widget.adsService.interstitialAdUnitId,
      onAdLoaded: (ad) {
        ad.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose();
            setState(() {
              _adShown = true;
            });
            widget.onAdShown?.call();
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            ad.dispose();
            setState(() {
              _adShown = true;
            });
          },
        );
        ad.show();
      },
      onAdFailedToLoad: (error) {
        if (kDebugMode) {
          print('❌ Interstitial ad failed to load: $error');
        }
        setState(() {
          _adShown = true;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink(); // Widget görünmez, sadece reklam gösterir
  }
}

class FortuneResultScreen extends StatefulWidget {
  final FortuneModel fortune;
  
  const FortuneResultScreen({
    Key? key,
    required this.fortune,
  }) : super(key: key);

  @override
  State<FortuneResultScreen> createState() => _FortuneResultScreenState();
}

class _FortuneResultScreenState extends State<FortuneResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _contentController;
  late AnimationController _cardController;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _contentAnimation;
  late Animation<double> _cardAnimation;
  
  bool _isLoading = false;
  bool _isFavorite = false;
  double _rating = 0.0;
  final AdsService _ads = AdsService();
  DateTime? _availableAt;
  final GlobalKey _cardKey = GlobalKey();
  
  // Coffee fortunes artık PageView kullanmıyor, tek sayfada gösteriliyor

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkFavoriteStatus();
    _refreshFromFirestore();
    _loadAvailability();
    
    // Coffee fortunes artık PageView kullanmıyor
    
    // Karma kesme işlemini sayfa tamamen yüklendikten sonra yap
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _deductKarmaIfNeeded();
      // Reklamı önceden yükle (ilk tıklamada hemen açılması için)
      _preloadRewardedAd();
    });
  }
  
  
  // Coffee fortunes artık PageView kullanmıyor, bu metod kullanılmıyor

  Future<void> _preloadRewardedAd() async {
    try {
      await _ads.createRewardedAd(
        adUnitId: _ads.rewardedAdUnitId,
        onAdLoaded: (_) {
          if (kDebugMode) {
            print('🎯 Rewarded ad preloaded successfully');
          }
        },
        onAdFailedToLoad: (_) {
          if (kDebugMode) {
            print('❌ Rewarded ad preload failed');
          }
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error preloading rewarded ad: $e');
      }
    }
  }

  Future<void> _deductKarmaIfNeeded() async {
    // Fortune ID boşsa, karma kesme işlemi yapılamaz
    if (widget.fortune.id.isEmpty) {
      return;
    }
    
    // Firestore'dan güncel karmaUsed değerini kontrol et
    int? firestoreKarmaUsed;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('readings')
          .doc(widget.fortune.id)
          .get();
      if (doc.exists) {
        firestoreKarmaUsed = doc.data()?['karmaUsed'] as int?;
      }
    } catch (e) {
      // Firestore okuma hatası - sessizce devam et
    }
    
    // Eğer Firestore'da karmaUsed set edilmişse, karma kesme
    if (firestoreKarmaUsed != null && firestoreKarmaUsed > 0) {
      return;
    }
    
    // Eğer daha önce karma kesilmemişse (karmaUsed == 0), şimdi kes
    if (widget.fortune.karmaUsed == 0) {
      try {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        
        if (userProvider.user == null) {
          return;
        }
        
        // Fal tipine göre karma miktarını al
        final fortuneTypeString = widget.fortune.type.toString().split('.').last;
        final karmaCost = PricingConstants.getFortuneCost(fortuneTypeString);
        
        // Karma kes
        final success = await userProvider.spendKarma(
          karmaCost,
          '${widget.fortune.typeDisplayName} falı',
        );
        
        if (success && mounted) {
          // Firestore'da karmaUsed değerini güncelle
          try {
            await FirebaseFirestore.instance
                .collection('readings')
                .doc(widget.fortune.id)
                .update({
              'karmaUsed': karmaCost,
            });
          } catch (e) {
            // Firestore güncelleme hatası - sessizce devam et
          }
        }
      } catch (e) {
        // Karma kesme hatası - sessizce devam et
      }
    }
  }

  void _loadAvailability() {
    try {
      final raw = widget.fortune.metadata['availableAt'];
      if (raw is String && raw.isNotEmpty) {
        _availableAt = DateTime.tryParse(raw);
      } else if (raw is Timestamp) {
        _availableAt = raw.toDate();
      }
      setState(() {});
    } catch (_) {}
  }

  bool get _isLocked {
    // Debug modda bekleme kilidini tamamen devre dışı bırak
    if (kDebugMode) return false;
    if (_availableAt == null) return false;
    return DateTime.now().isBefore(_availableAt!);
  }

  Future<void> _speedUp5Min() async {
    try {
      setState(() {
        _isLoading = true;
      });

      RewardItem? reward;
      
      // Reklam zaten yüklü mü kontrol et
      if (_ads.isRewardedLoaded) {
        // Reklam yüklü, direkt göster
        reward = await _ads.showRewardedAd();
      } else {
        // Reklam yüklü değilse yükle ve bekle (5s timeout)
        final loaded = Completer<bool>();
        await _ads.createRewardedAd(
          adUnitId: _ads.rewardedAdUnitId,
          onAdLoaded: (_) => loaded.complete(true),
          onAdFailedToLoad: (_) => loaded.complete(false),
        );
        bool ok = false;
        try { 
          ok = await loaded.future.timeout(const Duration(seconds: 5)); 
        } catch (_) {}
        
        if (ok) {
          // Reklam yüklendi, şimdi göster
          reward = await _ads.showRewardedAd();
        }
      }
      
      // Reklam izlendiyse zamanı güncelle
      if (reward != null && mounted) {
        setState(() {
          _availableAt = (_availableAt ?? DateTime.now()).subtract(const Duration(minutes: 5));
          _isLoading = false;
        });
        
        if (widget.fortune.id.isNotEmpty) {
          await FirebaseFirestore.instance.collection('readings').doc(widget.fortune.id).update({
            'metadata.availableAt': _availableAt!.toIso8601String(),
          });
        }
        
        // Reklam gösterildikten sonra bir sonraki için yeniden yükle
        _preloadRewardedAd();
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildImages() {
    if (widget.fortune.imageUrls.isEmpty) return const SizedBox.shrink();

    final urls = widget.fortune.imageUrls.where((u) => u.trim().isNotEmpty).toList();
    if (urls.isEmpty) return const SizedBox.shrink();

    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    final textColor = AppColors.getTextPrimary(isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.images,
          style: AppTextStyles.headingSmall.copyWith(color: textColor),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: urls.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final url = urls[index];
              return SizedBox(
                width: 90, // 3/4 aspect ratio için: 120 * 3/4 = 90
                height: 120,
                child: MysticalCard(
                  showGlow: true,
                  enforceAspectRatio: false,
                  toggleFlipOnTap: false,
                  onTap: () => ImageViewer.show(
                    context: context,
                    imageUrl: url,
                  ),
                  padding: EdgeInsets.zero,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      url,
                      width: 90,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 90,
                        height: 120,
                        color: Colors.white10,
                        child: const Center(
                          child: Icon(Icons.broken_image, color: Colors.white54),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _initializeAnimations() {
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));
    
    _contentAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: Curves.elasticOut,
    ));
    
    _cardAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: Curves.bounceOut,
    ));
    
    // Blinking animation disabled
    // _backgroundController.repeat(reverse: true);
    _contentController.forward();
    
    // Stagger card animations
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _cardController.forward();
      }
    });
  }

  void _checkFavoriteStatus() {
    setState(() {
      _isFavorite = widget.fortune.isFavorite;
      _rating = widget.fortune.rating.toDouble();
    });
  }

  Future<void> _refreshFromFirestore() async {
    try {
      if (widget.fortune.id.isEmpty) return;
      final doc = await FirebaseFirestore.instance
          .collection('readings')
          .doc(widget.fortune.id)
          .get();
      if (!doc.exists) return;
      final data = doc.data() ?? {};
      final fav = (data['isFavorite'] ?? _isFavorite) as bool;
      final rt = ((data['rating'] ?? _rating) as num).toDouble();
      if (!mounted) return;
      setState(() {
        _isFavorite = fav;
        _rating = rt;
      });
    } catch (_) {}
  }

  void _toggleFavorite() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Update in root 'readings' collection to match generation storage
      await FortuneService().toggleFortuneFavorite(widget.fortune.id, !_isFavorite);
      
      setState(() {
        _isFavorite = !_isFavorite;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isFavorite ? AppStrings.addedToFavorites : AppStrings.removedFromFavorites,
          ),
          backgroundColor: AppColors.success,
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
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _rateFortune(double rating) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await FortuneService().updateFortuneRating(widget.fortune.id, rating);
      
      setState(() {
        _rating = rating;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.ratingSubmitted),
          backgroundColor: AppColors.success,
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
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _shareFortune() async {
    if (_isLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.fortuneStillPreparing),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final title = widget.fortune.title;
    final text = widget.fortune.interpretation;
    final content = '$title\n\n$text\n\nFalla ile falına bak!';

    try {
      await ShareUtils.captureAndShare(
        key: _cardKey,
        text: content,
        subject: title,
      );
    } catch (e) {
      // Eğer görüntü paylaşımı başarısız olursa, sadece metin paylaş
      debugPrint('ShareUtils failed, using text share: $e');
      try {
        await Share.share(content, subject: title);
      } catch (shareError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${AppStrings.error}: ${AppStrings.shareFailed}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Widget _getFortuneTypeIcon() {
    switch (widget.fortune.type) {
      case FortuneType.tarot:
        return Image.asset(
          'assets/icons/tarot.png',
          width: 48,
          height: 48,
          errorBuilder: (_, __, ___) => const Text('🔮', style: TextStyle(fontSize: 48)),
        );
      case FortuneType.coffee:
        return Image.asset(
          'assets/icons/coffee.png',
          width: 48,
          height: 48,
          errorBuilder: (_, __, ___) => const Text('☕', style: TextStyle(fontSize: 48)),
        );
      case FortuneType.palm:
        return Image.asset(
          'assets/icons/palm.png',
          width: 48,
          height: 48,
          errorBuilder: (_, __, ___) => const Text('✋', style: TextStyle(fontSize: 48)),
        );
      case FortuneType.astrology:
        return Image.asset(
          'assets/icons/astrology.png',
          width: 48,
          height: 48,
          errorBuilder: (_, __, ___) => const Text('⭐', style: TextStyle(fontSize: 48)),
        );
      case FortuneType.face:
        return Image.asset(
          'assets/icons/face.png',
          width: 48,
          height: 48,
          errorBuilder: (_, __, ___) => const Text('👤', style: TextStyle(fontSize: 48)),
        );
      case FortuneType.katina:
        return Image.asset(
          'assets/icons/katina.png',
          width: 48,
          height: 48,
          errorBuilder: (_, __, ___) => const Text('🔮', style: TextStyle(fontSize: 48)),
        );
      case FortuneType.dream:
        return Image.asset(
          'assets/icons/dream.png',
          width: 48,
          height: 48,
          errorBuilder: (_, __, ___) => const Text('🌙', style: TextStyle(fontSize: 48)),
        );
      default:
        return const Text('🔮', style: TextStyle(fontSize: 48));
    }
  }

  Color _getFortuneTypeColor() {
    switch (widget.fortune.type) {
      case FortuneType.tarot:
        return AppColors.primary;
      case FortuneType.coffee:
        return AppColors.secondary;
      case FortuneType.palm:
        return AppColors.accent;
      case FortuneType.astrology:
        return AppColors.premium;
      default:
        return AppColors.primary;
    }
  }

  bool _isDreamDraw() {
    try {
      final src = widget.fortune.metadata['source']?.toString();
      return widget.fortune.type == FortuneType.dream && src == 'dream_draw';
    } catch (_) {
      return false;
    }
  }

  String _getTypeDisplay() {
    if (_isDreamDraw()) return AppStrings.dreamDrawing;
    return widget.fortune.typeDisplayName;
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
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RepaintBoundary(
                        key: _cardKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 24),
                            if (!_isLocked) _buildInterpretation(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildImages(),
                      const SizedBox(height: 24),
                      _buildSelectedCards(),
                      const SizedBox(height: 24),
                      if (_isLocked || kDebugMode) _buildLockedCard(),
                      if (!_isLocked) ...[
                        const SizedBox(height: 24),
                        _buildRatingSection(),
                      ],
                      const SizedBox(height: 24),
                      _buildActionButtons(),
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
  }

  Widget _buildLockedCard() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
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
            AppColors.cardBackground.withValues(alpha: 0.95),
            AppColors.cardBackground.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  AppColors.secondary,
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.5),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(
              Icons.psychology,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: Text(
            AppStrings.fortuneTellerLooking,
            style: AppTextStyles.headingMedium.copyWith(
                color: textColor,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
            AppStrings.speedUpFortuneTeller,
            style: AppTextStyles.bodyMedium.copyWith(
                color: textSecondaryColor,
            ),
            textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
          ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 54,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.secondary,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isLoading ? null : _speedUp5Min,
                borderRadius: BorderRadius.circular(16),
                child: Center(
                  child: _isLoading
                      ? MysticalLoading(
                          type: MysticalLoadingType.spinner,
                          size: 24,
                          color: Colors.white,
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CachedFallaLogo(
                              size: 22,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                              AppStrings.speedUpFortuneTellerButton,
                              style: AppTextStyles.buttonLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final textColor = AppColors.getTextPrimary(isDark);
    final iconColor = AppColors.getIconColor(isDark);
    
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
              AppStrings.fortuneResult,
              style: AppTextStyles.headingMedium.copyWith(
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            onPressed: _isLoading ? null : _toggleFavorite,
            icon: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: MysticalLoading(
                      type: MysticalLoadingType.spinner,
                      size: 20,
                      strokeWidth: 2,
                      color: iconColor,
                    ),
                  )
                : Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? AppColors.love : iconColor,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _contentAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _contentAnimation.value,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _getFortuneTypeColor().withValues(alpha: 0.8),
                  _getFortuneTypeColor().withValues(alpha: 0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _getFortuneTypeColor().withValues(alpha: 0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _getFortuneTypeColor().withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                  _getFortuneTypeIcon(),
                const SizedBox(height: 16),
                Text(
                  widget.fortune.title,
                  style: AppTextStyles.headingMedium.copyWith(
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _getTypeDisplay().toUpperCase(),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _formatDate(widget.fortune.createdAt),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectedCards() {
    if (widget.fortune.selectedCards.isEmpty) {
      return const SizedBox.shrink();
    }

    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    final textColor = AppColors.getTextPrimary(isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.selectedCards,
          style: AppTextStyles.headingSmall.copyWith(
            color: textColor,
          ),
        ),
        const SizedBox(height: 16),
        Builder(
          builder: (context) {
            final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
            final isDarkMode = themeProvider.isDarkMode;
            
            return AnimatedBuilder(
          animation: _cardAnimation,
          builder: (context, child) {
            // selectedCards boş olabilir, güvenli kontrol
            final selectedCards = widget.fortune.selectedCards;
            if (selectedCards.isEmpty) {
              return const SizedBox.shrink();
            }
            
            return SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: selectedCards.length,
                itemBuilder: (context, index) {
                  // Index range kontrolü
                  if (index >= selectedCards.length) {
                    return const SizedBox.shrink();
                  }
                  final id = selectedCards[index];
                  final data = _getTarotCardData(id);
                  final displayName = AppStrings.getTarotCardName(id);
                  final asset = data['asset'];
                  return TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 400 + (index * 200)),
                    tween: Tween(begin: 0.0, end: 1.0),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          width: 130,
                          margin: const EdgeInsets.only(right: 16),
                          child: MysticalCard(
                            showGlow: true,
                            aspectRatio: 3/4,
                            toggleFlipOnTap: false,
                            onTap: asset != null
                                ? () => ImageViewer.show(
                                      context: context,
                                      imageAsset: asset,
                                      title: displayName,
                                    )
                                : null,
                            padding: EdgeInsets.zero,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  if (asset != null)
                                    Image.asset(
                                      asset,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                            color: isDarkMode ? Colors.white10 : Colors.grey[200],
                                            child: Center(
                                              child: Icon(
                                                Icons.broken_image,
                                                color: isDarkMode ? Colors.white54 : Colors.grey[600],
                                              ),
                                            ),
                                      ),
                                    )
                                  else
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: AppColors.mysticalGradient,
                                      ),
                                          child: CachedFallaLogo(
                                            size: 24,
                                            color: isDarkMode ? Colors.white : Colors.black87,
                                          ),
                                    ),
                                  Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: isDarkMode 
                                                ? Colors.black.withOpacity(0.45)
                                                : Colors.white.withOpacity(0.9),
                                          ),
                                      child: Text(
                                        displayName,
                                            style: AppTextStyles.bodySmall.copyWith(
                                              color: isDarkMode ? Colors.white : Colors.black87,
                                              fontWeight: FontWeight.w600,
                                            ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
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
                },
              ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Map<String, String> _getTarotCardData(String id) {
    // Map id -> asset path (name is now handled by AppStrings.getTarotCardName)
    const entries = [
      {'id': 'the_fool', 'name': 'Deli', 'asset': 'assets/tarot/kartlar/deli-thefool.png'},
      {'id': 'magician', 'name': 'Büyücü', 'asset': 'assets/tarot/kartlar/buyucu-themagician.png'},
      {'id': 'high_priestess', 'name': 'Başrahibe', 'asset': 'assets/tarot/kartlar/basrahibe-theıııgprıestess.png'},
      {'id': 'empress', 'name': 'İmparatoriçe', 'asset': 'assets/tarot/kartlar/imparatorice-theempress.png'},
      {'id': 'emperor', 'name': 'İmparator', 'asset': 'assets/tarot/kartlar/imparator-theemperor.png'},
      {'id': 'hierophant', 'name': 'Aziz', 'asset': 'assets/tarot/kartlar/aziz-thehıerophant.png'},
      {'id': 'lovers', 'name': 'Aşıklar', 'asset': 'assets/tarot/kartlar/asiklar-thelovers.png'},
      {'id': 'chariot', 'name': 'Savaş Arabası', 'asset': 'assets/tarot/kartlar/savasarabasi-thecariot.png'},
      {'id': 'strength', 'name': 'Güç', 'asset': 'assets/tarot/kartlar/güc-thestrength.png'},
      {'id': 'hermit', 'name': 'Ermiş', 'asset': 'assets/tarot/kartlar/ermis-thehermit.png'},
      {'id': 'wheel_of_fortune', 'name': 'Kader Çarkı', 'asset': 'assets/tarot/kartlar/kadercarki-wheeloffortune.png'},
      {'id': 'justice', 'name': 'Adalet', 'asset': 'assets/tarot/kartlar/adalet-justice.png'},
      {'id': 'the_hanged_man', 'name': 'Asılan Adam', 'asset': 'assets/tarot/kartlar/asilanadam-thehangedman.png'},
      {'id': 'death', 'name': 'Ölüm', 'asset': 'assets/tarot/kartlar/olum-death.png'},
      {'id': 'temperance', 'name': 'Denge', 'asset': 'assets/tarot/kartlar/denge-thetemperance.png'},
      {'id': 'devil', 'name': 'Şeytan', 'asset': 'assets/tarot/kartlar/seytan-thedevil.png'},
      {'id': 'the_tower', 'name': 'Kule', 'asset': 'assets/tarot/kartlar/kule-thetower.png'},
      {'id': 'the_moon', 'name': 'Ay', 'asset': 'assets/tarot/kartlar/ay-themoon.png'},
      {'id': 'the_sun', 'name': 'Güneş', 'asset': 'assets/tarot/kartlar/gunes-thesun.png'},
      {'id': 'judgement', 'name': 'Mahkeme', 'asset': 'assets/tarot/kartlar/mahkeme-judugent.png'},
      {'id': 'the_world', 'name': 'Dünya', 'asset': 'assets/tarot/kartlar/dunya-theworld.png'},
      {'id': 'page_of_swords', 'name': 'Vale Kılıç', 'asset': 'assets/tarot/kartlar/valekilic-pageofswords.png'},
      {'id': 'page_of_cups', 'name': 'Vale Kupalar', 'asset': 'assets/tarot/kartlar/valekupalar-pageofcups.png'},
      {'id': 'page_of_wands', 'name': 'Vale Değnek', 'asset': 'assets/tarot/kartlar/valedegnek-pageofwands.png'},
      {'id': 'page_of_pentacles', 'name': 'Vale Tılsım', 'asset': 'assets/tarot/kartlar/valetilsim-pageofpentacles.png'},
      {'id': 'knight_of_swords', 'name': 'Şövalye Kılıç', 'asset': 'assets/tarot/kartlar/sovalyekilic-knightofswords.png'},
      {'id': 'knight_of_wands', 'name': 'Şövalye Değnek', 'asset': 'assets/tarot/kartlar/sovalyedegnek-knightofwands.png'},
      {'id': 'knight_of_pentacles', 'name': 'Şövalye Tılsım', 'asset': 'assets/tarot/kartlar/sovalyetilsim-knightofpentacles.png'},
      {'id': 'knight_of_cups', 'name': 'Şövalye Kupalar', 'asset': 'assets/tarot/kartlar/sovalyekupalar-knıghtofcups.png'},
      {'id': 'queen_of_pentacles', 'name': 'Kraliçe Tılsım', 'asset': 'assets/tarot/kartlar/kralicetilsim-quennofpentacles.png'},
      {'id': 'queen_of_cups', 'name': 'Kraliçe Kupalar', 'asset': 'assets/tarot/kartlar/kralicekupalar-queenofcups.png'},
      {'id': 'queen_of_swords', 'name': 'Kraliçe Kılıç', 'asset': 'assets/tarot/kartlar/kralicekilic-quennofswords.png'},
      {'id': 'queen_of_wands', 'name': 'Kraliçe Değnek', 'asset': 'assets/tarot/kartlar/kralicedegnek-quennofwands.png'},
      {'id': 'king_of_pentacles', 'name': 'Kral Tılsım', 'asset': 'assets/tarot/kartlar/kraltilsim-kingofpentacles.png'},
      {'id': 'king_of_cups', 'name': 'Kral Kupalar', 'asset': 'assets/tarot/kartlar/kralkupalar-kingofcups.png'},
      {'id': 'king_of_swords', 'name': 'Kral Kılıç', 'asset': 'assets/tarot/kartlar/kralkilic-kingofswords.png'},
      {'id': 'king_of_wands', 'name': 'Kral Değnek', 'asset': 'assets/tarot/kartlar/kraldegnek-kingofwands.png'},
    ];
    for (final e in entries) {
      if (e['id'] == id) return {'asset': e['asset']!};
    }
    return {};
  }

  Widget _buildInterpretation() {
    // Tarot ve kahve falı için özel widget
    if (widget.fortune.type == FortuneType.tarot) {
      return _buildTarotInterpretation();
    } else if (widget.fortune.type == FortuneType.coffee) {
      return _buildCoffeeInterpretation();
    }
    
    // Diğer fallar için normal widget
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
                _getFortuneTypeColor().withValues(alpha: 0.8 + (_backgroundAnimation.value * 0.1)),
                _getFortuneTypeColor().withValues(alpha: 0.6 + (_backgroundAnimation.value * 0.1)),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.2 + (_backgroundAnimation.value * 0.1)),
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CachedFallaLogo(
                    size: 24,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isDreamDraw() ? 'Rüya Çizimi' : AppStrings.interpretation,
                      style: AppTextStyles.headingSmall.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.star,
                    color: Colors.white54,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SelectableText(
                Helpers.cleanMarkdown(widget.fortune.interpretation),
                style: AppTextStyles.fortuneResult.copyWith(
                  color: Colors.white,
                  height: 1.6,
                ),
                textAlign: TextAlign.justify,
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Falla',
                  style: AppTextStyles.headingLarge.copyWith(
                    color: Colors.white38,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTarotInterpretation() {
    final interpretation = Helpers.cleanMarkdown(widget.fortune.interpretation);
    final cardSections = _parseTarotInterpretation(interpretation);
    
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
                          _getFortuneTypeColor().withValues(alpha: 0.8 + (_backgroundAnimation.value * 0.1)),
                          _getFortuneTypeColor().withValues(alpha: 0.6 + (_backgroundAnimation.value * 0.1)),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.2 + (_backgroundAnimation.value * 0.1)),
                          blurRadius: 15,
                          spreadRadius: 2,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CachedFallaLogo(
                                size: 24,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  AppStrings.interpretation,
                                  style: AppTextStyles.headingSmall.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
              const SizedBox(height: 20),
              // Tüm kart yorumlarını tek kartta göster
              ...cardSections.asMap().entries.map((entry) {
                final index = entry.key;
                final section = entry.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kart yorumu
                          _buildTarotCardSection(
                            section['title'] ?? '',
                            section['content'] ?? '',
                          ),
                    // Son kart değilse reklam göster
                    if (index < cardSections.length - 1) ...[
                          const SizedBox(height: 16),
                          _AdWidget(
                            adsService: _ads,
                            onAdShown: () {
                              _ads.createInterstitialAd(
                                adUnitId: _ads.interstitialAdUnitId,
                              );
                            },
                          ),
                      const SizedBox(height: 16),
                    ],
                  ],
                );
              }).toList(),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Falla',
                  style: AppTextStyles.headingLarge.copyWith(
                    color: Colors.white38,
                    fontSize: 16,
                  ),
                ),
                          ),
                      ],
                    ),
        );
      },
    );
  }

  Widget _buildCoffeeInterpretation() {
    final interpretation = Helpers.cleanMarkdown(widget.fortune.interpretation);
    
    // Topics'i farklı formatlardan al
    List<dynamic> topics = [];
    if (widget.fortune.inputData.containsKey('topics')) {
      final topicsData = widget.fortune.inputData['topics'];
      if (topicsData is List) {
        topics = topicsData;
      } else if (topicsData is String) {
        // Eğer string ise, parse et
        try {
          topics = (topicsData.split(',') as List).map((e) => e.trim()).toList();
        } catch (_) {
          topics = [topicsData];
        }
      }
    }
    
    // Eğer topics yoksa, topic1 ve topic2'den oluştur
    if (topics.isEmpty) {
      if (widget.fortune.inputData.containsKey('topic1')) {
        topics.add(widget.fortune.inputData['topic1']);
      }
      if (widget.fortune.inputData.containsKey('topic2')) {
        topics.add(widget.fortune.inputData['topic2']);
      }
    }
    
    final topicSections = _parseCoffeeInterpretation(interpretation, topics);
    
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
                          _getFortuneTypeColor().withValues(alpha: 0.8 + (_backgroundAnimation.value * 0.1)),
                          _getFortuneTypeColor().withValues(alpha: 0.6 + (_backgroundAnimation.value * 0.1)),
                        ],
                      ),
            borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
              width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.2 + (_backgroundAnimation.value * 0.1)),
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CachedFallaLogo(
                      size: 24,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  AppStrings.interpretation,
                                  style: AppTextStyles.headingSmall.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                const SizedBox(height: 20),
                // Tüm topic'leri tek sayfada göster
                ...topicSections.asMap().entries.map((entry) {
                  final index = entry.key;
                  final section = entry.value;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Topic yorumu
                          _buildCoffeeTopicSection(
                            section['title'] ?? '',
                            section['content'] ?? '',
                          ),
                      // Son topic değilse reklam göster
                      if (index < topicSections.length - 1) ...[
                          const SizedBox(height: 16),
                          _AdWidget(
                            adsService: _ads,
                            onAdShown: () {
                              _ads.createInterstitialAd(
                                adUnitId: _ads.interstitialAdUnitId,
                              );
                            },
                          ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  );
                }).toList(),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Falla',
                    style: AppTextStyles.headingLarge.copyWith(
                      color: Colors.white38,
                      fontSize: 16,
                    ),
                  ),
                          ),
                      ],
                    ),
              ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _parseTarotInterpretation(String interpretation) {
    final sections = <Map<String, dynamic>>[];
    
    // ÖNCE: Tüm kart numaralarını ve pozisyonlarını bul (1, 2, 3)
    // Daha agresif yaklaşım: Her kart için ayrı ayrı parse et
    final allCards = <Map<String, dynamic>>[];
    final foundCardNumbers = <int>{};
    
    // Her kart için (1, 2, 3) ayrı ayrı parse et
    for (int cardNum = 1; cardNum <= 3; cardNum++) {
      if (foundCardNumbers.contains(cardNum)) {
        continue;
      }
      
      // Türkçe pattern'ler - her kart numarası için ayrı pattern
      List<RegExp> turkishPatterns;
      if (cardNum == 1) {
        turkishPatterns = [
          // "kart: [KART ADI] şunu açıklıyor: [AÇIKLAMA]" (1. kart için "1." eksik olabilir - metnin başında)
          RegExp(r'^(?:1\.\s*)?kart[:\s]+([^:]+?)\s*(?:şunu|açıklıyor|açıklıyor:)[:\s]*(.+?)(?=\d+\.\s*kart|Genel Yorum|General Interpretation|Üç kartın birleşik mesajı|3 kartın birleşik mesajı|$)', caseSensitive: false, dotAll: true, multiLine: true),
          // "1. kart: [KART ADI] şunu açıklıyor: [AÇIKLAMA]"
          RegExp(r'1\.\s*kart[:\s]+([^:]+?)\s*(?:şunu|açıklıyor|açıklıyor:)[:\s]*(.+?)(?=\d+\.\s*kart|Genel Yorum|General Interpretation|Üç kartın birleşik mesajı|3 kartın birleşik mesajı|$)', caseSensitive: false, dotAll: true),
          // "kart: [AÇIKLAMA]" (1. kart için "1." eksik, kart adı yok - metnin başında)
          RegExp(r'^(?:1\.\s*)?kart[:\s]+(.+?)(?=\d+\.\s*kart|Genel Yorum|General Interpretation|Üç kartın birleşik mesajı|3 kartın birleşik mesajı|$)', caseSensitive: false, dotAll: true, multiLine: true),
          // "1. kart: [AÇIKLAMA]" (kart adı yok)
          RegExp(r'1\.\s*kart[:\s]+(.+?)(?=\d+\.\s*kart|Genel Yorum|General Interpretation|Üç kartın birleşik mesajı|3 kartın birleşik mesajı|$)', caseSensitive: false, dotAll: true),
        ];
      } else if (cardNum == 2) {
        turkishPatterns = [
          RegExp(r'2\.\s*kart[:\s]+([^:]+?)\s*(?:şunu|açıklıyor|açıklıyor:)[:\s]*(.+?)(?=\d+\.\s*kart|Genel Yorum|General Interpretation|Üç kartın birleşik mesajı|3 kartın birleşik mesajı|$)', caseSensitive: false, dotAll: true),
          RegExp(r'2\.\s*kart[:\s]+(.+?)(?=\d+\.\s*kart|Genel Yorum|General Interpretation|Üç kartın birleşik mesajı|3 kartın birleşik mesajı|$)', caseSensitive: false, dotAll: true),
        ];
      } else {
        turkishPatterns = [
          RegExp(r'3\.\s*kart[:\s]+([^:]+?)\s*(?:şunu|açıklıyor|açıklıyor:)[:\s]*(.+?)(?=\d+\.\s*kart|Genel Yorum|General Interpretation|Üç kartın birleşik mesajı|3 kartın birleşik mesajı|$)', caseSensitive: false, dotAll: true),
          RegExp(r'3\.\s*kart[:\s]+(.+?)(?=\d+\.\s*kart|Genel Yorum|General Interpretation|Üç kartın birleşik mesajı|3 kartın birleşik mesajı|$)', caseSensitive: false, dotAll: true),
        ];
      }
      
      // İngilizce pattern'ler - her kart numarası için ayrı pattern
      List<RegExp> englishPatterns;
      if (cardNum == 1) {
        englishPatterns = [
          // "Card: [CARD NAME] tells: [EXPLANATION]" (1. kart için "Card 1" yerine "Card" olabilir - metnin başında)
          RegExp(r'^(?:Card\s+1[:\s]+|Card[:\s]+)([^:]+?)\s*(?:tells?|represents?|means?)[:\s]*(.+?)(?=Card\s+\d+|General Interpretation|Genel Yorum|When the 3 cards come together|$)', caseSensitive: false, dotAll: true, multiLine: true),
          RegExp(r'Card\s+1[:\s]+([^:]+?)\s*(?:tells?|represents?|means?)[:\s]*(.+?)(?=Card\s+\d+|General Interpretation|Genel Yorum|When the 3 cards come together|$)', caseSensitive: false, dotAll: true),
          // "Card: [EXPLANATION]" (1. kart için "Card 1" yerine "Card" olabilir - metnin başında)
          RegExp(r'^(?:Card\s+1[:\s]+|Card[:\s]+)(.+?)(?=Card\s+\d+|General Interpretation|Genel Yorum|When the 3 cards come together|$)', caseSensitive: false, dotAll: true, multiLine: true),
          RegExp(r'Card\s+1[:\s]+(.+?)(?=Card\s+\d+|General Interpretation|Genel Yorum|When the 3 cards come together|$)', caseSensitive: false, dotAll: true),
        ];
      } else if (cardNum == 2) {
        englishPatterns = [
          RegExp(r'Card\s+2[:\s]+([^:]+?)\s*(?:tells?|represents?|means?)[:\s]*(.+?)(?=Card\s+\d+|General Interpretation|Genel Yorum|When the 3 cards come together|$)', caseSensitive: false, dotAll: true),
          RegExp(r'Card\s+2[:\s]+(.+?)(?=Card\s+\d+|General Interpretation|Genel Yorum|When the 3 cards come together|$)', caseSensitive: false, dotAll: true),
    ];
      } else {
        englishPatterns = [
          RegExp(r'Card\s+3[:\s]+([^:]+?)\s*(?:tells?|represents?|means?)[:\s]*(.+?)(?=Card\s+\d+|General Interpretation|Genel Yorum|When the 3 cards come together|$)', caseSensitive: false, dotAll: true),
          RegExp(r'Card\s+3[:\s]+(.+?)(?=Card\s+\d+|General Interpretation|Genel Yorum|When the 3 cards come together|$)', caseSensitive: false, dotAll: true),
        ];
      }
      
      // Önce Türkçe pattern'leri dene
      for (int patternIndex = 0; patternIndex < turkishPatterns.length; patternIndex++) {
        final pattern = turkishPatterns[patternIndex];
        final match = pattern.firstMatch(interpretation);
        if (match != null) {
          final cardName = match.group(1)?.trim() ?? '';
          final cardContent = (match.groupCount >= 2 && match.group(2) != null) 
              ? match.group(2)!.trim() 
              : cardName;
          
          if (cardContent.isNotEmpty && cardContent.length > 30) {
            String actualCardName = '';
            String actualContent = cardContent;
            
            // Eğer group(2) varsa, group(1) kart adı, group(2) içerik
            if (match.groupCount >= 2 && match.group(2) != null && cardName.length < 100) {
              if (cardName.length > 50) {
                actualContent = cardName;
                actualCardName = '';
              } else {
                actualCardName = cardName;
                actualContent = match.group(2)!.trim();
              }
            }
            
            String cleanedContent = actualContent.replaceAll(RegExp(r'\[|\]'), '').trim();
            String cleanedCardName = actualCardName.replaceAll(RegExp(r'\[|\]'), '').trim();
            
            if (cleanedContent.isNotEmpty) {
              allCards.add({
                'number': cardNum,
                'title': AppStrings.isEnglish 
                    ? 'Card $cardNum${cleanedCardName.isNotEmpty ? ': $cleanedCardName' : ''} tells:'
                    : '$cardNum. kart${cleanedCardName.isNotEmpty ? ': $cleanedCardName' : ''} şunu açıklıyor:',
                'content': cleanedContent,
              });
              foundCardNumbers.add(cardNum);
              break; // Bu kartı bulduk, diğer pattern'lere gerek yok
            }
          }
        }
      }
      
      // Türkçe'de bulunamadıysa İngilizce pattern'leri dene
      if (!foundCardNumbers.contains(cardNum)) {
        for (int patternIndex = 0; patternIndex < englishPatterns.length; patternIndex++) {
          final pattern = englishPatterns[patternIndex];
          final match = pattern.firstMatch(interpretation);
          if (match != null) {
            final cardName = match.group(1)?.trim() ?? '';
            final cardContent = (match.groupCount >= 2 && match.group(2) != null) 
                ? match.group(2)!.trim() 
                : cardName;
          
            if (cardContent.isNotEmpty && cardContent.length > 30) {
            String actualCardName = '';
            String actualContent = cardContent;
            
              if (match.groupCount >= 2 && match.group(2) != null && cardName.length < 100) {
              if (cardName.length > 50) {
                actualContent = cardName;
                actualCardName = '';
              } else {
                actualCardName = cardName;
                  actualContent = match.group(2)!.trim();
              }
            }
            
              String cleanedContent = actualContent.replaceAll(RegExp(r'\[|\]'), '').trim();
              String cleanedCardName = actualCardName.replaceAll(RegExp(r'\[|\]'), '').trim();
            
              if (cleanedContent.isNotEmpty) {
                allCards.add({
                  'number': cardNum,
              'title': AppStrings.isEnglish 
                      ? 'Card $cardNum${cleanedCardName.isNotEmpty ? ': $cleanedCardName' : ''} tells:'
                      : '$cardNum. kart${cleanedCardName.isNotEmpty ? ': $cleanedCardName' : ''} şunu açıklıyor:',
              'content': cleanedContent,
            });
                foundCardNumbers.add(cardNum);
                break;
              }
            }
          }
        }
      }
    }
    
    // Kartları numaraya göre sırala
    allCards.sort((a, b) => (a['number'] as int).compareTo(b['number'] as int));
    
    // Sıralı kartları sections'a ekle
    for (final card in allCards) {
      sections.add({
        'title': card['title'] as String,
        'content': card['content'] as String,
      });
    }
    
    print('🔮 TAROT PARSE DEBUG - Final sections count: ${sections.length}');
    
    // Genel Yorum bölümünü bul - "Üç kartın birleşik mesajı" gibi başlıkları yakala
    // Önce orijinal metinde "Üç kartın birleşik mesajı" gibi pattern'leri ara
    final generalPatterns = [
      // "Üç kartın birleşik mesajı" ile başlayan metin (virgül, iki nokta veya boşluk ile devam edebilir)
      RegExp(r'(?:Üç kartın birleşik mesajı|3 kartın birleşik mesajı|Üç kart bir araya|3 kart bir araya)[:\s,]*\s*(.+?)$', caseSensitive: false, dotAll: true),
      // "Genel Yorum" ile başlayan metin
      RegExp(r'(?:Genel Yorum|General Interpretation)[:\s]*(.+?)$', caseSensitive: false, dotAll: true),
      // "When the 3 cards come together" ile başlayan metin
      RegExp(r'(?:When the 3 cards come together|3 cards together)[:\s]*(.+?)$', caseSensitive: false, dotAll: true),
    ];
    
    String? generalContent;
    // Önce orijinal metinde pattern'leri ara
    for (final pattern in generalPatterns) {
      final match = pattern.firstMatch(interpretation);
      if (match != null) {
        final content = match.group(1)?.trim() ?? '';
        // İçerik yeterince uzunsa ve kart pattern'i içermiyorsa, genel yorum olarak kabul et
        if (content.length > 50 && !content.contains(RegExp(r'\d+\.\s*kart', caseSensitive: false))) {
          generalContent = content;
          break;
        }
      }
    }
    
    // Eğer pattern ile bulunamadıysa, kartlardan sonra kalan metni kontrol et
    if (generalContent == null) {
      // Tüm kart bölümlerini metinden çıkar
      String textAfterCards = interpretation;
      // Kart pattern'lerini temizle - her kart için ayrı ayrı
      textAfterCards = textAfterCards.replaceAll(RegExp(r'1\.\s*kart[:\s]+.+?(?=\d+\.\s*kart|Genel Yorum|General Interpretation|Üç kartın birleşik mesajı|3 kartın birleşik mesajı|$)', caseSensitive: false, dotAll: true), '');
      textAfterCards = textAfterCards.replaceAll(RegExp(r'2\.\s*kart[:\s]+.+?(?=\d+\.\s*kart|Genel Yorum|General Interpretation|Üç kartın birleşik mesajı|3 kartın birleşik mesajı|$)', caseSensitive: false, dotAll: true), '');
      textAfterCards = textAfterCards.replaceAll(RegExp(r'3\.\s*kart[:\s]+.+?(?=\d+\.\s*kart|Genel Yorum|General Interpretation|Üç kartın birleşik mesajı|3 kartın birleşik mesajı|$)', caseSensitive: false, dotAll: true), '');
      textAfterCards = textAfterCards.replaceAll(RegExp(r'Card\s+1[:\s]+.+?(?=Card\s+\d+|General Interpretation|Genel Yorum|When the 3 cards come together|$)', caseSensitive: false, dotAll: true), '');
      textAfterCards = textAfterCards.replaceAll(RegExp(r'Card\s+2[:\s]+.+?(?=Card\s+\d+|General Interpretation|Genel Yorum|When the 3 cards come together|$)', caseSensitive: false, dotAll: true), '');
      textAfterCards = textAfterCards.replaceAll(RegExp(r'Card\s+3[:\s]+.+?(?=Card\s+\d+|General Interpretation|Genel Yorum|When the 3 cards come together|$)', caseSensitive: false, dotAll: true), '');
      final remainingText = textAfterCards.trim();
      
      // Eğer kalan metin yeterince uzunsa ve kart pattern'i içermiyorsa
      if (remainingText.length > 50 && !remainingText.contains(RegExp(r'\d+\.\s*kart', caseSensitive: false))) {
        generalContent = remainingText;
      } else if (allCards.isEmpty) {
        // Hiç kart bulunamadıysa, tüm metni göster (pattern'de "Üç kartın birleşik mesajı" varsa)
        if (interpretation.contains(RegExp(r'Üç kartın birleşik mesajı|3 kartın birleşik mesajı', caseSensitive: false))) {
          // "Üç kartın birleşik mesajı" ile başlayan metni al
          final match = RegExp(r'Üç kartın birleşik mesajı[:\s,]*\s*(.+?)$', caseSensitive: false, dotAll: true).firstMatch(interpretation);
          if (match != null) {
            generalContent = match.group(1)?.trim() ?? interpretation.trim();
          } else {
            generalContent = interpretation.trim();
          }
        } else if (interpretation.trim().length > 50) {
          generalContent = interpretation.trim();
        }
      }
    }
    
    if (generalContent != null && generalContent.isNotEmpty) {
      sections.add({
        'title': AppStrings.isEnglish ? 'When the 3 cards come together…' : '3 kart bir araya geldiğinde…',
        'content': generalContent,
      });
    }
    
    // Eğer hiç section bulunamadıysa, tüm metni göster
    if (sections.isEmpty) {
      sections.add({
        'title': '',
        'content': interpretation,
      });
    }
    
    return sections;
  }

  List<Map<String, dynamic>> _parseCoffeeInterpretation(String interpretation, List<dynamic> topics) {
    final sections = <Map<String, dynamic>>[];
    
    // Eğer topics boşsa, interpretation'dan topic'leri çıkarmayı dene
    if (topics.isEmpty) {
      // Interpretation'dan topic pattern'lerini ara
      final topicPattern = RegExp(r'([A-ZÇĞIİÖŞÜ][a-zçğıöşü]+(?:\s+[A-ZÇĞIİÖŞÜ][a-zçğıöşü]+)*)\s*[:：]\s*', caseSensitive: false);
      final matches = topicPattern.allMatches(interpretation);
      
      if (matches.length >= 2) {
        // En az 2 topic bulundu, bunları kullan
        topics = matches.map((m) => m.group(1) ?? '').toList();
      } else {
        // Topics bulunamadı, normal göster
        sections.add({
          'title': '',
          'content': interpretation,
          'showAd': false,
        });
        return sections;
      }
    }
    
    // Topics'e göre metni böl
    final topicNames = topics.map((t) => t.toString()).toList();
    String remainingText = interpretation;
    
    // Her topic için "TOPIC NAME: INTERPRETATION" formatını ara (köşeli parantez olmadan)
    // İlk topic için özel kontrol: "TOPIC NAME:" veya sadece "TOPIC:" ile başlayabilir
    for (int i = 0; i < topicNames.length; i++) {
      final topicName = topicNames[i];
      final topicNameLower = topicName.toLowerCase();
      final escapedTopicName = RegExp.escape(topicName);
      final escapedTopicNameLower = RegExp.escape(topicNameLower);
      
      // Topic pattern'leri - her topic için tam içeriği yakala
      String? bestContent;
      int? topicStartIndex;
      int? contentEndIndex;
      
      // Önce topic'in başlangıç pozisyonunu bul (topic başlığı dahil)
      // İlk topic için özel pattern: metnin başında "TOPIC:" veya "TOPIC NAME:" olabilir
      final topicStartPatterns = i == 0
          ? [
              // İlk topic için: metnin başında "TOPIC:" veya "TOPIC NAME:" olabilir
              RegExp(r'^(?:\[?$escapedTopicName\]?|\[?$escapedTopicNameLower\]?)\s*[:：]', caseSensitive: false, multiLine: true),
              RegExp(r'^$escapedTopicName\s*[:：]', caseSensitive: false, multiLine: true),
              // Fallback: normal pattern
              RegExp('(?:\\[?$escapedTopicName\\]?|\\[?$escapedTopicNameLower\\]?)\\s*[:：]', caseSensitive: false),
              RegExp('$escapedTopicName\\s*[:：]', caseSensitive: false),
            ]
          : [
        RegExp('(?:\\[?$escapedTopicName\\]?|\\[?$escapedTopicNameLower\\]?)\\s*[:：]', caseSensitive: false),
        RegExp('$escapedTopicName\\s*[:：]', caseSensitive: false),
      ];
      
      int? topicHeaderStartIndex;
      for (final startPattern in topicStartPatterns) {
        final startMatch = startPattern.firstMatch(remainingText);
        if (startMatch != null) {
          topicHeaderStartIndex = startMatch.start; // Topic başlığının başlangıcı
          topicStartIndex = startMatch.end; // Topic içeriğinin başlangıcı
          break;
        }
      }
      
      if (topicStartIndex != null && topicHeaderStartIndex != null) {
        // Topic başlangıcından sonraki metni al
        String contentAfterTopic = remainingText.substring(topicStartIndex);
        
        // Sonraki topic veya "Genel Özet"e kadar içeriği bul
        if (i < topicNames.length - 1) {
          // Sonraki topic'e kadar al
          final nextTopic = topicNames[i + 1];
          final escapedNextTopic = RegExp.escape(nextTopic);
          final escapedNextTopicLower = RegExp.escape(nextTopic.toLowerCase());
          
          // Sonraki topic'in başlangıcını bul (daha esnek pattern)
          final nextTopicPatterns = [
            RegExp('(?:\\[?$escapedNextTopic\\]?|\\[?$escapedNextTopicLower\\]?)\\s*[:：]', caseSensitive: false),
            RegExp('$escapedNextTopic\\s*[:：]', caseSensitive: false),
            RegExp('\\b$escapedNextTopic\\b\\s*[:：]', caseSensitive: false),
          ];
          
          int? nextTopicMatchIndex;
          for (final pattern in nextTopicPatterns) {
            final match = pattern.firstMatch(contentAfterTopic);
            if (match != null) {
              nextTopicMatchIndex = match.start;
              break;
            }
          }
          
          if (nextTopicMatchIndex != null) {
            bestContent = contentAfterTopic.substring(0, nextTopicMatchIndex).trim();
            contentEndIndex = topicStartIndex + nextTopicMatchIndex;
          } else {
            // Sonraki topic bulunamadı - "Genel Özet" satır başında bulunana kadar TÜM metni al
            // SADECE satır başında "Genel Özet" ara (içerik içinde yanlış pozitif olmasın)
            final summaryPatternsAtLineStart = [
              RegExp(r'^\s*Genel\s+Özet', caseSensitive: false, multiLine: true),
              RegExp(r'^\s*General\s+Summary', caseSensitive: false, multiLine: true),
              RegExp(r'^\s*Özet\s*$', caseSensitive: false, multiLine: true),
              RegExp(r'^\s*Summary\s*$', caseSensitive: false, multiLine: true),
            ];
            
            int? summaryMatchIndex;
            for (final pattern in summaryPatternsAtLineStart) {
              final match = pattern.firstMatch(contentAfterTopic);
              if (match != null) {
                summaryMatchIndex = match.start;
                break;
              }
            }
            
            // Eğer satır başında bulunamadıysa, yeni satır + "Genel Özet" ara
            if (summaryMatchIndex == null) {
              final summaryPatternsAfterNewline = [
                RegExp(r'\n\s*Genel\s+Özet', caseSensitive: false),
                RegExp(r'\n\s*General\s+Summary', caseSensitive: false),
                RegExp(r'\n\s*Özet\s*$', caseSensitive: false, multiLine: true),
                RegExp(r'\n\s*Summary\s*$', caseSensitive: false, multiLine: true),
              ];
              
              for (final pattern in summaryPatternsAfterNewline) {
                final match = pattern.firstMatch(contentAfterTopic);
                if (match != null) {
                  summaryMatchIndex = match.start;
                  break;
                }
              }
            }
            
            if (summaryMatchIndex != null && summaryMatchIndex > 200) {
              // "Genel Özet" bulundu ve yeterince uzakta (en az 200 karakter sonra)
              bestContent = contentAfterTopic.substring(0, summaryMatchIndex).trim();
              contentEndIndex = topicStartIndex + summaryMatchIndex;
            } else {
              // "Genel Özet" bulunamadı veya çok yakında - KESİNLİKLE kalan TÜM metni al
              // Bu kritik: Topic'in tam içeriğini yakalamak için hiç kesme
              bestContent = contentAfterTopic.trim();
              contentEndIndex = remainingText.length;
            }
          }
        } else {
          // Son topic - "Genel Özet"e kadar veya metnin sonuna kadar
          // Daha geniş pattern'ler dene
          final summaryPatterns = [
            RegExp(r'^\s*Genel\s+Özet', caseSensitive: false, multiLine: true),
            RegExp(r'^\s*General\s+Summary', caseSensitive: false, multiLine: true),
            RegExp(r'Genel\s+Özet', caseSensitive: false),
            RegExp(r'General\s+Summary', caseSensitive: false),
            RegExp(r'^\s*Özet', caseSensitive: false, multiLine: true),
            RegExp(r'^\s*Summary', caseSensitive: false, multiLine: true),
            RegExp(r'\bÖzet\b', caseSensitive: false),
            RegExp(r'\bSummary\b', caseSensitive: false),
          ];
          
          int? summaryMatchIndex;
          for (final pattern in summaryPatterns) {
            final match = pattern.firstMatch(contentAfterTopic);
            if (match != null) {
              summaryMatchIndex = match.start;
              break;
            }
          }
          
          if (summaryMatchIndex != null && summaryMatchIndex > 50) {
            // "Genel Özet" bulundu ve yeterince uzakta
            bestContent = contentAfterTopic.substring(0, summaryMatchIndex).trim();
            contentEndIndex = topicStartIndex + summaryMatchIndex;
          } else {
            // "Genel Özet" bulunamadı veya çok yakında, kalan tüm metni al
            bestContent = contentAfterTopic.trim();
            contentEndIndex = remainingText.length;
          }
        }
      }
      
      if (bestContent != null && bestContent.isNotEmpty) {
        String content = bestContent;
        // Köşeli parantezleri temizle
        content = content.replaceAll(RegExp(r'\[|\]'), '');
        
        sections.add({
          'title': topicName,
          'content': content,
        });
        
        // Match'i remainingText'ten çıkar - topic başlığından içeriğin sonuna kadar
        if (topicHeaderStartIndex != null && contentEndIndex != null) {
          // Topic başlığından içeriğin sonuna kadar olan kısmı çıkar
          remainingText = remainingText.substring(0, topicHeaderStartIndex) + 
                         remainingText.substring(contentEndIndex);
        }
      } else {
        // Eğer pattern ile bulunamadıysa, topic adını içeren ilk paragrafı al
        final escapedTopicNameForFallback = RegExp.escape(topicName);
        final nextTopicForFallback = i < topicNames.length - 1 ? RegExp.escape(topicNames[i + 1]) : '';
        final fallbackEndPattern = i < topicNames.length - 1 
            ? nextTopicForFallback 
            : '(?:Genel Özet|Özet|General Summary|Summary|\$)';
        final fallbackPattern = RegExp('\\[?$escapedTopicNameForFallback\\]?[^\\n]*\\n(.+?)(?=$fallbackEndPattern)', caseSensitive: false, dotAll: true);
        final fallbackMatch = fallbackPattern.firstMatch(remainingText);
        if (fallbackMatch != null && fallbackMatch.group(1) != null && fallbackMatch.group(1)!.trim().isNotEmpty) {
          String content = fallbackMatch.group(1)!.trim();
          // Köşeli parantezleri temizle
          content = content.replaceAll(RegExp(r'\[|\]'), '');
          sections.add({
            'title': topicName,
            'content': content,
          });
          remainingText = remainingText.replaceFirst(fallbackMatch.group(0) ?? '', '');
        }
      }
    }
    
    // Genel Özet/Özet bölümünü bul - daha esnek pattern
    // Önce orijinal interpretation'dan da kontrol et (remainingText'te bulunamazsa)
    String textToSearch = remainingText.trim();
    if (textToSearch.isEmpty || textToSearch.length < 50) {
      // remainingText boş veya çok kısa ise, orijinal interpretation'dan kontrol et
      textToSearch = interpretation;
    }
    
    final summaryPatterns = [
      // "Genel Özet:" veya "Genel Özet " ile başlayan
      RegExp(r'(?:Genel\s+Özet|General\s+Summary)[:\s]+(.+?)$', caseSensitive: false, dotAll: true),
      // Sadece "Özet:" veya "Summary:" ile başlayan (ama topic isimleri değil)
      RegExp(r'(?:^|\n)\s*(?:Özet|Summary)[:\s]+(.+?)$', caseSensitive: false, dotAll: true),
      // "Genel Özet" kelimesini içeren ve sonrası
      RegExp(r'Genel\s+Özet[:\s]*(.+?)$', caseSensitive: false, dotAll: true),
      RegExp(r'General\s+Summary[:\s]*(.+?)$', caseSensitive: false, dotAll: true),
      // Daha genel pattern
      RegExp(r'(?:Genel\s+Özet|General\s+Summary|Özet|Summary)[:\s]*(.+?)$', caseSensitive: false, dotAll: true),
    ];
    
    Match? summaryMatch;
    for (final pattern in summaryPatterns) {
      final match = pattern.firstMatch(textToSearch);
      if (match != null && match.group(1) != null) {
        final content = match.group(1)!.trim();
        // Eğer içerik yeterince uzunsa ve topic isimleri değilse
        if (content.length > 50 && 
            !content.contains(RegExp(r'^[A-ZÇĞIİÖŞÜ]+:\s*[A-ZÇĞIİÖŞÜ]+:\s*$', caseSensitive: false))) {
        summaryMatch = match;
        break;
        }
      }
    }
    
    if (summaryMatch != null && summaryMatch.group(1) != null) {
      String summaryContent = summaryMatch.group(1)!.trim();
      // Köşeli parantezleri temizle
      summaryContent = summaryContent.replaceAll(RegExp(r'\[|\]'), '');
      // Eğer sadece topic isimleri varsa (LOVE:CAREER: gibi), atla
      if (summaryContent.isNotEmpty && 
          summaryContent.length > 50 &&
          !summaryContent.contains(RegExp(r'^[A-ZÇĞIİÖŞÜ]+:\s*[A-ZÇĞIİÖŞÜ]+:\s*$', caseSensitive: false))) {
        sections.add({
          'title': AppStrings.isEnglish ? 'General Summary' : 'Genel Özet',
          'content': summaryContent,
        });
      }
    } else if (remainingText.trim().isNotEmpty) {
      // Kalan metni kontrol et - eğer sadece topic isimleri değilse ekle
      String remainingContent = remainingText.trim();
      remainingContent = remainingContent.replaceAll(RegExp(r'\[|\]'), '');
      // Topic isimleri pattern'ini kontrol et
      if (remainingContent.isNotEmpty && 
          remainingContent.length > 50 && // En az 50 karakter olsun (daha güvenli)
          !remainingContent.contains(RegExp(r'^[A-ZÇĞIİÖŞÜ]+:\s*[A-ZÇĞIİÖŞÜ]+:\s*$', caseSensitive: false)) &&
          // Topic isimlerini içermiyorsa
          !topicNames.any((topic) => remainingContent.toLowerCase().contains(topic.toLowerCase() + ':'))) {
        sections.add({
          'title': AppStrings.isEnglish ? 'General Summary' : 'Genel Özet',
          'content': remainingContent,
        });
      }
    }
    
    // Eğer hiç section bulunamadıysa, tüm metni göster
    if (sections.isEmpty) {
      sections.add({
        'title': '',
        'content': interpretation,
        'showAd': false,
      });
    }
    
    return sections;
  }

  Widget _buildTarotCardSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) ...[
          Text(
            title,
            style: AppTextStyles.headingSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
        ],
        SelectableText(
          content,
          style: AppTextStyles.fortuneResult.copyWith(
            color: Colors.white,
            height: 1.6,
          ),
          textAlign: TextAlign.justify,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCoffeeTopicSection(String title, String content) {
    // Köşeli parantezleri temizle
    String cleanedContent = content.replaceAll(RegExp(r'\[|\]'), '');
    String cleanedTitle = title.replaceAll(RegExp(r'\[|\]'), '');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (cleanedTitle.isNotEmpty) ...[
          Text(
            cleanedTitle,
            style: AppTextStyles.headingSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
        ],
        SelectableText(
          cleanedContent,
          style: AppTextStyles.fortuneResult.copyWith(
            color: Colors.white,
            height: 1.6,
          ),
          textAlign: TextAlign.justify,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildRatingSection() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    final textColor = isDark ? Colors.white : Colors.grey[900]!;
    final textSecondaryColor = isDark ? Colors.white70 : Colors.grey[700]!;
    final starColor = isDark ? Colors.white54 : Colors.grey[600]!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.karmaGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.karma.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.karma.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            AppStrings.rateFortune,
            style: AppTextStyles.headingSmall.copyWith(
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starValue = index + 1.0;
              return GestureDetector(
                onTap: () => _rateFortune(starValue),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    _rating >= starValue ? Icons.star : Icons.star_border,
                    color: _rating >= starValue ? AppColors.karma : starColor,
                    size: 32,
                  ),
                ),
              );
            }),
          ),
          if (_rating > 0) ...[
            const SizedBox(height: 8),
            Text(
              '${AppStrings.yourRating}: ${_rating.toInt()}/5',
              style: AppTextStyles.bodyMedium.copyWith(
                color: textSecondaryColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (widget.fortune.type == FortuneType.dream && !_isLocked) ...[
          MysticalButton.primary(
            text: 'Rüyamı çiz',
            icon: Icons.brush,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DreamDrawScreen(
                    initialPrompt: (widget.fortune.metadata['dreamText'] ?? widget.fortune.question ?? '').toString(),
                  ),
                ),
              );
            },
            width: double.infinity,
            size: MysticalButtonSize.large,
          ),
          const SizedBox(height: 16),
        ],
        if (!_isLocked) ...[
          Row(
            children: [
              Expanded(
                child: MysticalButton.secondary(
                  text: AppStrings.share,
                  icon: Icons.share,
                  onPressed: _shareFortune,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: MysticalButton.ghost(
                  text: AppStrings.newFortune,
                  icon: Icons.refresh,
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FortuneSelectionScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        MysticalButton.primary(
          text: AppStrings.backToHome,
          icon: Icons.home,
          onPressed: () {
            Navigator.popUntil(context, (route) => route.isFirst);
          },
          width: double.infinity,
          size: MysticalButtonSize.large,
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} ${AppStrings.minutesAgo}';
      }
      return '${difference.inHours} ${AppStrings.hoursAgo}';
    } else if (difference.inDays == 1) {
      return AppStrings.yesterday;
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${AppStrings.daysAgo}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  void dispose() {
    // Coffee fortunes artık PageView kullanmıyor
    _backgroundController.dispose();
    _contentController.dispose();
    _cardController.dispose();
    super.dispose();
  }
}