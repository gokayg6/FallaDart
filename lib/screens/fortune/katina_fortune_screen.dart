import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'fortune_result_screen.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/pricing_constants.dart';
import '../../core/models/fortune_model.dart' as fm;
import '../../core/models/fortune_type.dart';
import '../../core/services/fortune_service.dart';
import '../../core/widgets/mystical_loading.dart';
import '../../core/widgets/glassmorphism_components.dart';
import '../../core/services/ads_service.dart';
import '../../widgets/fortune/karma_cost_badge.dart';
import '../../core/providers/user_provider.dart';
import 'dart:async';

class KatinaFortuneScreen extends StatefulWidget {
  const KatinaFortuneScreen({Key? key}) : super(key: key);

  @override
  State<KatinaFortuneScreen> createState() => _KatinaFortuneScreenState();
}

class _KatinaFortuneScreenState extends State<KatinaFortuneScreen> {
  final FortuneService _fortuneService = FortuneService();
  final AdsService _ads = AdsService();
  String? _question;

  Future<void> _generate() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final requiredKarma = PricingConstants.getFortuneCost('katina');
    
    final canUseDaily = userProvider.user?.canUseDailyFortune ?? false;
    
    if (!canUseDaily) {
      final currentKarma = userProvider.user?.karma ?? 0;
      
      if (currentKarma < requiredKarma) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.notEnoughKarma}. Gerekli: $requiredKarma karma'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      
      final karmaSpent = await userProvider.spendKarma(requiredKarma, 'Katina Falı');
      
      if (!karmaSpent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.notEnoughKarma}. Gerekli: $requiredKarma karma'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }
    
    try {
      MysticLoading.show(context);
      final result = await _fortuneService.generateFortune(
        type: FortuneType.katina,
        inputData: const {},
        question: _question,
      );

      final fm.FortuneModel adapted = fm.FortuneModel(
        id: result.id,
        userId: result.userId,
        type: fm.FortuneType.katina,
        status: fm.FortuneStatus.completed,
        title: result.title,
        interpretation: result.interpretation,
        inputData: const {},
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
        karmaUsed: requiredKarma,
        isPremium: false,
      );

      if (!mounted) return;
      await MysticLoading.hide(context);

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
        MaterialPageRoute(builder: (context) => FortuneResultScreen(fortune: adapted)),
      );
    } catch (e) {
      await MysticLoading.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppStrings.katinaFortuneCreationError}: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      body: SafeArea(
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
                    _buildQuestionInput(),
                  ],
                ),
              ),
            ),
            _buildGenerateBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withOpacity(0.12),
                Colors.white.withOpacity(0.05),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: AppColors.champagneGold.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // Back button with glass effect
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.15),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    color: AppColors.warmIvory,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Title with icon
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.champagneGold.withOpacity(0.3),
                            AppColors.champagneGold.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Image.asset(
                        'assets/icons/katina.png',
                        width: 28,
                        height: 28,
                        fit: BoxFit.cover, 
                        errorBuilder: (_, __, ___) => const Text('🔮', style: TextStyle(fontSize: 22)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.katinaFortune,
                            style: TextStyle(
                              fontFamily: 'SF Pro Display',
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.warmIvory,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            'Kalbinin Sırları',
                            style: TextStyle(
                              fontFamily: 'SF Pro Text',
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.5),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const KarmaCostBadge(fortuneType: 'katina'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntroCard() {
    return GlassCard(
      child: Text(
        AppStrings.katinaFortuneDesc,
        style: PremiumTextStyles.body,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildQuestionInput() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.problemOptional, style: PremiumTextStyles.section),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: TextField(
                onChanged: (v) => setState(() => _question = v.trim().isEmpty ? null : v.trim()),
                style: TextStyle(color: AppColors.warmIvory, fontFamily: 'SF Pro Text'),
                decoration: InputDecoration(
                  hintText: AppStrings.exampleLoveLifeShort,
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.08),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.champagneGold, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                maxLines: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateBar() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final requiredKarma = PricingConstants.getFortuneCost('katina');
        final canUseFortune = (userProvider.user?.canUseDailyFortune ?? false) || 
                             (userProvider.user?.karma ?? 0) >= requiredKarma;
        
        return ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.08),
                    Colors.white.withOpacity(0.04),
                  ],
                ),
                border: Border(
                  top: BorderSide(color: Colors.white.withOpacity(0.15), width: 0.5),
                ),
              ),
              child: GlassButton(
                text: AppStrings.createFortune,
                icon: Icons.auto_awesome,
                onPressed: canUseFortune ? _generate : null,
                width: double.infinity,
              ),
            ),
          ),
        );
      },
    );
  }
}
