import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'fortune_result_screen.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_strings.dart';
import '../../core/models/fortune_model.dart' as fm;
import '../../core/models/fortune_type.dart';
import '../../core/services/fortune_service.dart';
import '../../core/widgets/mystical_card.dart';
import '../../core/widgets/mystical_loading.dart';
import '../../core/services/ads_service.dart';
import '../../widgets/fortune/karma_cost_badge.dart';
import '../../providers/theme_provider.dart';
import '../../core/services/ai_service.dart';
import '../../core/providers/user_provider.dart';
import 'dart:async';

class DreamDictionaryScreen extends StatefulWidget {
  const DreamDictionaryScreen({Key? key}) : super(key: key);

  @override
  State<DreamDictionaryScreen> createState() => _DreamDictionaryScreenState();
}

class _DreamDictionaryScreenState extends State<DreamDictionaryScreen> {
  final FortuneService _fortuneService = FortuneService();
  final AIService _aiService = AIService();
  final AdsService _ads = AdsService();
  final TextEditingController _controller = TextEditingController();

  bool _canGenerate = false;

  Future<void> _generate() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    try {
      MysticLoading.show(context);
      
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;
      if (user == null) {
        await MysticLoading.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.isEnglish 
                ? 'Please log in to continue' 
                : 'Devam etmek için lütfen giriş yapın'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      // Generate dream symbol interpretation using AI
      final interpretation = await _aiService.generateDreamSymbolInterpretation(
        symbol: text,
        user: user,
        english: AppStrings.isEnglish,
      );

      // Create a fortune model for the result
      final result = await _fortuneService.generateFortune(
        type: FortuneType.dream,
        inputData: {
          'dreamSymbol': text,
          'isDictionary': true,
        },
      );

      final fm.FortuneModel adapted = fm.FortuneModel(
        id: result.id,
        userId: result.userId,
        type: fm.FortuneType.dream,
        status: fm.FortuneStatus.completed,
        title: AppStrings.isEnglish 
            ? 'Dream Symbol: $text'
            : 'Rüya Sembolü: $text',
        interpretation: interpretation,
        inputData: {
          'dreamSymbol': text,
          'isDictionary': true,
        },
        selectedCards: result.selectedCards,
        imageUrls: result.imageUrls,
        question: result.question,
        createdAt: result.createdAt,
        completedAt: result.createdAt,
        isFavorite: result.isFavorite,
        rating: result.rating.toInt(),
        notes: null,
        isForSelf: true,
        targetPersonName: null,
        metadata: result.metadata,
        karmaUsed: 0,
        isPremium: false,
      );

      if (!mounted) return;
      await MysticLoading.hide(context);

      // Show interstitial after generating
      try {
        final loaded = Completer<bool>();
        await _ads.createInterstitialAd(
          adUnitId: _ads.interstitialAdUnitId,
          onAdLoaded: (_) => loaded.complete(true),
          onAdFailedToLoad: (_) => loaded.complete(false),
        );
        bool ok = false;
        try { ok = await loaded.future.timeout(const Duration(seconds: 2)); } catch (_) {}
        if (ok) { await _ads.showInterstitialAd(); }
      } catch (_) {}

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FortuneResultScreen(fortune: adapted),
        ),
      );
    } catch (e) {
      await MysticLoading.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppStrings.fortuneCreationError}: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(gradient: themeProvider.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildIntroCard(),
                      const SizedBox(height: 16),
                      _buildInputCard(),
                    ],
                  ),
                ),
              ),
              _buildGenerateBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final textColor = AppColors.getTextPrimary(isDark);
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back, color: textColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppStrings.isEnglish ? 'Dream Dictionary' : 'Rüya Sözlüğü',
              style: AppTextStyles.headingLarge.copyWith(color: textColor),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          const KarmaCostBadge(fortuneType: 'dream'),
          const SizedBox(width: 8),
          const Text('📖', style: TextStyle(fontSize: 24)),
        ],
      ),
    );
  }

  Widget _buildIntroCard() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        final textColor = AppColors.getTextPrimary(isDark);
        final cardBg = AppColors.getCardBackground(isDark);
        
        return MysticalCard(
          showGlow: false,
          enforceAspectRatio: false,
          toggleFlipOnTap: false,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFFFD700).withValues(alpha: isDark ? 0.3 : 0.25),
                  cardBg.withValues(alpha: isDark ? 0.9 : 0.85),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('📖', style: TextStyle(fontSize: 32)),
                const SizedBox(height: 12),
                Text(
                  AppStrings.isEnglish
                      ? 'Enter a dream symbol or word to discover its meaning'
                      : 'Rüya sembolü veya kelime girerek anlamını keşfet',
                  style: AppTextStyles.bodyMedium.copyWith(color: textColor),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputCard() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        final cardBg = AppColors.getCardBackground(isDark);
        
        return MysticalCard(
          showGlow: false,
          enforceAspectRatio: false,
          toggleFlipOnTap: false,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFFFD700).withValues(alpha: isDark ? 0.25 : 0.2),
                  cardBg.withValues(alpha: isDark ? 0.9 : 0.85),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                final isDark = themeProvider.isDarkMode;
                final textColor = AppColors.getTextPrimary(isDark);
                final inputTextColor = AppColors.getInputTextColor(isDark);
                final inputHintColor = AppColors.getInputHintColor(isDark);
                final inputBorderColor = AppColors.getInputBorderColor(isDark);
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.isEnglish ? 'Dream Symbol' : 'Rüya Sembolü',
                      style: AppTextStyles.headingSmall.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _controller,
                      onChanged: (v) => setState(() => _canGenerate = v.trim().isNotEmpty),
                      style: AppTextStyles.bodyMedium.copyWith(color: inputTextColor),
                      decoration: InputDecoration(
                        hintText: AppStrings.isEnglish 
                            ? 'e.g., snake, water, flying...'
                            : 'örn: yılan, su, uçmak...',
                        hintStyle: AppTextStyles.bodyMedium.copyWith(color: inputHintColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: inputBorderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: inputBorderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.secondary),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                        filled: true,
                        fillColor: isDark 
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.white.withValues(alpha: 0.3),
                      ),
                      keyboardType: TextInputType.text,
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildGenerateBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground.withValues(alpha: 0.3),
        border: const Border(top: BorderSide(color: Colors.white24, width: 1)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _canGenerate ? _generate : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            AppStrings.isEnglish 
                ? (_canGenerate ? 'Discover Meaning' : 'Enter a Symbol')
                : (_canGenerate ? 'Anlamını Keşfet' : 'Sembol Gir'),
            style: AppTextStyles.buttonLarge.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

