import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_strings.dart';
import '../../core/models/quiz_test_model.dart';
import '../../core/widgets/mystical_button.dart';
import '../../core/services/ads_service.dart';
import '../../providers/theme_provider.dart';
import '../../core/utils/helpers.dart';

class TestResultScreen extends StatefulWidget {
  final QuizTestResult result;
  
  const TestResultScreen({
    Key? key,
    required this.result,
  }) : super(key: key);

  @override
  State<TestResultScreen> createState() => _TestResultScreenState();
}

class _TestResultScreenState extends State<TestResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _contentController;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _contentAnimation;
  
  bool _isFavorite = false;
  bool _isLoading = false;
  final AdsService _ads = AdsService();
  DateTime? _availableAt;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadAvailability();
    _startCountdownTimer();
    // Reklam izleyerek açılma - fal sonucu gibi
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showInterstitialAd();
    });
  }

  Future<void> _showInterstitialAd() async {
    try {
      final loaded = Completer<bool>();
      await _ads.createInterstitialAd(
        adUnitId: _ads.interstitialAdUnitId,
        onAdLoaded: (_) => loaded.complete(true),
        onAdFailedToLoad: (_) => loaded.complete(false),
      );
      bool ok = false;
      try { ok = await loaded.future.timeout(const Duration(seconds: 2)); } catch (_) {}
      if (ok && mounted) {
        await _ads.showInterstitialAd();
      }
    } catch (_) {
      // Reklam yüklenemezse sessizce devam et
    }
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_isLocked) {
        setState(() {});
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _backgroundController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _loadAvailability() {
    try {
      // Check if result has metadata with availableAt
      // If not, create a wait time like fortune results (15-25 min)
      if (widget.result.id.isNotEmpty) {
        // Try to load from Firestore
        FirebaseFirestore.instance
            .collection('quiz_test_results')
            .doc(widget.result.id)
            .get()
            .then((doc) {
          if (doc.exists) {
            final data = doc.data() ?? {};
            final metadata = data['metadata'] as Map<String, dynamic>? ?? {};
            final raw = metadata['availableAt'];
            
            if (raw != null) {
              if (raw is String && raw.isNotEmpty) {
                setState(() {
                  _availableAt = DateTime.tryParse(raw);
                });
              } else if (raw is Timestamp) {
                setState(() {
                  _availableAt = raw.toDate();
                });
              }
            } else {
              // Create initial wait time if not exists
              final waitMinutes = 15 + (DateTime.now().millisecond % 11);
              final newAvailableAt = DateTime.now().add(Duration(minutes: waitMinutes));
              setState(() {
                _availableAt = newAvailableAt;
              });
              // Save to Firestore
              FirebaseFirestore.instance
                  .collection('quiz_test_results')
                  .doc(widget.result.id)
                  .update({
                'metadata.availableAt': newAvailableAt.toIso8601String(),
              });
            }
          } else {
            // Create initial wait time
            final waitMinutes = 15 + (DateTime.now().millisecond % 11);
            final newAvailableAt = DateTime.now().add(Duration(minutes: waitMinutes));
            setState(() {
              _availableAt = newAvailableAt;
            });
          }
        });
      } else {
        // No ID, create wait time locally
        final waitMinutes = 15 + (DateTime.now().millisecond % 11);
        setState(() {
          _availableAt = DateTime.now().add(Duration(minutes: waitMinutes));
        });
      }
    } catch (_) {
      // On error, create wait time locally
      final waitMinutes = 15 + (DateTime.now().millisecond % 11);
      setState(() {
        _availableAt = DateTime.now().add(Duration(minutes: waitMinutes));
      });
    }
  }

  bool get _isLocked {
    if (_availableAt == null) return false;
    return DateTime.now().isBefore(_availableAt!);
  }

  Future<void> _speedUp5Min() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Load rewarded and wait until ready (2s timeout)
      final loaded = Completer<bool>();
      await _ads.createRewardedAd(
        adUnitId: _ads.rewardedAdUnitId,
        onAdLoaded: (_) => loaded.complete(true),
        onAdFailedToLoad: (_) => loaded.complete(false),
      );
      bool ok = false;
      try { ok = await loaded.future.timeout(const Duration(seconds: 2)); } catch (_) {}
      
      if (ok) {
        // Show rewarded ad and wait for reward
        final reward = await _ads.showRewardedAd();
        
        // Only update if user actually watched the ad (reward is not null)
        if (reward != null && mounted) {
          final newAvailableAt = (_availableAt ?? DateTime.now()).subtract(const Duration(minutes: 5));
          
          // Eğer zaman 0 veya negatif olduysa, hemen açılabilir hale getir
          final finalAvailableAt = newAvailableAt.isBefore(DateTime.now()) 
              ? DateTime.now().subtract(const Duration(seconds: 1))
              : newAvailableAt;
          
          setState(() {
            _availableAt = finalAvailableAt;
            _isLoading = false;
          });
          
          // Countdown timer'ı yeniden başlat
          _startCountdownTimer();
          
          if (widget.result.id.isNotEmpty) {
            await FirebaseFirestore.instance
                .collection('quiz_test_results')
                .doc(widget.result.id)
                .update({
              'metadata.availableAt': finalAvailableAt.toIso8601String(),
            });
          }
        } else if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
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

  void _initializeAnimations() {
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _backgroundController,
        curve: Curves.easeInOut,
      ),
    );

    _contentAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: Curves.easeOutBack,
      ),
    );

    // Blinking animation disabled
    // _backgroundController.repeat(reverse: true);
    _contentController.forward();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      final hours = difference.inHours;
      if (hours == 0) {
        final minutes = difference.inMinutes;
        return '$minutes ${AppStrings.minutesAgo}';
      }
      return '$hours ${AppStrings.hoursAgo}';
    } else if (difference.inDays == 1) {
      return AppStrings.yesterday;
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${AppStrings.daysAgoShort}';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${AppStrings.weeksAgo}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _shareResult() async {
    // Sonuç gelmeden paylaş butonu görünmemeli, ama yine de kontrol edelim
    if (_isLocked) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.testResultPreparing),
            backgroundColor: AppColors.warning,
          ),
        );
      }
      return;
    }

    try {
      final text = '''
${widget.result.emoji} ${widget.result.testTitle}

${widget.result.resultText}

${AppStrings.testDate} ${_formatDate(widget.result.createdAt)}

#Falla #TestSonucu #${widget.result.testTitle.replaceAll(' ', '')}
''';
      await Share.share(text);
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

  Future<void> _copyToClipboard() async {
    // Sonuç gelmeden kopyala butonu görünmemeli, ama yine de kontrol edelim
    if (_isLocked) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.testResultPreparing),
            backgroundColor: AppColors.warning,
          ),
        );
      }
      return;
    }

    try {
      final text = '''
${widget.result.emoji} ${widget.result.testTitle}

${widget.result.resultText}

${AppStrings.testDate} ${_formatDate(widget.result.createdAt)}
''';
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.resultCopiedToClipboard),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.copyError} $e'),
            backgroundColor: AppColors.error,
          ),
        );
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
              Expanded(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      if (_isLocked) _buildLockedCard() else _buildResultCard(),
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

  Widget _buildAppBar() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final textColor = AppColors.getTextPrimary(isDark);
    final iconColor = AppColors.getIconColor(isDark);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: iconColor),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              AppStrings.testResult,
              style: AppTextStyles.headingMedium.copyWith(
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? AppColors.error : iconColor,
            ),
            onPressed: () {
              setState(() {
                _isFavorite = !_isFavorite;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _contentAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _contentAnimation.value.clamp(0.0, 1.0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.8),
                  AppColors.primary.withValues(alpha: 0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.result.emoji,
                  style: const TextStyle(fontSize: 48),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.result.testTitle,
                  style: AppTextStyles.headingMedium.copyWith(
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.result.testDescription,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _formatDate(widget.result.createdAt),
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

  Widget _buildLockedCard() {
    final remaining = _availableAt != null 
        ? _availableAt!.difference(DateTime.now())
        : const Duration(minutes: 15);
    
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.cardBackground.withValues(alpha: 0.9),
            AppColors.cardBackground.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          const SizedBox(height: 20),
          Text(
            AppStrings.fortuneTellerLookingAtTest,
            style: AppTextStyles.headingMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.watchAdToSpeedUpFortuneTeller,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  AppStrings.remainingTime,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                  style: AppTextStyles.headingLarge.copyWith(
                    color: AppColors.primary,
                    fontSize: 36,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
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
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              AppStrings.speedUpFortuneTellerThinking,
                              style: AppTextStyles.buttonLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppStrings.watchAdToSpeedUp5Min,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
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
                AppColors.cardBackground.withValues(alpha: 0.9 + (_backgroundAnimation.value * 0.1)),
                AppColors.cardBackground.withValues(alpha: 0.8 + (_backgroundAnimation.value * 0.1)),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.psychology,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppStrings.analysisResult,
                      style: AppTextStyles.headingSmall.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  Helpers.cleanMarkdown(widget.result.resultText),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white,
                    height: 1.8,
                    fontSize: 16,
                  ),
                  softWrap: true,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    // Sonuç gelmeden butonlar görünmemeli
    if (_isLocked) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: MysticalButton.secondary(
                text: AppStrings.share,
                icon: Icons.share,
                onPressed: _shareResult,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MysticalButton.secondary(
                text: AppStrings.copy,
                icon: Icons.copy,
                onPressed: _copyToClipboard,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: MysticalButton.secondary(
                text: AppStrings.returnToTestsPage,
                icon: Icons.arrow_back,
                onPressed: () {
                  // Sadece geri git, navbar'ı koru
                  Navigator.of(context).pop();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MysticalButton.accent(
                text: AppStrings.newTest,
                icon: Icons.refresh,
                onPressed: () {
                  // Testler sayfasına git ama navbar'ı koru
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

