import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/providers/user_provider.dart';
import '../../core/providers/fortune_provider.dart';
import '../../core/providers/language_provider.dart';
import '../../providers/theme_provider.dart';
import '../../core/widgets/mystical_button.dart';
import '../../core/widgets/mystical_loading.dart';
import '../../core/widgets/zoom_blur_route.dart';
import '../../core/widgets/liquid_glass_navbar.dart';
import '../../core/services/ads_service.dart';
import '../../core/services/ai_service.dart';
import '../../core/constants/pricing_constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../fortune/fortune_selection_screen.dart';
import '../profile/profile_screen.dart';
import '../history/fortunes_history_screen.dart';
import '../premium/premium_screen.dart';
import '../fortune/coffee_fortune_screen.dart';

import '../social/love_compatibility_screen.dart';
import '../social/soulmate_analysis_screen.dart';
import '../other/biorhythm_screen.dart';
import '../social/live_chat_screen.dart';
import '../fortune/dream_interpretation_screen.dart';
import '../fortune/dream_draw_screen.dart';
import '../fortune/dream_dictionary_screen.dart';
import '../fortune/tarot_fortune_screen.dart';
import '../fortune/palm_fortune_screen.dart';
import '../premium/karma_purchase_screen.dart';
import '../fortune/katina_fortune_screen.dart';
import '../fortune/face_fortune_screen.dart';
import '../astrology/astrology_screen.dart';
import '../premium/spin_wheel_screen.dart';
import '../astrology/horoscope_detail_screen.dart';
import '../other/tests_screen.dart';
import '../other/aura_update_screen.dart';
import '../../core/services/quiz_test_service.dart';
import '../../core/models/quiz_test_model.dart';
import '../tests/general_test_screen.dart';
import '../social/social_screen.dart';
import '../../core/widgets/confetti_animation.dart';
import '../../core/services/firebase_service.dart';
import '../../core/models/love_candidate_model.dart';
import '../social/love_candidate_form_screen.dart';
import '../social/love_compatibility_result_screen.dart';
import '../social/love_candidates_screen.dart';
import '../../core/utils/helpers.dart';
// coins screen used in karma section navigation
// import removed: coins screen not used here

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with TickerProviderStateMixin, RouteAware {
  late AnimationController _backgroundController;
  late AnimationController _cardController;
  final AdsService _adsService = AdsService();
  final AIService _aiService = AIService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, String> _horoscopes = {};
  bool _loadingHoroscopes = false;
  String? _pendingHistoryFilter;
  
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  int _pendingRequestsCount = 0;
  StreamSubscription<QuerySnapshot>? _pendingRequestsSubscription;
  String? _lastLanguageCode;
  bool _showDailyReward = false;
  bool _showConfetti = false;
  final GlobalKey _backgroundKey = GlobalKey();
  int _currentStreak = 0;
  int _todayKarmaReward = 0;
  final FirebaseService _firebaseService = FirebaseService();
  List<String> _completedQuests = [];
  bool _loadingQuests = false;
  DateTime? _lastQuestLoadTime;
  List<LoveCandidateModel> _loveCandidates = [];
  bool _loadingLoveCandidates = false;
  bool _questsExpanded = true;
  
  bool get _isEnglish {
    try {
      final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
      return languageProvider.isEnglish;
    } catch (e) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadInitialData();
    _loadHoroscopes();
    _loadPendingRequestsCount();
    _startPendingRequestsListener();
    _loadLoveCandidates();
    // Initialize language code and check daily reward
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
      _lastLanguageCode = languageProvider.languageCode;
      // Check daily reward on page load
      await _checkDailyRewardAvailability();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check daily reward when dependencies change (e.g., user login)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDailyRewardAvailability();
      _loadQuests();
    });
  }

  Future<void> _loadQuests() async {
    if (_loadingQuests) return;
    setState(() => _loadingQuests = true);
    
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.user?.id;
      if (userId == null) {
        setState(() {
          _completedQuests = [];
          _loadingQuests = false;
        });
        return;
      }

      final completed = await _firebaseService.getCompletedQuests(userId);
      if (mounted) {
        setState(() {
          _completedQuests = completed;
          _loadingQuests = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _completedQuests = [];
          _loadingQuests = false;
        });
      }
    }
  }

  Future<void> _loadLoveCandidates() async {
    if (_loadingLoveCandidates) return;
    setState(() => _loadingLoveCandidates = true);
    
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.user?.id;
      if (userId == null) {
        setState(() {
          _loveCandidates = [];
          _loadingLoveCandidates = false;
        });
        return;
      }

      final candidates = await _firebaseService.getLoveCandidates(userId);
      if (mounted) {
        setState(() {
          _loveCandidates = candidates;
          _loadingLoveCandidates = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loveCandidates = [];
          _loadingLoveCandidates = false;
        });
      }
    }
  }

  void _initializeAnimations() {
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Removed repeat animation to prevent blinking
    _backgroundController.forward();
    _cardController.forward();
  }


  void _loadInitialData() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final fortuneProvider = Provider.of<FortuneProvider>(context, listen: false);
      
      // Check if daily reward is available
      await _checkDailyRewardAvailability();
      
      final uid = userProvider.user?.id;
      if (uid != null && uid.isNotEmpty) {
        fortuneProvider.loadUserFortunes(uid);
      }
      fortuneProvider.loadTarotCards();
      fortuneProvider.loadFortuneTellers();
    });
  }

  Future<void> _checkDailyRewardAvailability() async {
    if (!mounted) return;
    
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.user?.id;
      if (userId == null) {
        setState(() {
          _showDailyReward = false;
          _currentStreak = 0;
          _todayKarmaReward = 0;
        });
        return;
      }

      final hasLoggedToday = await _firebaseService.checkDailyLogin(userId);
      if (hasLoggedToday) {
        setState(() {
          _showDailyReward = false;
          _currentStreak = 0;
          _todayKarmaReward = 0;
        });
        return;
      }

      // Get streak and reward info
      // getLoginStreak returns the next streak if user hasn't logged in today
      // If last login was yesterday, it returns currentStreak + 1
      // If streak is broken, it returns 1
      // If never logged in, it returns 0
      final nextStreak = await _firebaseService.getLoginStreak(userId);
      
      // If nextStreak is 0, user has never logged in - show reward for day 1
      final streakDay = nextStreak > 0 ? nextStreak : 1;
      final reward = PricingConstants.getDailyLoginReward(streakDay);
      
      if (reward != null) {
        setState(() {
          _showDailyReward = true;
          // Display current streak (before claiming today's reward)
          _currentStreak = streakDay - 1;
          _todayKarmaReward = reward['karma'] as int;
        });
      } else {
        setState(() {
          _showDailyReward = false;
          _currentStreak = 0;
          _todayKarmaReward = 0;
        });
      }
    } catch (e) {
      setState(() {
        _showDailyReward = false;
        _currentStreak = 0;
        _todayKarmaReward = 0;
      });
    }
  }

  Future<void> _loadHoroscopes() async {
    if (_loadingHoroscopes) return;
    setState(() => _loadingHoroscopes = true);
    
    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final isEnglish = _isEnglish;
    
    final signs = ['Koç', 'Boğa', 'İkizler', 'Yengeç', 'Aslan', 'Başak', 'Terazi', 'Akrep', 'Yay', 'Oğlak', 'Kova', 'Balık'];
    final newHoroscopes = <String, String>{};
    
    try {
      // Single doc per day
      final docRef = _firestore.collection('horoscopes').doc(dateKey);
      final doc = await docRef.get();

      Map<String, dynamic> texts = {};
      Map<String, dynamic> shorts = {};

      if (doc.exists) {
        final data = doc.data() ?? {};
        final textKey = isEnglish ? 'texts_en' : 'texts';
        final shortKey = isEnglish ? 'shorts_en' : 'shorts';
        texts = Map<String, dynamic>.from(data[textKey] ?? {});
        shorts = Map<String, dynamic>.from(data[shortKey] ?? {});
      }

      for (final sign in signs) {
        String? shortVal = shorts[sign]?.toString();
        String? fullVal = texts[sign]?.toString();

        if (shortVal == null || shortVal.isEmpty) {
          // Need to generate or summarize
          if (fullVal == null || fullVal.isEmpty) {
            // AI'ya İngilizce isim gönder, ama cache anahtarı olarak Türkçe ismi kullan
            final aiSign = isEnglish ? _mapTurkishSignToEnglish(sign) : sign;
            fullVal = await _aiService.generateDailyHoroscope(
              zodiacSign: aiSign,
              date: today,
              english: isEnglish,
            );
          }
          shortVal = _summarizeShort(fullVal);
          texts[sign] = fullVal;
          shorts[sign] = shortVal;
        }
        newHoroscopes[sign] = shortVal;
      }

      final textKey = isEnglish ? 'texts_en' : 'texts';
      final shortKey = isEnglish ? 'shorts_en' : 'shorts';
      await docRef.set({
        'date': dateKey,
        textKey: texts,
        shortKey: shorts,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      for (final sign in signs) {
        newHoroscopes[sign] = _getDefaultHoroscope(sign);
      }
    }
    
    if (mounted) {
      setState(() {
        _horoscopes = newHoroscopes;
        _loadingHoroscopes = false;
      });
    }
  }
  
  String _summarizeShort(String text) {
    var t = text.trim();
    // Remove persona intro if present
    final introIdx = t.toLowerCase().indexOf('merhaba, ben falla');
    if (introIdx == 0) {
      // Drop first sentence
      final dot = t.indexOf('.');
      if (dot != -1 && dot + 1 < t.length) t = t.substring(dot + 1).trim();
    }
    // Take first sentence up to 90 chars
    final endIdx = t.indexOf('.') != -1 ? t.indexOf('.') + 1 : (t.length);
    var s = t.substring(0, endIdx).trim();
    if (s.length > 90) s = s.substring(0, 90).trimRight() + '…';
    return s;
  }

  String _mapTurkishSignToEnglish(String sign) {
    switch (sign) {
      case 'Koç':
        return 'Aries';
      case 'Boğa':
        return 'Taurus';
      case 'İkizler':
        return 'Gemini';
      case 'Yengeç':
        return 'Cancer';
      case 'Aslan':
        return 'Leo';
      case 'Başak':
        return 'Virgo';
      case 'Terazi':
        return 'Libra';
      case 'Akrep':
        return 'Scorpio';
      case 'Yay':
        return 'Sagittarius';
      case 'Oğlak':
        return 'Capricorn';
      case 'Kova':
        return 'Aquarius';
      case 'Balık':
        return 'Pisces';
      default:
        return sign;
    }
  }

  String _getDefaultHoroscope(String sign) {
    if (_isEnglish) {
      final defaults = {
        'Aries': 'An energetic and courageous day.',
        'Taurus': 'Stay balanced, be patient.',
        'Gemini': 'Social relationships are in the foreground.',
        'Cancer': 'Listen to your emotions.',
        'Leo': 'Time to show yourself.',
        'Virgo': 'Pay attention to details.',
        'Libra': 'Harmony and balance are in the foreground.',
        'Scorpio': 'Deep feelings and intuition.',
        'Sagittarius': 'Adventure awaits you.',
        'Capricorn': 'Focus on your goals.',
        'Aquarius': 'Be open to innovations.',
        'Pisces': 'Use your imagination.',
      };
      return defaults[sign] ?? AppStrings.starsSpeakingToday;
    } else {
    final defaults = {
      'Koç': 'Enerjik ve cesur bir gün.',
      'Boğa': 'Dengede kal, sabırlı ol.',
      'İkizler': 'Sosyal ilişkiler önde.',
      'Yengeç': 'Duygularına kulak ver.',
      'Aslan': 'Kendini gösterme zamanı.',
      'Başak': 'Detaylara dikkat et.',
      'Terazi': 'Uyum ve denge ön planda.',
      'Akrep': 'Derin hisler ve sezgi.',
      'Yay': 'Macera seni bekliyor.',
      'Oğlak': 'Hedeflerine odaklan.',
      'Kova': 'Yeniliklere açık ol.',
      'Balık': 'Hayal gücünü kullan.',
    };
      return defaults[sign] ?? AppStrings.starsSpeakingToday;
    }
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          extendBody: true, // Required for transparent navbar effects
          body: RepaintBoundary(
            key: _backgroundKey,
            child: Stack(
              children: [
                Container(
            decoration: BoxDecoration(
              gradient: themeProvider.backgroundGradient,
            ),
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _selectedIndex = index;
            });
                    // Reload quests when returning to home tab
                    if (index == 0) {
                      _loadQuests();
                    }
          },
          children: [
            _buildHomeTab(),
            _buildFortunesHistoryTab(),
            const TestsScreen(),
            const SocialScreen(),
            const ProfileScreen(),
          ],
        ),
              ),
              if (_showConfetti)
                ConfettiAnimation(
                  onComplete: () {
                    setState(() {
                      _showConfetti = false;
                    });
                  },
                ),

                // Navbar is now part of the body stack to support Positioned widget
                _buildBottomNavigationBar(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHomeTab() {
    // Reload quests when home tab is built (user might have completed a quest)
    // But only if it's been more than 2 seconds since last load to avoid excessive calls
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedIndex == 0) {
        final now = DateTime.now();
        if (_lastQuestLoadTime == null || 
            now.difference(_lastQuestLoadTime!).inSeconds > 2) {
          _lastQuestLoadTime = now;
          _loadQuests();
        }
      }
    });
    
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            if (_showDailyReward) ...[
              _buildDailyRewardCard(),
              const SizedBox(height: 16),
            ],
            _buildQuestsCard(),
            const SizedBox(height: 16),
            _buildWelcomeCard(),
            const SizedBox(height: 24),
            _FalGridHome(),
            const SizedBox(height: 12),
            _showResultsCard(),
          const SizedBox(height: 24),
          _buildHoroscopeSection(),
            const SizedBox(height: 32),
            _buildLoveCompatibilitySection(),
            const SizedBox(height: 32),
            _buildTestsSection(),
            const SizedBox(height: 32),
            _buildDreamSection(),
            const SizedBox(height: 32),
            _buildBiorhythmSection(),
            const SizedBox(height: 32),
            _buildKarmaSection(),
            const SizedBox(height: 32),
            _buildOtherFeatures(),
            const SizedBox(height: 100), // Bottom padding for navigation
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer2<UserProvider, ThemeProvider>(
      builder: (context, userProvider, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        final textColor = isDark ? Colors.white : Colors.grey[900]!;
        final textSecondaryColor = isDark ? Colors.white70 : Colors.grey[700]!;
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
              children: [
                Image.asset(
                  'assets/icons/premium_logo.png',
                  height: 85,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
                const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        userProvider.user?.name ?? AppStrings.welcome,
                        style: AppTextStyles.headingLarge.copyWith(
                          color: textColor,
                        ),
                        maxLines: 1,
                      ),
                    ),
                const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        userProvider.user?.name != null 
                            ? AppStrings.welcomeBack 
                            : AppStrings.guest,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: textSecondaryColor,
                        ),
                        maxLines: 1,
                      ),
                    ),
                  ],
                    ),
                ),
              ],
            ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
              children: [
                  Flexible(
                    child: _buildKarmaDisplay(userProvider.user?.karma ?? 0),
                  ),
                  const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PremiumScreen(),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.diamond,
                    color: AppColors.premium,
                    size: 28,
                  ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                ),
              ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, [Color? textColor, Color? textSecondaryColor]) {
    final primaryColor = textColor ?? Colors.white;
    final secondaryColor = textSecondaryColor ?? Colors.white70;
    
    return Row(
      children: [
        Text(
          '• $label: ',
          style: AppTextStyles.bodySmall.copyWith(
            color: secondaryColor,
          ),
        ),
        Expanded(
          child: Text(
          value,
          style: AppTextStyles.bodySmall.copyWith(
            color: primaryColor,
            fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildKarmaDisplay(int karma) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const KarmaPurchaseScreen(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: AppColors.karmaGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.karma.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
              height: 24,
              width: 24,
            child: Image.asset('assets/karma/karma.png', fit: BoxFit.contain),
          ),
          const SizedBox(width: 4),
            Flexible(
              child: Text(
            karma.toString(),
                style: AppTextStyles.karmaDisplay.copyWith(fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildDailyRewardCard() {
    if (!_showDailyReward) {
      return const SizedBox.shrink();
    }

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
                AppColors.primary.withValues(alpha: 0.2),
                AppColors.accent.withValues(alpha: 0.15),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.dailyAuraReward,
                          style: AppTextStyles.headingMedium.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Bugün +$_todayKarmaReward karma seni bekliyor. Serini bozmamak için hemen al!',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: textSecondaryColor,
                          ),
                        ),
                        if (_currentStreak > 0) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.error.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: AppColors.error,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    AppStrings.streakWillReset.replaceAll('{0}', '$_currentStreak'),
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppColors.karmaGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '🔥',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          AppStrings.dayStreak.replaceAll('{0}', '$_currentStreak'),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: MysticalButton.primary(
                  text: AppStrings.claimMyReward,
                  onPressed: _claimDailyReward,
                  icon: Icons.card_giftcard,
                  showGlow: true,
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  Future<void> _claimDailyReward() async {
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

      final hasLoggedToday = await _firebaseService.checkDailyLogin(userId);
      if (hasLoggedToday) {
        setState(() => _showDailyReward = false);
        return;
      }

      // Record login and update streak
      await _firebaseService.recordDailyLogin(userId);
      final currentStreak = await _firebaseService.getLoginStreak(userId);
      final newStreak = currentStreak + 1;
      await _firebaseService.updateLoginStreak(userId, newStreak);

      // Get reward
      final reward = PricingConstants.getDailyLoginReward(newStreak);
      if (reward != null) {
        final karmaAmount = reward['karma'] as int;
        await userProvider.addKarma(
          karmaAmount,
          'Günlük giriş ödülü (Gün $newStreak)',
        );

        // Show confetti and hide card
        if (mounted) {
          setState(() {
            _showConfetti = true;
            _showDailyReward = false;
          });
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

  Widget _buildQuestsCard() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        
        // Masterpiece Colors
        final cardBg = isDark 
            ? const Color(0xFF151520).withValues(alpha: 0.6) 
            : const Color(0xFFFFFFF).withValues(alpha: 0.65);
            
        final borderColor = isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.05);

        final allQuests = PricingConstants.dailyQuests;
        final completedCount = _completedQuests.length;
        final totalQuests = allQuests.length;
        final allCompleted = completedCount == totalQuests;

        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderColor, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black.withValues(alpha: 0.4) : const Color(0xFF6366F1).withValues(alpha: 0.08),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                    spreadRadius: -5,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  InkWell(
                    onTap: () {
                      setState(() {
                         _questsExpanded = !_questsExpanded;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF6366F1).withValues(alpha: 0.2) : const Color(0xFF6366F1).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.verified_user_outlined,
                              size: 20,
                              color: isDark ? const Color(0xFFA5A6F6) : const Color(0xFF6366F1),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStrings.todaysQuests,
                                  style: AppTextStyles.headingSmall.copyWith(
                                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5,
                                    fontSize: 17,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  allCompleted 
                                    ? "Tüm görevler tamamlandı!" 
                                    : "${totalQuests - completedCount} görev seni bekliyor",
                                  style: TextStyle(
                                    color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.5),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AnimatedRotation(
                            turns: _questsExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutBack,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                              ),
                              child: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: isDark ? Colors.white70 : Colors.black54,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Divider
                  if (_questsExpanded)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Divider(height: 1, color: borderColor),
                    ),

                  // Content
                  AnimatedSize(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic, // Daha akıcı, titreşimsiz curve
                    alignment: Alignment.topCenter, // Yukarıdan aşağı düzgün açılma
                    child: _questsExpanded
                        ? Padding(
                            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20), // Top padding removed to prevent jump
                            child: Column(
                              children: [
                                const SizedBox(height: 10), // Add spacing here instead
                                ...allQuests.map((quest) {
                                  final questId = quest['id'] as String;
                                  final isCompleted = _completedQuests.contains(questId);
                                  
                                  // Get icon asset path
                                  String iconAsset;
                                  switch (questId) {
                                    case 'coffee_fortune':
                                      iconAsset = 'assets/quest_icons/coffee.png';
                                      break;
                                    case 'love_test':
                                      iconAsset = 'assets/quest_icons/love.png';
                                      break;
                                    case 'aura_match':
                                      iconAsset = 'assets/quest_icons/aura.png';
                                      break;
                                    default:
                                      iconAsset = 'assets/quest_icons/coffee.png';
                                  }

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isCompleted
                                          ? (isDark ? const Color(0xFF6366F1).withValues(alpha: 0.15) : const Color(0xFF6366F1).withValues(alpha: 0.08))
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isCompleted
                                            ? (isDark ? const Color(0xFF6366F1).withValues(alpha: 0.3) : const Color(0xFF6366F1).withValues(alpha: 0.2))
                                            : Colors.transparent,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Image.asset(
                                          iconAsset,
                                          width: 40,
                                          height: 40,
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Text(
                                              // Mapping logic duplicated here for safety or use helper
                                              questId == 'coffee_fortune' ? AppStrings.questCoffeeFortuneTitle :
                                              questId == 'love_test' ? AppStrings.questLoveTestTitle :
                                              questId == 'aura_match' ? AppStrings.questAuraMatchTitle : '',
                                            style: TextStyle(
                                              fontWeight: isCompleted ? FontWeight.w600 : FontWeight.w500,
                                              decoration: isCompleted ? TextDecoration.lineThrough : null,
                                              decorationColor: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.4),
                                              color: isCompleted ? (isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.5)) : (isDark ? Colors.white : Colors.black87),
                                            ),
                                          ),
                                        ),
                                        if (isCompleted)
                                          const Icon(Icons.check_circle, color: Color(0xFF6366F1), size: 24)
                                        else
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
                                              borderRadius: BorderRadius.circular(20),
                                              boxShadow: [
                                                BoxShadow(color: const Color(0xFFF59E0B).withValues(alpha: 0.4), blurRadius: 6, offset: const Offset(0, 2))
                                              ]
                                            ),
                                            child: Text(
                                              "+${quest['karma']}",
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeCard() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        
        // Masterpiece Daily Fortune Colors
        // Dark: Mystic Deep Blue/Purple gradient
        // Light: Soft Ethereal Pink/Gold
        
        final gradientColors = isDark 
            ? [const Color(0xFF2A2A72), const Color(0xFF009FFD)] // Dark space vibe
            : [const Color(0xFFFFF0F5), const Color(0xFFE6E6FA)]; // Light fairy vibe

        final shadowColor = isDark 
            ? const Color(0xFF009FFD).withValues(alpha: 0.25)
            : const Color(0xFFE6E6FA).withValues(alpha: 0.3);

        return ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              // 1. Background with blur
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark 
                        ? [Colors.black.withValues(alpha: 0.6), Colors.black.withValues(alpha: 0.4)]
                        : [Colors.white.withValues(alpha: 0.8), Colors.white.withValues(alpha: 0.6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              
              // 2. Artistic Mesh Gradients / Glows (Orb effects)
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? const Color(0xFF9D4EDD).withValues(alpha: 0.3) : const Color(0xFFFFD700).withValues(alpha: 0.2),
                    boxShadow: [
                      BoxShadow(color: isDark ? const Color(0xFF9D4EDD).withValues(alpha: 0.4) : const Color(0xFFFFD700).withValues(alpha: 0.3), blurRadius: 40, spreadRadius: 10)
                    ]
                  ),
                ),
              ),
              
              // 3. Main Content
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.5),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ]
                ),
                child: Column(
                  children: [
                    // Floating Icon with Glow
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.9),
                        boxShadow: [
                          BoxShadow(
                            color: isDark ? const Color(0xFF009FFD).withValues(alpha: 0.4) : const Color(0xFFFFD700).withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          )
                        ]
                      ),
                      child: Image.asset(
                        'assets/quest_icons/aura.png', // Kesin çalışan path
                        width: 48,
                        height: 48,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Icon(
                           Icons.auto_awesome, 
                           size: 40,
                           color: isDark ? const Color(0xFF009FFD) : const Color(0xFFFFD700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Titles
                    Text(
                      AppStrings.dailyFortune,
                      style: AppTextStyles.headingMedium.copyWith(
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        fontSize: 26,
                        shadows: isDark ? [
                          BoxShadow(color: Colors.white.withValues(alpha: 0.2), blurRadius: 10)
                        ] : null,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.dailyFortuneDesc,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isDark ? Colors.white70 : const Color(0xFF64748B),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    
                    // Cinematic Button
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: isDark 
                              ? [const Color(0xFF4338CA), const Color(0xFF6366F1)] // Indigo gradient
                              : [const Color(0xFF1E293B), const Color(0xFF334155)], // Slate gradient
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark ? const Color(0xFF4338CA).withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                            spreadRadius: -2,
                          )
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                             Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const FortuneSelectionScreen(),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  AppStrings.startFortune.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                              ],
                            ),
                          ),
                        ),
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

  // Removed legacy fortune types section
  // Widget _buildFortuneTypes() {}

  // Removed legacy fortune type card



  Widget _buildDreamSection() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        final textColor = AppColors.getTextPrimary(isDark);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.dreamArea,
              style: AppTextStyles.headingMedium.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildDreamCard(
                    title: AppStrings.isEnglish ? 'Dream Dictionary' : 'Rüya Sözlüğü',
                    icon: Icons.menu_book_rounded,
                    gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFDB931)]), // Gold
                    iconColor: const Color(0xFFFDB931),
                    isDark: isDark,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const DreamDictionaryScreen()));
                    },
                    delay: 0,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDreamCard(
                    title: AppStrings.drawMyDream,
                    icon: Icons.brush_rounded,
                    gradient: const LinearGradient(colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)]), // Purple
                    iconColor: const Color(0xFF8E2DE2),
                    isDark: isDark,
                    onTap: () {
                       Navigator.push(context, MaterialPageRoute(builder: (context) => const DreamDrawScreen()));
                    },
                    delay: 1,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDreamCard(
                    title: AppStrings.interpretDream,
                    icon: Icons.auto_awesome_rounded,
                    gradient: const LinearGradient(colors: [Color(0xFF11998E), Color(0xFF38EF7D)]), // Emerald
                    iconColor: const Color(0xFF11998E),
                    isDark: isDark,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const DreamInterpretationScreen()));
                    },
                    delay: 2,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
  Widget _buildDreamCard({
    required String title,
    required IconData icon,
    required Gradient gradient,
    required Color iconColor,
    required bool isDark,
    required VoidCallback onTap,
    required int delay,
  }) {
    // 0xFF1E1B2E is a deep mystic purple/black color
    final baseColor = iconColor; 
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          // Glass Background with Full Atmosphere
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                // Color spread everywhere
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark 
                      ? [
                          baseColor.withValues(alpha: 0.2), 
                          Colors.black.withValues(alpha: 0.6)
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.4),
                          baseColor.withValues(alpha: 0.2)
                        ],
                ),
                border: Border.all(
                  color: isDark 
                      ? baseColor.withValues(alpha: 0.2) 
                      : Colors.white.withValues(alpha: 0.6),
                  width: 1.5,
                ),
              ),
            ),
          ),
          
          // No explicit "orb" 

          // Content
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              splashColor: baseColor.withValues(alpha: 0.3),
              highlightColor: baseColor.withValues(alpha: 0.15),
              child: Container(
                padding: const EdgeInsets.all(16),
                height: 140,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.5),
                        boxShadow: [
                           BoxShadow(
                             color: baseColor.withValues(alpha: 0.3),
                             blurRadius: 15,
                             spreadRadius: 2,
                           )
                        ]
                      ),
                      child: Icon(icon, color: iconColor, size: 28),
                    ),
                    const Spacer(),
                    Text(
                      title,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }


  String _getZodiacSignName(String signCode) {
    if (!_isEnglish) return signCode;
    final lower = signCode.toLowerCase();
    if (lower.contains('koç') || lower.contains('koc')) return AppStrings.aries;
    if (lower.contains('boğa') || lower.contains('boga')) return AppStrings.taurus;
    if (lower.contains('ikiz')) return AppStrings.gemini;
    if (lower.contains('yengeç') || lower.contains('yengec')) return AppStrings.cancer;
    if (lower.contains('aslan')) return AppStrings.leo;
    if (lower.contains('başak') || lower.contains('basak')) return AppStrings.virgo;
    if (lower.contains('terazi')) return AppStrings.libra;
    if (lower.contains('akrep')) return AppStrings.scorpio;
    if (lower.contains('yay')) return AppStrings.sagittarius;
    if (lower.contains('oğlak') || lower.contains('oglak')) return AppStrings.capricorn;
    if (lower.contains('kova')) return AppStrings.aquarius;
    if (lower.contains('balık') || lower.contains('balik')) return AppStrings.pisces;
    return signCode;
  }

  Widget _buildGlassActionChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    color.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.4),
                  ]
                : [
                    Colors.white.withValues(alpha: 0.6),
                    color.withValues(alpha: 0.1),
                  ],
          ),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.15),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.grey[900],
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoveCompatibilitySection() {
    return Consumer2<ThemeProvider, UserProvider>(
      builder: (context, themeProvider, userProvider, child) {
        final isDark = themeProvider.isDarkMode;
        final textColor = isDark ? Colors.white : Colors.grey[900]!;
        final textSecondaryColor = isDark ? Colors.white70 : Colors.grey[700]!;
        
        // Base Color for Love Section (Pink/Rose)
        final baseColor = const Color(0xFFE91E63);
        
        if (_loadingLoveCandidates) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: baseColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Center(
              child: MysticalLoading(
                type: MysticalLoadingType.spinner,
                size: 32,
                color: baseColor,
              ),
            ),
          );
        }
        
        final hasCandidates = _loveCandidates.isNotEmpty;
        final firstCandidate = hasCandidates ? _loveCandidates.first : null;
        
        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Atmospheric Glass Background
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark 
                          ? [
                              baseColor.withValues(alpha: 0.25),
                              Colors.black.withValues(alpha: 0.6),
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.8),
                              baseColor.withValues(alpha: 0.15),
                            ],
                    ),
                    border: Border.all(
                      color: isDark 
                          ? baseColor.withValues(alpha: 0.2) 
                          : Colors.white.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: baseColor.withValues(alpha: 0.15),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Floating Glass Icon Container
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  baseColor.withValues(alpha: 0.3),
                                  baseColor.withValues(alpha: 0.1),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: baseColor.withValues(alpha: 0.3),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: baseColor.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.favorite_rounded,
                              color: isDark ? const Color(0xFFFF80AB) : baseColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStrings.loveCompatibility,
                                  style: AppTextStyles.headingSmall.copyWith(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  AppStrings.calculateHarmony,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: textSecondaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      if (hasCandidates && firstCandidate != null) ...[
                        // Premium Glass Candidate Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark 
                                ? Colors.black.withValues(alpha: 0.3) 
                                : Colors.white.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: baseColor.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: baseColor.withValues(alpha: 0.2),
                                child: Text(
                                  firstCandidate.name[0].toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 20, 
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? const Color(0xFFFF80AB) : baseColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      firstCandidate.name,
                                      style: AppTextStyles.bodyLarge.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                    Text(
                                      _getZodiacSignName(firstCandidate.zodiacSign),
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: textSecondaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (firstCandidate.lastCompatibilityScore != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    gradient: AppColors.karmaGradient,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.3),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    '${firstCandidate.lastCompatibilityScore!.toStringAsFixed(0)}%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ] else ...[
                        Text(
                          AppStrings.noLoveCandidate,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: textSecondaryColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildGlassActionChip(
                              context,
                              label: AppStrings.isEnglish ? 'Add New' : 'Yeni Ekle',
                              icon: Icons.add_rounded,
                              color: const Color(0xFFE91E63), // Pink
                              isDark: isDark,
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoveCandidateFormScreen(),
                                  ),
                                );
                                _loadLoveCandidates();
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildGlassActionChip(
                              context,
                              label: AppStrings.isEnglish ? 'Candidates' : 'Adaylar',
                              icon: Icons.favorite_border_rounded,
                              color: const Color(0xFF9C27B0), // Purple
                              isDark: isDark,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoveCandidatesScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Top Glint
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 1,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.white.withValues(alpha: 0.5), Colors.transparent],
                    )
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTestsSection() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        final textColor = AppColors.getTextPrimary(isDark);
        final textSecondaryColor = AppColors.getTextSecondary(isDark);
        
        final quizTestService = QuizTestService();
        final allTests = quizTestService.getAllTests();
        
        // Popüler testler (test ID'lerine göre - dil bağımsız)
        final popularTestIds = ['personality', 'friendship', 'love', 'compatibility', 'love_what_you_want'];
        final popularTests = allTests.where((test) => 
          popularTestIds.contains(test.id)
        ).toList();
        
        if (popularTests.isEmpty) {
          return const SizedBox.shrink();
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.tests,
                    style: AppTextStyles.headingMedium.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _onBottomNavTap(2); // Navigate to tests tab
                    },
                    child: Text(
                      AppStrings.seeAllTests,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: popularTests.length,
                itemBuilder: (context, index) {
                  final test = popularTests[index];
                  return _buildTestCard(test, isDark, textColor, textSecondaryColor);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  String? _getTestGifPath(QuizTestDefinition test) {
    switch (test.id) {
      case 'personality':
        return 'assets/gif/Popüler Testler/Kişilik Testi/kişiliktesti.gif';
      case 'friendship':
        return 'assets/gif/Popüler Testler/Arkadaşlık Testi/arkadaşlıktesti.gif';
      case 'love':
        return 'assets/gif/Popüler Testler/Aşk Testi/aşktesti.gif';
      case 'compatibility':
        return 'assets/gif/Popüler Testler/İlişki Uyum Testi/ilişkiuyumtesti.gif';
      case 'love_what_you_want':
        return 'assets/gif/Popüler Testler/İlişkinde Gerçekten Ne İstiyorsun/ilişkindegerçektenneistiyorsun.gif';
      default:
        return null;
    }
  }

  String _getLocalizedQuizTitle(QuizTestDefinition test) {
    if (!AppStrings.isEnglish) return test.title;
    final lower = test.title.toLowerCase();
    if (lower.contains('kişilik testi')) {
      return AppStrings.personalityTest;
    } else if (lower.contains('arkadaşlık testi')) {
      return AppStrings.friendshipTest;
    } else if (lower.contains('aşk testi')) {
      return AppStrings.loveTest;
    } else if (lower.contains('ilişkinde gerçekten ne istiyorsun')) {
      return AppStrings.relationshipWhatYouWantTest;
    }
    return test.title;
  }

  String _getLocalizedQuizSubtitle(QuizTestDefinition test) {
    if (!AppStrings.isEnglish) return test.description;
    switch (test.id) {
      case 'personality':
        return AppStrings.personalityTestSubtitle;
      case 'friendship':
        return AppStrings.friendshipTestSubtitle;
      case 'love':
        return AppStrings.loveTestSubtitle;
      case 'compatibility':
        return AppStrings.relationshipCompatibilitySubtitle;
      case 'love_what_you_want':
        return AppStrings.relationshipWhatYouWantSubtitle;
      default:
        return test.description;
    }
  }

  Widget _buildTestCard(
    QuizTestDefinition test,
    bool isDark,
    Color textColor,
    Color textSecondaryColor,
  ) {
    final gifPath = _getTestGifPath(test);
    
    // Dynamic Atmospheric Colors based on Test Type
    Color baseColor;
    if (test.id.contains('love')) {
      baseColor = const Color(0xFFE91E63); // Pink
    } else if (test.id.contains('personality')) {
      baseColor = const Color(0xFF9C27B0); // Purple
    } else if (test.id.contains('friend')) {
      baseColor = const Color(0xFFFF9800); // Orange
    } else {
      baseColor = const Color(0xFF2196F3); // Blue
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GeneralTestScreen(testDefinition: test),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12, bottom: 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Atmospheric Glass Background
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  height: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark 
                          ? [
                              baseColor.withValues(alpha: 0.25),
                              Colors.black.withValues(alpha: 0.6),
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.8),
                              baseColor.withValues(alpha: 0.15),
                            ],
                    ),
                    border: Border.all(
                      color: isDark 
                          ? baseColor.withValues(alpha: 0.2) 
                          : Colors.white.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: baseColor.withValues(alpha: 0.15),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      if (gifPath != null)
                        Expanded(
                          flex: 3,
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.4),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Image.asset(
                              gifPath,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const SizedBox(),
                            ),
                          ),
                        ),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _getLocalizedQuizTitle(test),
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getLocalizedQuizSubtitle(test),
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: textSecondaryColor,
                                  fontSize: 10,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Subtle Glow Overlay
              Positioned(
                 top: 0,
                 right: 0,
                 child: Container(
                   width: 50,
                   height: 50,
                   decoration: BoxDecoration(
                     shape: BoxShape.circle,
                     gradient: RadialGradient(
                       colors: [
                         baseColor.withValues(alpha: 0.4),
                         Colors.transparent,
                       ],
                     ),
                   ),
                 ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBiorhythmSection() {
    return Consumer2<UserProvider, ThemeProvider>(
      builder: (context, userProvider, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        final textColor = isDark ? Colors.white : Colors.grey[900]!;
        final textSecondaryColor = isDark ? Colors.white70 : Colors.grey[700]!;
        
        // Base Color for Biorhythm (Teal)
        final baseColor = const Color(0xFF009688);
        
        final user = userProvider.user;
        final birthDate = user?.birthDate;
        
        // Calculate biorhythm scores
        Map<String, double> biorhythmScores = {};
        if (birthDate != null) {
          final daysSinceBirth = DateTime.now().difference(birthDate).inDays.toDouble();
          final physical = math.sin(2 * math.pi * daysSinceBirth / 23);
          final emotional = math.sin(2 * math.pi * daysSinceBirth / 28);
          final mental = math.sin(2 * math.pi * daysSinceBirth / 33);
          
          // Convert -1..1 to 0..100
          biorhythmScores = {
            'physical': ((physical + 1) / 2 * 100).clamp(0, 100),
            'emotional': ((emotional + 1) / 2 * 100).clamp(0, 100),
            'mental': ((mental + 1) / 2 * 100).clamp(0, 100),
          };
        }
        
        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Atmospheric Glass Background
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark 
                          ? [
                              baseColor.withValues(alpha: 0.25),
                              Colors.black.withValues(alpha: 0.6),
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.8),
                              baseColor.withValues(alpha: 0.15),
                            ],
                    ),
                    border: Border.all(
                      color: isDark 
                          ? baseColor.withValues(alpha: 0.2) 
                          : Colors.white.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: baseColor.withValues(alpha: 0.15),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Floating Glass Icon Container
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  baseColor.withValues(alpha: 0.3),
                                  baseColor.withValues(alpha: 0.1),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(
                                color: baseColor.withValues(alpha: 0.3),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: baseColor.withValues(alpha: 0.2),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                )
                              ]
                            ),
                            child: Icon(
                              Icons.auto_graph_rounded,
                              color: isDark ? const Color(0xFF80CBC4) : baseColor, // Light Teal in dark mode
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStrings.biorhythm,
                                  style: AppTextStyles.headingSmall.copyWith(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  AppStrings.isEnglish
                                      ? 'Discover your daily energy cycles'
                                      : 'Günlük enerji döngülerini keşfet',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: textSecondaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      if (birthDate == null) ...[
                        // Set Birthday Button (Glass Chip style)
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context, 
                                MaterialPageRoute(builder: (context) => const ProfileScreen()),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  colors: [
                                    baseColor.withValues(alpha: 0.3),
                                    baseColor.withValues(alpha: 0.1),
                                  ],
                                ),
                                border: Border.all(
                                  color: baseColor.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                AppStrings.isEnglish ? 'Set Birth Date' : 'Doğum Tarihi Ayarla',
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        // Modern Glass Progress Bars
                        _buildGlassBiorhythmBar(
                          AppStrings.isEnglish ? 'Physical' : 'Fiziksel',
                          biorhythmScores['physical'] ?? 50,
                          const Color(0xFFE57373), // Red/Pink
                          isDark,
                        ),
                        const SizedBox(height: 16),
                        _buildGlassBiorhythmBar(
                          AppStrings.isEnglish ? 'Emotional' : 'Duygusal',
                          biorhythmScores['emotional'] ?? 50,
                          const Color(0xFF64B5F6), // Blue
                          isDark,
                        ),
                        const SizedBox(height: 16),
                        _buildGlassBiorhythmBar(
                          AppStrings.isEnglish ? 'Mental' : 'Zihinsel',
                          biorhythmScores['mental'] ?? 50,
                          const Color(0xFF81C784), // Green
                          isDark,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Subtle Top Gradient Overlay
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        baseColor.withValues(alpha: 0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGlassBiorhythmBar(String label, double value, Color color, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.grey[800],
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            Text(
              '${value.toInt()}%',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Glass Track
        Container(
          height: 8,
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value / 100,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.6),
                    color,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  )
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }




  Widget _buildKarmaSection() {
    return Consumer2<UserProvider, ThemeProvider>(
      builder: (context, userProvider, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        final textColor = isDark ? Colors.white : Colors.grey[900]!;
        final textSecondaryColor = isDark ? Colors.white70 : Colors.grey[700]!;
        
        // Base Color for Karma (Amber/Gold)
        final baseColor = const Color(0xFFFFC107);
        
        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Atmospheric Glass Background
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark 
                          ? [
                              baseColor.withValues(alpha: 0.15),
                              Colors.black.withValues(alpha: 0.6),
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.8),
                              baseColor.withValues(alpha: 0.1),
                            ],
                    ),
                    border: Border.all(
                      color: isDark 
                          ? baseColor.withValues(alpha: 0.2) 
                          : Colors.white.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: baseColor.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 90,
                        width: 90,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: baseColor.withValues(alpha: 0.3),
                                blurRadius: 30,
                                spreadRadius: -5,
                              )
                            ]
                          ),
                          child: Image.asset('assets/karma/karma.png', fit: BoxFit.contain),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppStrings.karmaSystem,
                        style: AppTextStyles.headingSmall.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: baseColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: baseColor.withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '${AppStrings.currentKarma}: ${userProvider.user?.karma ?? 0}',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: isDark ? Colors.amber[200] : Colors.amber[900],
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppStrings.karmaDesc,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: textSecondaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      
                      // Glass Info Container
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark 
                              ? Colors.black.withValues(alpha: 0.2) 
                              : Colors.white.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: baseColor.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.play_circle_filled_rounded,
                                  size: 20,
                                  color: baseColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  AppStrings.watchAdsToEarn,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: textColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(AppStrings.perVideo, '3 ${AppStrings.karma}', textColor, textSecondaryColor),
                            const SizedBox(height: 8),
                            _buildInfoRow(AppStrings.dailyLimit, '5 ${_isEnglish ? 'videos' : 'video'} (${_isEnglish ? 'total' : 'toplam'} 15 ${AppStrings.karma})', textColor, textSecondaryColor),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      Column(
                        children: [
                          _buildGlassActionChip(
                            context,
                            label: AppStrings.buyKarma,
                            icon: Icons.shopping_bag_outlined,
                            color: Colors.amber,
                            isDark: isDark,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const KarmaPurchaseScreen(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildGlassActionChip(
                            context,
                            label: AppStrings.earnKarma,
                            icon: Icons.play_arrow_rounded,
                            color: Colors.orange,
                            isDark: isDark,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const KarmaPurchaseScreen(
                                    initialTab: 1, // Kazan sekmesi
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Top Glint
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 1,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.white.withValues(alpha: 0.5), Colors.transparent],
                    )
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOtherFeatures() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        final textColor = isDark ? Colors.white : Colors.grey[900]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  AppStrings.otherFeatures,
                  style: AppTextStyles.headingMedium.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: [
                _buildGlassFeatureCard(
                  title: AppStrings.loveTest,
                  icon: Icons.favorite_rounded,
                  color: const Color(0xFFE91E63), // Pink
                  gradient: AppColors.loveGradient,
                  isDark: isDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoveCompatibilityScreen(),
                      ),
                    );
                  },
                ),
                _buildGlassFeatureCard(
                  title: AppStrings.auraMatch,
                  icon: Icons.auto_awesome_rounded,
                  color: const Color(0xFF9C27B0), // Purple
                  gradient: AppColors.personalityGradient,
                  isDark: isDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SoulmateAnalysisScreen(),
                      ),
                    );
                  },
                ),
                _buildGlassFeatureCard(
                  title: AppStrings.dreamInterpretation,
                  icon: Icons.bedtime_rounded,
                  color: const Color(0xFF673AB7), // Deep Purple
                  gradient: const LinearGradient(colors: [Color(0xFF673AB7), Color(0xFF512DA8)]),
                  isDark: isDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DreamInterpretationScreen(),
                      ),
                    );
                  },
                ),

                _buildGlassFeatureCard(
                  title: AppStrings.palmFortune,
                  icon: Icons.pan_tool_rounded,
                  color: const Color(0xFFFF9800), // Orange
                  gradient: const LinearGradient(colors: [Color(0xFFFF9800), Color(0xFFF57C00)]),
                  isDark: isDark,
                  onTap: () {
                     Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PalmFortuneScreen(),
                      ),
                    );
                  },
                ),
                _buildGlassFeatureCard(
                  title: AppStrings.tarot,
                  icon: Icons.style_rounded,
                  color: const Color(0xFF3F51B5), // Indigo
                  gradient: const LinearGradient(colors: [Color(0xFF3F51B5), Color(0xFF303F9F)]),
                  isDark: isDark,
                  onTap: () {
                    _onBottomNavTap(1); 
                  },
                ),
                _buildGlassFeatureCard(
                  title: AppStrings.auraAnalysis,
                  icon: Icons.auto_awesome_rounded,
                  color: const Color(0xFF9C27B0), // Purple
                  gradient: const LinearGradient(colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)]),
                  isDark: isDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AuraUpdateScreen(),
                      ),
                    );
                  },
                ),
                _buildGlassFeatureCard(
                  title: AppStrings.spinWheel,
                  icon: Icons.casino_rounded,
                  color: const Color(0xFF673AB7), // Deep Purple
                  gradient: const LinearGradient(colors: [Color(0xFF673AB7), Color(0xFF512DA8)]),
                  isDark: isDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SpinWheelScreen(),
                      ),
                    );
                  },
                ),
                _buildGlassFeatureCard(
                  title: AppStrings.liveChat,
                  icon: Icons.chat_bubble_rounded,
                  color: const Color(0xFFFFC107), // Amber
                  gradient: const LinearGradient(colors: [Color(0xFFFFCA28), Color(0xFFFFA000)]),
                  isDark: isDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LiveChatScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildGlassFeatureCard({
    required String title,
    required IconData icon,
    required Color color,
    required Gradient gradient,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24), // Increased radius for smoother feel
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    color.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.5),
                  ]
                : [
                    Colors.white.withValues(alpha: 0.9),
                    color.withValues(alpha: 0.1),
                  ],
          ),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1.5, // Slightly thicker border
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2), // Depth shadow
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Increased blur
            child: Stack(
              alignment: Alignment.center, // CRITICAL: Centers everything
              children: [
                // Top Gloss
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 40,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center, // CRITICAL
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Floating Glass Icon
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: gradient,
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.5),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                              spreadRadius: 1,
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: 30, // Slightly larger icon
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      
                      // Text
                      Text(
                        title,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.grey[900],
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          letterSpacing: 0.3,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildHoroscopeSection() {
    return Consumer2<ThemeProvider, LanguageProvider>(
      builder: (context, themeProvider, languageProvider, child) {
        final isDark = themeProvider.isDarkMode;
        final textColor = isDark ? Colors.white : Colors.grey[900]!;
        final textSecondaryColor = isDark ? Colors.white60 : Colors.grey[600]!;
        
        // Reload horoscopes when language changes
        final currentLanguageCode = languageProvider.languageCode;
        if (_lastLanguageCode != null && _lastLanguageCode != currentLanguageCode) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _loadHoroscopes();
            }
          });
        }
        _lastLanguageCode = currentLanguageCode;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.dailyHoroscope,
              style: AppTextStyles.headingMedium.copyWith(color: textColor),
            ),
            const SizedBox(height: 6),
            Text(
              AppStrings.aiUpdatedDaily,
              style: AppTextStyles.bodySmall.copyWith(color: textSecondaryColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        const SizedBox(height: 10),
        SizedBox(
          height: 122,
          child: _loadingHoroscopes
              ? Center(
                  child: MysticalLoading(
                    type: MysticalLoadingType.spinner,
                    size: 24,
                    color: textColor,
                  ),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _zodiacList.length,
                  separatorBuilder: (ctx, i) => const SizedBox(width: 10),
                  itemBuilder: (ctx, i) {
                    final z = _zodiacList[i];
                    final desc = _horoscopes[z['name']] ?? _getDefaultHoroscope(z['name']!);
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HoroscopeDetailScreen(
                              zodiacName: z['name']!,
                              emoji: z['emoji'] ?? '',
                            ),
                          ),
                        );
                      },
                      child: _zodiacCard(z, desc, isDark),
                    );
                  },
                ),
        ),
      ],
    );
      },
    );
  }

  Widget _zodiacCard(Map<String, String> zodiac, String description, [bool isDark = true]) {
    // Helper to get asset
    String _zodiacAssetForName(String name) {
      final lower = name.toLowerCase()
          .replaceAll('ı', 'i')
          .replaceAll('ş', 's')
          .replaceAll('ğ', 'g')
          .replaceAll('ç', 'c')
          .replaceAll('ö', 'o')
          .replaceAll('ü', 'u');
      if (lower.contains('koc')) return 'assets/burclar/koc.png';
      if (lower.contains('boga')) return 'assets/burclar/boga.png';
      if (lower.contains('ikiz')) return 'assets/burclar/ikizler.png';
      if (lower.contains('yengec')) return 'assets/burclar/yengec.png';
      if (lower.contains('aslan')) return 'assets/burclar/aslan.png';
      if (lower.contains('basak')) return 'assets/burclar/basak.png';
      if (lower.contains('terazi')) return 'assets/burclar/terazi.png';
      if (lower.contains('akrep')) return 'assets/burclar/akrep.png';
      if (lower.contains('yay')) return 'assets/burclar/yay.png';
      if (lower.contains('oglak')) return 'assets/burclar/oglak.png';
      if (lower.contains('kova')) return 'assets/burclar/kova.png';
      if (lower.contains('balik')) return 'assets/burclar/balik.png';
      return 'assets/icons/astrology.png';
    }
    
    // Helper for localized name
    String _localizedZodiacName(String name) {
       return _getZodiacSignName(name);
    }
    
    // Cosmic/Mystic Color Palette for Zodiacs
    final baseColor = isDark ? const Color(0xFF6C63FF) : const Color(0xFF5A4FCF);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          // Atmospheric Glass Background
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              width: 140,
              height: 180,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark 
                      ? [
                          const Color(0xFF2E1A47).withValues(alpha: 0.8), // Deep Cosmic Purple
                          const Color(0xFF4527A0).withValues(alpha: 0.6),
                        ]
                      : [
                          const Color(0xFFEDE7F6).withValues(alpha: 0.9), // Light Lavender
                          const Color(0xFFD1C4E9).withValues(alpha: 0.7),
                        ],
                ),
                border: Border.all(
                  color: isDark 
                      ? Colors.white.withValues(alpha: 0.1) 
                      : Colors.white.withValues(alpha: 0.6),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: baseColor.withValues(alpha: 0.15),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon
                  Image.asset(
                    _zodiacAssetForName(zodiac['name']!),
                    width: 48,
                    height: 48,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 12),
                  // Name
                  Text(
                    _localizedZodiacName(zodiac['name']!),
                    style: AppTextStyles.bodyMedium.copyWith(
                       color: isDark ? Colors.white : Colors.deepPurple[900],
                       fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  // Description / Horoscope Preview
                  Expanded(
                    child: Center(
                      child: Text(
                        description,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.deepPurple[700],
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          height: 1.2,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Subtle Top Gradient Overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 40,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    baseColor.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const List<Map<String, String>> _zodiacList = [
    // İsimler veri ve AI tarafında Türkçe kalıyor; ekranda gösterirken AppStrings ile çeviriyoruz
    {"name": "Koç", "emoji": "♈️", "desc": "Enerjik ve cesur bir gün."},
    {"name": "Boğa", "emoji": "♉️", "desc": "Dengede kal, sabırlı ol."},
    {"name": "İkizler", "emoji": "♊️", "desc": "Sosyal ilişkiler önde."},
    {"name": "Yengeç", "emoji": "♋️", "desc": "Duygularına kulak ver."},
    {"name": "Aslan", "emoji": "♌️", "desc": "Kendini gösterme zamanı."},
    {"name": "Başak", "emoji": "♍️", "desc": "Detaylara dikkat et."},
    {"name": "Terazi", "emoji": "♎️", "desc": "Uyum ve denge ön planda."},
    {"name": "Akrep", "emoji": "♏️", "desc": "Derin hisler ve sezgi."},
    {"name": "Yay", "emoji": "♐️", "desc": "Macera seni bekliyor."},
    {"name": "Oğlak", "emoji": "♑️", "desc": "Hedeflerine odaklan."},
    {"name": "Kova", "emoji": "♒️", "desc": "Yeniliklere açık ol."},
    {"name": "Balık", "emoji": "♓️", "desc": "Hayal gücünü kullan."},
  ];



  Widget _buildBottomNavigationBar() {
    return LiquidGlassNavbar(
      currentIndex: _selectedIndex,
      onTap: _onBottomNavTap,
      backgroundKey: _backgroundKey,
      items: [
        NavbarItem(
          icon: Icons.home_outlined,
          activeIcon: Icons.home,
          label: AppStrings.home,
        ),
        NavbarItem(
          icon: Icons.auto_awesome_outlined, 
          activeIcon: Icons.auto_awesome,
          label: AppStrings.fortunes,
        ),
        NavbarItem(
          icon: Icons.quiz_outlined,
          activeIcon: Icons.quiz,
          label: AppStrings.tests,
        ),
        NavbarItem(
          icon: Icons.people_outline,
          activeIcon: Icons.people,
          label: AppStrings.social,
        ),
        NavbarItem(
          icon: Icons.person_outline,
          activeIcon: Icons.person,
          label: AppStrings.profile,
        ),
      ],
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label, {bool showBadge = false, bool isDark = true}) {
    final isSelected = _selectedIndex == index;
    final color = isSelected ? AppColors.primary : (isDark ? AppColors.textSecondary : Colors.grey[600]!);
    
    return Expanded(
      child: GestureDetector(
        onTap: () => _onBottomNavTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  color: color,
                  size: 24,
                ),
                if (showBadge && _pendingRequestsCount > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isDark ? AppColors.surfaceColor : AppColors.lightSurface, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.6),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 16,
                      ),
                      child: Text(
                        _pendingRequestsCount > 99 ? '99+' : '$_pendingRequestsCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          height: 1.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: (isSelected ? AppTextStyles.navigationLabel : AppTextStyles.navigationLabel).copyWith(
                color: color,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadPendingRequestsCount() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      
      try {
        final currentUser = Provider.of<UserProvider>(context, listen: false).user;
        if (currentUser == null) {
          if (mounted) {
            setState(() {
              _pendingRequestsCount = 0;
            });
          }
          return;
        }

        final snapshot = await _firestore
            .collection('social_requests')
            .where('toUserId', isEqualTo: currentUser.id)
            .where('status', isEqualTo: 'pending')
            .get();

        final count = snapshot.docs.length;

        if (mounted) {
          setState(() {
            _pendingRequestsCount = count;
          });
        }
      } catch (e) {
        print('Error loading pending requests count: $e');
      }
    });
  }

  void _startPendingRequestsListener() {
    // Önceki subscription'ı iptal et
    _pendingRequestsSubscription?.cancel();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      final currentUser = Provider.of<UserProvider>(context, listen: false).user;
      if (currentUser == null) {
        if (mounted) {
          setState(() {
            _pendingRequestsCount = 0;
          });
        }
        return;
      }

      _pendingRequestsSubscription = _firestore
          .collection('social_requests')
          .where('toUserId', isEqualTo: currentUser.id)
          .where('status', isEqualTo: 'pending')
          .snapshots()
          .listen((snapshot) {
        if (!mounted) return;

        final count = snapshot.docs.length;

        if (mounted) {
          setState(() {
            _pendingRequestsCount = count;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _pendingRequestsSubscription?.cancel();
    _backgroundController.dispose();
    _cardController.dispose();
    _pageController.dispose();
    _adsService.disposeAllAds();
    super.dispose();
  }

  // HomeScreen'deki "Fallarımı Göster" kartı
  Widget _showResultsCard([String? fortuneTypeFilter]) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        // Deep Purple / Indigo Theme
        final baseColor = const Color(0xFF4A00E0);
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _pendingHistoryFilter = fortuneTypeFilter ?? 'all';
              _selectedIndex = 1;
            });
            _pageController.animateToPage(1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Atmospheric Glass Background
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark 
                            ? [
                                const Color(0xFF311B92).withValues(alpha: 0.85), // Deep Indigo
                                const Color(0xFF4A148C).withValues(alpha: 0.65), // Deep Purple
                              ]
                            : [
                                const Color(0xFF673AB7).withValues(alpha: 0.9), // Deep Purple
                                const Color(0xFF512DA8).withValues(alpha: 0.8), // Indigo
                              ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF311B92).withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            // Floating Glass Icon Container
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withValues(alpha: 0.2),
                                    const Color(0xFF4A00E0).withValues(alpha: 0.1),
                                  ],
                                ),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  )
                                ]
                              ),
                              child: const Icon(
                                Icons.history_edu_rounded, 
                                color: Colors.white, 
                                size: 28,
                                shadows: [
                                  Shadow(
                                    color: Colors.black38,
                                    blurRadius: 5,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStrings.showMyFortunes,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black26,
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  AppStrings.isEnglish ? 'View your past readings' : 'Geçmiş yorumlarını incele',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontWeight: FontWeight.w500,
                                    shadows: const [
                                      Shadow(
                                        color: Colors.black12,
                                        blurRadius: 2,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        
                        // Action Arrow
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_ios_rounded, 
                            color: Colors.white, 
                            size: 16
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Top Gloss Overlay
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 40,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.15),
                          Colors.transparent,
                        ],
                      ),
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

  // Rewarded Ad akışı

  Widget _buildFortunesHistoryTab() {
    // Bu fonksiyon _pendingHistoryFilter'i kullanarak sadece 1 kez dream filtresi ile açılmayı tetikler
    if (_pendingHistoryFilter != null) {
      final String filter = _pendingHistoryFilter!;
      // filter parametresini tek seferlik tüket
      _pendingHistoryFilter = null;
      return FortunesHistoryScreen(selectedFilter: filter);
    }
    return const FortunesHistoryScreen();
  }

}

// -------- HomeScreen'deki Fal Grid'in ana sayfa versiyonu --------
class _FalGridHome extends StatelessWidget {
  const _FalGridHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer2<LanguageProvider, ThemeProvider>(
      builder: (context, languageProvider, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        
        final items = [
          _FalItemHome(
            title: AppStrings.coffeeFortune,
            iconAsset: 'assets/icons/premium_coffee.png',
            color: const Color(0xFFD4A373), // Warm Coffee Color
            onTap: (ctx) => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const CoffeeFortuneScreen())),
          ),
          _FalItemHome(
            title: AppStrings.tarotFortune,
            iconAsset: 'assets/icons/premium_tarot.png',
            color: const Color(0xFF9D4EDD), // Mystic Purple
            onTap: (ctx) => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const TarotFortuneScreen())),
          ),
          _FalItemHome(
            title: AppStrings.palmFortune,
            iconAsset: 'assets/icons/premium_palm.png',
            color: const Color(0xFF2A9D8F), // Mystic Teal
            onTap: (ctx) => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const PalmFortuneScreen())),
          ),
          _FalItemHome(
            title: AppStrings.katinaFortune,
            iconAsset: 'assets/icons/premium_katina.png',
            color: const Color(0xFFE63946), // Deep Rose
            onTap: (ctx) => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const KatinaFortuneScreen())),
          ),
          _FalItemHome(
            title: AppStrings.faceFortune,
            iconAsset: 'assets/icons/premium_face.png',
            color: const Color(0xFFFFB703), // Golden Amber
            onTap: (ctx) => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const FaceFortuneScreen())),
          ),
          _FalItemHome(
            title: AppStrings.astrology,
            iconAsset: 'assets/icons/premium_astrology.png',
            color: const Color(0xFF4361EE), // Cosmic Blue
            onTap: (ctx) => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const AstrologyScreen())),
          ),
        ];

        return LayoutBuilder(
          builder: (ctx, c) {
            final cross = c.maxWidth >= 420 ? 3 : 2;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cross,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemBuilder: (ctx, i) {
                final it = items[i];
                final baseColor = it.color ?? Colors.grey;
                
                return ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Glassmorphism Background with Full Atmosphere
                      BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          decoration: BoxDecoration(
                            // The base color is now part of the background itself
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isDark 
                                  ? [
                                      baseColor.withValues(alpha: 0.25), 
                                      Colors.black.withValues(alpha: 0.6),
                                    ]
                                  : [
                                      Colors.white.withValues(alpha: 0.4),
                                      baseColor.withValues(alpha: 0.2),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isDark 
                                  ? baseColor.withValues(alpha: 0.2)
                                  : Colors.white.withValues(alpha: 0.5),
                              width: 1.5, // Slightly clearer border
                            ),
                          ),
                        ),
                      ),
                      
                      // No explicit "orb" or "corner glow" anymore. 
                      // The color is spread everywhere via the container gradient above.

                      // Content
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => it.onTap(ctx),
                          borderRadius: BorderRadius.circular(24),
                          splashColor: baseColor.withValues(alpha: 0.3),
                          highlightColor: baseColor.withValues(alpha: 0.15),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Icon Container
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    // More transparent background for icon to blend in
                                    color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: baseColor.withValues(alpha: 0.3),
                                        blurRadius: 15,
                                        spreadRadius: 2,
                                      )
                                    ]
                                  ),
                                  child: Image.asset(
                                    it.iconAsset,
                                    height: 55, // Slightly larger
                                    width: 55,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_,__,___) => Icon(Icons.star, color: baseColor, size: 30),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  it.title,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _FalItemHome {
  final String title;
  final String iconAsset;
  final Color? color;
  final Function(BuildContext) onTap;

  _FalItemHome({
    required this.title,
    required this.iconAsset,
    this.color,
    required this.onTap,
  });
}