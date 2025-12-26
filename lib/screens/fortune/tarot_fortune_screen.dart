import 'dart:ui' as ui;
import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import 'fortune_result_screen.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/pricing_constants.dart';
import '../../core/models/fortune_model.dart' as fm;
import '../../core/models/fortune_type.dart';
import '../../core/services/fortune_service.dart';
import '../../core/services/ads_service.dart';
import '../../core/providers/user_provider.dart';
import '../../core/widgets/glassmorphism_components.dart';
import '../../core/widgets/mystical_loading.dart';
import '../../widgets/fortune/fortune_user_info_form.dart';
import '../../widgets/fortune/karma_cost_badge.dart';

class TarotFortuneScreen extends StatefulWidget {
  final String? question;

  const TarotFortuneScreen({Key? key, this.question}) : super(key: key);

  @override
  State<TarotFortuneScreen> createState() => _TarotFortuneScreenState();
}

class _TarotFortuneScreenState extends State<TarotFortuneScreen> with TickerProviderStateMixin {
  final FortuneService _fortuneService = FortuneService();
  final AdsService _ads = AdsService();

  int _currentStep = 0; // 0: Card Selection, 1: Info Form
  Map<String, dynamic> _formData = {};
  
  // Deck Data
  final List<Map<String, String>> _baseDeck = const [
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
     // Minors (Sample)
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

  late List<Map<String, String>> _deck;
  
  // Selection State
  final List<int?> _selectedSlots = [null, null, null]; // Stores indices of selected cards in _deck
  final Set<int> _selectedIndices = {}; // Indices in _deck that are currently selected/flying
  
  // Animations
  late AnimationController _pulseController;
  late AnimationController _floatController;
  final GlobalKey _slotsKey = GlobalKey();
  
  // Flying Animation Logic
  OverlayEntry? _overlayEntry;
  List<AnimationController> _flyControllers = [];

  @override
  void initState() {
    super.initState();
    _initializeDeck();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }
  
  void _initializeDeck() {
    // Replicate cards to make a fuller deck (78 cards ideally)
    final random = math.Random();
    List<Map<String, String>> fullDeck = [];
    while(fullDeck.length < 78) {
      fullDeck.addAll(_baseDeck);
    }
    fullDeck = fullDeck.take(78).toList();
    fullDeck.shuffle(random);
    
    // Add unique grid IDs
    for(int i=0; i<fullDeck.length; i++) {
        fullDeck[i] = Map.from(fullDeck[i]);
        fullDeck[i]['uniqueId'] = '${fullDeck[i]['id']}_$i';
    }
    _deck = fullDeck;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _floatController.dispose();
    for (var c in _flyControllers) c.dispose();
    _overlayEntry?.remove();
    super.dispose();
  }

  void _onCardTap(int index, GlobalKey cardKey) {
    if (_selectedIndices.contains(index)) return; // Already selected
    if (_selectedSlots.every((s) => s != null)) return; // Slots full
    
    // Haptic feedback
    HapticFeedback.lightImpact();

    // Find first empty slot
    int slotIndex = _selectedSlots.indexWhere((s) => s == null);
    if (slotIndex == -1) return;

    setState(() {
      _selectedIndices.add(index);
    });

    _animateCardToSlot(index, slotIndex, cardKey);
  }

  void _animateCardToSlot(int cardIndex, int slotIndex, GlobalKey cardKey) {
    // Get start position from cardRenderBox
    final RenderBox? cardRenderBox = cardKey.currentContext?.findRenderObject() as RenderBox?;
    if (cardRenderBox == null) return;
    final startPos = cardRenderBox.localToGlobal(Offset.zero);
    final cardSize = cardRenderBox.size;

    // Get target position
    final screenWidth = MediaQuery.of(context).size.width;
    final slotWidth = (screenWidth - 64) / 3;
    final slotY = MediaQuery.of(context).padding.top + 80 + 32;
    final slotX = 16.0 + (slotIndex * (slotWidth + 12));
    
    final targetPos = Offset(slotX + 16, slotY + 16);
    
    // Create overlay
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _flyControllers.add(controller);

    final animation = CurvedAnimation(parent: controller, curve: Curves.easeInOutCubic);
    
    final positionAnim = Tween<Offset>(begin: startPos, end: targetPos).animate(animation);
    final scaleAnim = Tween<double>(begin: 1.0, end: slotWidth / cardSize.width).animate(animation);
    final rotateAnim = Tween<double>(begin: 0, end: math.pi * 2).animate(animation);

    OverlayEntry? entry;
    
    Widget buildOverlay(BuildContext context) {
       return AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          return Positioned(
            left: positionAnim.value.dx,
            top: positionAnim.value.dy,
            child: Transform.rotate(
              angle: rotateAnim.value,
              child: SizedBox(
                width: cardSize.width * scaleAnim.value,
                height: cardSize.height * scaleAnim.value,
                child: _buildCardVisual(isFront: false), // Flying card is back side
              ),
            ),
          );
        },
      );
    }

    entry = OverlayEntry(builder: buildOverlay);

    Overlay.of(context).insert(entry);

    controller.forward().then((_) {
      entry?.remove();
      _flyControllers.remove(controller);
      controller.dispose();
      
      if (mounted) {
        setState(() {
          _selectedSlots[slotIndex] = cardIndex;
        });
      }
    });
  }
  
  void _removeCardFromSlot(int slotIndex) {
    final cardIndex = _selectedSlots[slotIndex];
    if (cardIndex != null) {
      setState(() {
        _selectedSlots[slotIndex] = null;
        _selectedIndices.remove(cardIndex);
      });
    }
  }

  Future<void> _generateFortune() async {
    if (!_selectedSlots.every((s) => s != null)) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final requiredKarma = PricingConstants.getFortuneCost('tarot');
    
    if (!kDebugMode) {
      if (!(userProvider.user?.canUseDailyFortune ?? false)) {
        if ((userProvider.user?.karma ?? 0) < requiredKarma) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${AppStrings.notEnoughKarma}. Gerekli: $requiredKarma karma'),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }
        
        final karmaSpent = await userProvider.spendKarma(
          requiredKarma,
          AppStrings.tarotFortune,
        );
        
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
    }

    try {
      MysticLoading.show(context);
      
      final selectedCardIds = _selectedSlots.map((idx) => _deck[idx!]['id']!).toList();

      final result = await _fortuneService.generateFortune(
        type: FortuneType.tarot,
        inputData: {
          'selectedCards': selectedCardIds,
          'spreadType': 'three_card',
          ..._formData,
        },
        question: _buildQuestionFromForm(),
      );

      final fm.FortuneModel adapted = fm.FortuneModel(
        id: result.id,
        userId: result.userId,
        type: fm.FortuneType.tarot,
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
        karmaUsed: kDebugMode ? 0 : requiredKarma,
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
        try { 
          ok = await loaded.future.timeout(const Duration(seconds: 2)); 
        } catch (e) {
          if (kDebugMode) debugPrint('Ad load timeout: $e');
        }
        if (ok) { await _ads.showInterstitialAd(); }
      } catch (e) {
        if (kDebugMode) debugPrint('Ad error: $e');
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FortuneResultScreen(fortune: adapted),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      await MysticLoading.hide(context);
      String errorMsg = AppStrings.fortuneCreationError;
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('socketexception') || errorStr.contains('failed host lookup')) {
        errorMsg = AppStrings.networkConnectionError;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: AppColors.error),
      );
    }
  }

  String? _buildQuestionFromForm() {
    final topic1 = _formData['topic1'];
    final topic2 = _formData['topic2'];
    final name = _formData['name'];
    final rel = _formData['relationshipStatus'];
    final job = _formData['jobStatus'];
    final isForSelf = _formData['isForSelf'] == true;
    
    final parts = <String>[];
    if (topic1 != null) parts.add('Konu 1: $topic1');
    if (topic2 != null) parts.add('Konu 2: $topic2');
    if (name != null && name.isNotEmpty) parts.add('İsim: $name');
    parts.add(isForSelf ? 'Kendim için' : 'Başkası için');
    if (rel != null) parts.add('İlişki: $rel');
    if (job != null) parts.add('Meslek: $job');
    
    if (parts.isEmpty) return null;
    return parts.join('. ');
  }

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      body: Stack(
        children: [
          // Reduced particle count for performance
          ...List.generate(8, (index) => _buildFloatingParticle(index)),
          
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _currentStep == 0 
                      ? _buildSelectionStep() 
                      : _buildInfoStep(),
                ),
                _buildGenerateBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSelectionStep() {
    return Column(
      children: [
        const SizedBox(height: 10),
        _buildHeroSection(),
        const SizedBox(height: 16),
        _buildSlotsSection(),
        const SizedBox(height: 10),
        Expanded(child: _buildDeckGrid()),
      ],
    );
  }

  Widget _buildHeroSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final glowIntensity = 0.3 + _pulseController.value * 0.2;
          return ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.08),
                      Colors.white.withOpacity(0.03),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.champagneGold.withOpacity(glowIntensity),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.champagneGold.withOpacity(glowIntensity * 0.2),
                      blurRadius: 20,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Animated Tarot Icon
                    AnimatedBuilder(
                      animation: _floatController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, math.sin(_floatController.value * math.pi) * 3),
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.champagneGold.withOpacity(0.4),
                                  AppColors.champagneGold.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.champagneGold.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(Icons.style, color: AppColors.champagneGold, size: 28),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.isEnglish ? 'Select Your Cards' : 'Kartlarını Seç',
                            style: TextStyle(
                              fontFamily: 'SF Pro Display',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.champagneGold,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppStrings.isEnglish
                                ? 'Choose 3 cards that call to you. Trust your intuition.'
                                : '3 kart seç, sezgilerine güven. Kartlar seninle konuşacak.',
                            style: TextStyle(
                              fontFamily: 'SF Pro Text',
                              fontSize: 13,
                              height: 1.4,
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: FortuneUserInfoForm(
        onChanged: (data) {
          setState(() => _formData = data);
        },
      ),
    );
  }

  Widget _buildFloatingParticle(int index) {
    final random = math.Random(index);
    final size = 2.0 + random.nextDouble() * 3;
    final left = random.nextDouble() * MediaQuery.of(context).size.width;
    final top = random.nextDouble() * MediaQuery.of(context).size.height;
    
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        final offset = math.sin((_floatController.value * math.pi * 2) + index) * 20;
        return Positioned(
          left: left,
          top: top + offset,
          child: RepaintBoundary(
            child: Opacity(
              opacity: 0.3 + (math.sin(_floatController.value + index) + 1) / 4,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.champagneGold,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.champagneGold.withOpacity(0.5),
                      blurRadius: 5,
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

  Widget _buildHeader() {
    return ClipRRect(
        child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
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
                onTap: () {
                  if (_currentStep == 1) {
                    setState(() => _currentStep = 0);
                  } else {
                    Navigator.pop(context);
                  }
                },
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
                      child: Icon(Icons.auto_awesome, color: AppColors.champagneGold, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.tarotFortune,
                            style: TextStyle(
                              fontFamily: 'SF Pro Display',
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.warmIvory,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            'Kartların Bilgeliği',
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
              
              const KarmaCostBadge(fortuneType: 'tarot'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlotsSection() {
    final selectedCount = _selectedSlots.where((s) => s != null).length;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        border: Border.symmetric(
          horizontal: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      child: Column(
        children: [
          Text(
            selectedCount == 3 ? 'Kartlar Seçildi' : '${3 - selectedCount} Kart Seçin',
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 16,
              color: AppColors.champagneGold,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) => _buildGlassSlot(index)),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassSlot(int index) {
    final cardIndex = _selectedSlots[index];
    final isFilled = cardIndex != null;
    final screenWidth = MediaQuery.of(context).size.width;
    final width = (screenWidth - 64) / 3;
    final height = width * 1.5;

    return GestureDetector(
      onTap: () {
        if (isFilled) _removeCardFromSlot(index);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        width: width,
        height: height,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
          child: isFilled
              ? _buildRevealedCard(_deck[cardIndex!], key: ValueKey('slot_$index'))
              : _buildEmptySlotVisual(width, height, key: ValueKey('empty_$index')),
        ),
      ),
    );
  }
  
  Widget _buildEmptySlotVisual(double width, double height, {Key? key}) {
    return AnimatedBuilder(
      key: key,
      animation: _pulseController,
      builder: (context, child) {
        final glow = 0.5 + (_pulseController.value * 0.5);
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.3 * glow),
              width: 1,
              style: BorderStyle.solid,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.05 * glow),
                Colors.transparent,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.champagneGold.withOpacity(0.1 * glow),
                blurRadius: 10 * glow,
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.add,
              color: Colors.white.withOpacity(0.3 * glow),
              size: 24,
            ),
          ),
        );
      },
    );
  }

  Widget _buildRevealedCard(Map<String, String> cardData, {Key? key}) {
    return Container(
      key: key,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            _buildCardVisual(cardData: cardData, isFront: true),
            
            // Selection overlay
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.champagneGold,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    AppColors.champagneGold.withOpacity(0.3),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeckGrid() {
    // Optimized Grid with lazy loading and repainting boundary
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 32 - 36) / 4;
    final cardHeight = cardWidth * 1.5;

    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 10, left: 16, right: 16, bottom: 100),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: cardWidth / cardHeight,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _deck.length,
      itemBuilder: (context, index) {
         final isSelected = _selectedIndices.contains(index);
         return RepaintBoundary( // Optimization
           child: AnimatedOpacity(
             duration: const Duration(milliseconds: 300),
             opacity: isSelected ? 0.0 : 1.0,
             child: GestureDetector(
               onTap: () {
                 final cardKey = GlobalKey();
               },
               child: Builder(
                builder: (context) {
                   return GestureDetector(
                     onTap: () {
                        final cardKey = GlobalKey(); 
                        _onCardTap(index, cardKey);
                     },
                     child: Container(
                       child: _buildCardVisuaWithKey(index, cardWidth), 
                     ),
                   );
                }
               ),
             ),
           ),
         );
      },
    );
  }

  Widget _buildCardVisuaWithKey(int index, double width) {
    // Helper to wrap visual with a key finder logic for tap
    return Builder(
      builder: (context) {
        return GestureDetector(
          onTap: () {
             final RenderBox box = context.findRenderObject() as RenderBox;
             _onCardTapFromBox(index, box);
          },
          child: SizedBox(
            width: width,
            height: width * 1.5,
            child: _buildCardVisual(isFront: false),
          ),
        );
      }
    );
  }

  void _onCardTapFromBox(int index, RenderBox cardRenderBox) {
    if (_selectedIndices.contains(index)) return; 
    if (_selectedSlots.every((s) => s != null)) return; 
    
    HapticFeedback.lightImpact();

    int slotIndex = _selectedSlots.indexWhere((s) => s == null);
    if (slotIndex == -1) return;

    setState(() {
      _selectedIndices.add(index);
    });

    _animateCardFromBox(index, slotIndex, cardRenderBox);
  }

  void _animateCardFromBox(int cardIndex, int slotIndex, RenderBox cardRenderBox) {
    final startPos = cardRenderBox.localToGlobal(Offset.zero);
    final cardSize = cardRenderBox.size;

    // Same logic as before
    final screenWidth = MediaQuery.of(context).size.width;
    final slotWidth = (screenWidth - 64) / 3;
    final slotY = MediaQuery.of(context).padding.top + 80 + 32;
    final slotX = 16.0 + (slotIndex * (slotWidth + 12));
    final targetPos = Offset(slotX + 16, slotY + 16);
    
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _flyControllers.add(controller);

    final animation = CurvedAnimation(parent: controller, curve: Curves.easeInOutCubic);
    
    final positionAnim = Tween<Offset>(begin: startPos, end: targetPos).animate(animation);
    final scaleAnim = Tween<double>(begin: 1.0, end: slotWidth / cardSize.width).animate(animation);
    final rotateAnim = Tween<double>(begin: 0, end: math.pi * 2).animate(animation);

    OverlayEntry? entry;
    
    Widget buildOverlay(BuildContext context) {
       return AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          return Positioned(
            left: positionAnim.value.dx,
            top: positionAnim.value.dy,
            child: Transform.rotate(
              angle: rotateAnim.value,
              child: SizedBox(
                width: cardSize.width * scaleAnim.value,
                height: cardSize.height * scaleAnim.value,
                child: _buildCardVisual(isFront: false),
              ),
            ),
          );
        },
      );
    }

    entry = OverlayEntry(builder: buildOverlay);
    Overlay.of(context).insert(entry);

    controller.forward().then((_) {
      entry?.remove();
      _flyControllers.remove(controller);
      controller.dispose();
      
      if (mounted) {
        setState(() {
          _selectedSlots[slotIndex] = cardIndex;
        });
      }
    });
  }

  Widget _buildCardVisual({Map<String, String>? cardData, bool isFront = false}) {
    if (isFront && cardData != null) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
          border: Border.all(color: AppColors.champagneGold, width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            cardData['asset']!,
            fit: BoxFit.cover,
            errorBuilder: (c, e, s) => Center(child: Icon(Icons.broken_image, size: 20)),
          ),
        ),
      );
    }

    // Premium Card Back Visual
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2C2C3E),
            const Color(0xFF1A1A2E),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 2, // Reduced blur for performance
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Simplified pattern
          Opacity(
            opacity: 0.1,
            child: Icon(Icons.star, color: Colors.white, size: 12),
          ),
          // Center Symbol
          Icon(Icons.auto_awesome, color: AppColors.champagneGold.withOpacity(0.5), size: 16),
        ],
      ),
    );
  }

  Widget _buildGenerateBar() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final requiredKarma = PricingConstants.getFortuneCost('tarot');
        final canUseFortune = kDebugMode || 
                             (userProvider.user?.canUseDailyFortune ?? false) || 
                             (userProvider.user?.karma ?? 0) >= requiredKarma;
        final isSelectionComplete = _selectedSlots.every((s) => s != null);
        
        return ClipRRect(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15), // Reduced blur
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.12),
                    Colors.white.withOpacity(0.06),
                  ],
                ),
                border: Border(
                  top: BorderSide(color: Colors.white.withOpacity(0.15), width: 0.5),
                ),
              ),
              child: Opacity(
                opacity: _currentStep == 1 || isSelectionComplete ? 1.0 : 0.5,
                child: GlassButton(
                  text: _currentStep == 0 
                      ? (isSelectionComplete ? AppStrings.continue_ : AppStrings.select3Cards)
                      : AppStrings.createFortune,
                  icon: _currentStep == 0 ? Icons.arrow_forward : Icons.auto_awesome,
                  onPressed: (_currentStep == 1 || isSelectionComplete) ? () {
                    if (_currentStep == 0) {
                      if (isSelectionComplete) {
                        setState(() => _currentStep = 1);
                      }
                    } else {
                      if (canUseFortune) {
                        _generateFortune();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${AppStrings.notEnoughKarma}. Gerekli: $requiredKarma karma'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  } : null,
                  width: double.infinity,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
