import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/models/fortune_model.dart';
import '../../core/services/firebase_service.dart';
import '../../core/providers/user_provider.dart';
import '../../providers/theme_provider.dart';
import '../../core/widgets/mystical_loading.dart';
import '../../core/services/ads_service.dart';
import '../fortune/fortune_result_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui'; // Added for Glassmorphism

class FortunesHistoryScreen extends StatefulWidget {
  final String? selectedFilter;
  const FortunesHistoryScreen({Key? key, this.selectedFilter}) : super(key: key);

  @override
  State<FortunesHistoryScreen> createState() => _FortunesHistoryScreenState();
}

class _FortunesHistoryScreenState extends State<FortunesHistoryScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late Animation<double> _backgroundAnimation;
  final AdsService _adsService = AdsService();
  
  String _selectedFilter = 'all';
  String _selectedSort = 'newest';
  List<Map<String, dynamic>> _dreamDraws = [];
  List<FortuneModel> _userFortunes = [];
  bool _loadingFortunes = false;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.selectedFilter ?? 'all';
    _initializeAnimations();
    _loadFortunes();
  }

  void _initializeAnimations() {
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));
    
    _loadDreamDraws();
  }

  Future<void> _loadDreamDraws() async {
    try {
      final userId = Provider.of<UserProvider>(context, listen: false).user?.id;
      if (userId != null) {
        final docs = await FirebaseService().getDreamDraws(userId);
        if (mounted) {
          setState(() {
        _dreamDraws = docs.map((d) => {'id': d.id, ...Map<String, dynamic>.from(d.data() as Map)}).toList();
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _loadFortunes() async {
    setState(() => _loadingFortunes = true);
    try {
      final userId = Provider.of<UserProvider>(context, listen: false).user?.id;
      if (userId != null) {
        final docs = await FirebaseService().getUserFortunesFromReadings(userId);
        final List<FortuneModel> fortunes = [];
        for (final doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          try {
            fortunes.add(FortuneModel(
              id: doc.id,
              userId: data['userId'] ?? '',
              type: FortuneType.values.firstWhere(
                (t) => t.name == (data['type'] ?? '').toString().toLowerCase(),
                orElse: () => FortuneType.tarot,
              ),
              status: FortuneStatus.values.firstWhere(
                (s) => s.name == (data['status'] ?? 'completed').toString().toLowerCase(),
                orElse: () => FortuneStatus.completed,
              ),
              title: data['title'] ?? '',
              interpretation: data['interpretation'] ?? '',
              inputData: Map<String, dynamic>.from(data['inputData'] ?? {}),
              selectedCards: List<String>.from(data['selectedCards'] ?? []),
              imageUrls: List<String>.from(data['imageUrls'] ?? []),
              question: data['question'],
              fortuneTellerId: data['fortuneTellerId'],
              createdAt: (data['createdAt'] is Timestamp)
                  ? (data['createdAt'] as Timestamp).toDate()
                  : DateTime.tryParse(data['createdAt']?.toString() ?? '') ?? DateTime.now(),
              completedAt: (data['completedAt'] is Timestamp)
                  ? (data['completedAt'] as Timestamp).toDate()
                  : DateTime.tryParse(data['completedAt']?.toString() ?? ''),
              isFavorite: data['isFavorite'] ?? false,
              rating: (data['rating'] ?? 0) is int ? data['rating'] : (int.tryParse(data['rating'].toString()) ?? 0),
              notes: data['notes'],
              isForSelf: data['isForSelf'] ?? true,
              targetPersonName: data['targetPersonName'],
              metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
              karmaUsed: data['karmaUsed'] ?? 0,
              isPremium: data['isPremium'] ?? false,
            ));
          } catch (_) {}
        }
        _userFortunes = fortunes;
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingFortunes = false);
  }

  Widget _getFortuneTypeIcon(String type) {
    String assetName;
    switch (type.toLowerCase()) {
      case 'tarot':
        assetName = 'assets/icons/premium_tarot.png';
        break;
      case 'coffee':
        assetName = 'assets/icons/premium_coffee.png';
        break;
      case 'palm':
        assetName = 'assets/icons/premium_palm.png';
        break;
      case 'astrology':
        assetName = 'assets/icons/premium_astrology.png';
        break;
      case 'face':
      case 'water':
        assetName = 'assets/icons/premium_face.png';
        break;
      case 'katina':
      case 'love':
        assetName = 'assets/icons/premium_katina.png';
        break;
      case 'dream':
        // Fallback or specific icon if available
        assetName = 'assets/icons/dream.png'; 
        break;
      default:
        assetName = 'assets/icons/premium_tarot.png';
    }
    
    return Image.asset(
      assetName,
      width: 40,
      height: 40,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const Text('🔮', style: TextStyle(fontSize: 32)),
    );
  }

  Color _getFortuneTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'tarot':
        return const Color(0xFF9D4EDD); // Mystic Purple
      case 'coffee':
        return const Color(0xFFD4A373); // Warm Coffee
      case 'palm':
        return const Color(0xFF2A9D8F); // Mystic Teal
      case 'astrology':
        return const Color(0xFF4361EE); // Cosmic Blue
      case 'dream':
        return const Color(0xFFF72585); // Vivid Pink
      case 'katina':
        return const Color(0xFFE63946); // Deep Rose
      case 'face':
        return const Color(0xFFFFB703); // Golden Amber
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        
        // iOS System Background Colors
        final backgroundColor = isDark 
            ? const Color(0xFF0F172A) 
            : const Color(0xFFF5F5F7); // iOS Light Gray
            
        return Scaffold(
          backgroundColor: backgroundColor,
          body: Stack(
            children: [
              // Subtle Ambient Orbs for Premium Feel
              if (isDark) ...[
                Positioned(
                  top: -100,
                  right: -100,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF4A00E0).withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -50,
                  left: -50,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFE91E63).withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                 // Light Mode Subtle Warmth
                 Positioned(
                  top: -100,
                  right: -50,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF6200EA).withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                ),
              ],

              SafeArea(
                child: Column(
                  children: [
                    _buildHeader(isDark),
                    _buildFilters(isDark),
                    Expanded(
                      child: _loadingFortunes
                          ? Center(
                              child: MysticalLoading(
                                type: MysticalLoadingType.cards,
                                message: AppStrings.isEnglish ? 'Loading...' : 'Fallar Yükleniyor...',
                              ),
                            )
                          : _buildCombinedAccordingToFilter(isDark),
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

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Text(
            AppStrings.fortunesHistory,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700, // Reduced bold for elegance
              color: isDark ? Colors.white : const Color(0xFF1C1C1E), // iOS Black
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_userFortunes.length + _dreamDraws.length} ${AppStrings.total}',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          // Type Filter
          SizedBox(
            height: 44, // Slightly smaller for elegance
            child: ListView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              children: [
                _buildElegantFilterChip('all', AppStrings.all, Icons.grid_view_rounded, isDark),
                _buildElegantFilterChip('tarot', AppStrings.tarot, Icons.auto_awesome, isDark),
                _buildElegantFilterChip('coffee', AppStrings.coffee, Icons.coffee, isDark),
                _buildElegantFilterChip('palm', AppStrings.palm, Icons.back_hand, isDark),
                _buildElegantFilterChip('astrology', AppStrings.astrology, Icons.star, isDark),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Sort Filter
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              children: [
                _buildElegantSortChip('newest', AppStrings.newest, Icons.schedule, isDark),
                _buildElegantSortChip('favorites', AppStrings.favorites, Icons.favorite_border, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildElegantFilterChip(String value, String label, IconData icon, bool isDark) {
    final isSelected = _selectedFilter == value;
    final activeColor = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final inactiveColor = isDark ? Colors.white54 : Colors.black54;
    
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilter = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected 
                ? (isDark ? Colors.white : Colors.black)
                : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? Colors.transparent : (isDark ? Colors.white10 : Colors.black12),
            ),
            boxShadow: isSelected 
                ? [
                    BoxShadow(
                      color: isDark ? Colors.white24 : Colors.black12,
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? (isDark ? Colors.black : Colors.white) : inactiveColor,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? (isDark ? Colors.black : Colors.white) : inactiveColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildElegantSortChip(String value, String label, IconData icon, bool isDark) {
    final isSelected = _selectedSort == value;
    final inactiveColor = isDark ? Colors.white60 : Colors.black54;
    
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () => setState(() => _selectedSort = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected 
                ? (isDark ? const Color(0xFF323232) : const Color(0xFFE5E5EA))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? (isDark ? Colors.white : Colors.black) : inactiveColor,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? (isDark ? Colors.white : Colors.black) : inactiveColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_edu_rounded,
            size: 64,
            color: isDark ? Colors.white24 : Colors.black12,
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.noFortunes,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontSize: 16,
              fontWeight: FontWeight.w500
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildCombinedAccordingToFilter(bool isDark) {
    List<FortuneModel> list = [];
    if (_selectedFilter == 'dream') {
      final dreams = _userFortunes.where((f) => f.type == FortuneType.dream).toList();
      final draws = _dreamDraws.map((d) => _mapDreamDrawToFortune(d)).toList();
      list = [...dreams, ...draws];
    } else if (_selectedFilter == 'all') {
      final draws = _dreamDraws.map((d) => _mapDreamDrawToFortune(d)).toList();
      list = [..._userFortunes, ...draws];
    } else {
      list = _userFortunes
          .where((f) => f.type.name.toLowerCase() == _selectedFilter.toLowerCase())
          .toList();
    }
    
    if (list.isEmpty) return _buildEmptyState(isDark);
    
    switch (_selectedSort) {
      case 'newest':
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'oldest':
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'favorites':
        list = list.where((f) => f.isFavorite).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'rating':
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final fortune = list[index];
        return _buildElegantFortuneCard(fortune, isDark);
      },
    );
  }

  FortuneModel _mapDreamDrawToFortune(Map<String, dynamic> d) {
    DateTime createdAt;
    final raw = d['createdAt'];
    if (raw is Timestamp) {
      createdAt = raw.toDate();
    } else {
      createdAt = DateTime.tryParse(raw?.toString() ?? '') ?? DateTime.now();
    }
    final prompt = (d['prompt'] ?? '').toString();
    final style = (d['style'] ?? AppStrings.dreamDrawing).toString();
    final userId = Provider.of<UserProvider>(context, listen: false).user?.id ?? '';
    return FortuneModel(
      id: d['id']?.toString() ?? '',
      userId: userId,
      type: FortuneType.dream,
      status: FortuneStatus.completed,
      title: style,
      interpretation: prompt.isEmpty ? 'Çizim açıklaması yok.' : prompt,
      inputData: const {},
      selectedCards: const [],
      imageUrls: const [],
      question: null,
      fortuneTellerId: null,
      createdAt: createdAt,
      completedAt: createdAt,
      isFavorite: false,
      rating: 0,
      notes: null,
      isForSelf: true,
      targetPersonName: null,
      metadata: const {'source': 'dream_draw'},
      karmaUsed: 0,
      isPremium: false,
    );
  }

  Future<void> _showAdAndNavigate(FortuneModel fortune) async {
    try {
      final loadedCompleter = Completer<bool>();
      await _adsService.createInterstitialAd(
        adUnitId: _adsService.interstitialAdUnitId,
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
      if (isLoaded) {
        await _adsService.showInterstitialAd();
      }
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FortuneResultScreen(fortune: fortune),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FortuneResultScreen(fortune: fortune),
          ),
        );
      }
    }
  }

  Widget _buildElegantFortuneCard(FortuneModel fortune, bool isDark) {
    final fortuneColor = _getFortuneTypeColor(fortune.type.name);
    final displayTitle = _getFortuneDisplayTitle(fortune);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () => _showAdAndNavigate(fortune),
        child: Container(
          decoration: BoxDecoration(
            color: isDark 
                ? Colors.white.withValues(alpha: 0.05) 
                : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: isDark 
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon Container
                Container(
                  width: 64,
                  height: 64,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? Colors.black.withValues(alpha: 0.2) 
                        : fortuneColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: _getFortuneTypeIcon(fortune.type.name),
                ),
                const SizedBox(width: 16),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayTitle,
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            color: isDark ? Colors.white54 : Colors.black45,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(fortune.createdAt),
                            style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.black45,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Navigation Arrow
                if (fortune.isFavorite)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Icon(
                      Icons.favorite,
                      color: const Color(0xFFFF2D55), // iOS Red
                      size: 20,
                    ),
                  ),
                  
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? Colors.white30 : Colors.black26,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getFortuneDisplayTitle(FortuneModel fortune) {
    if (fortune.metadata['source'] == 'dream_draw') {
      return AppStrings.dreamDrawing;
    }
    switch (fortune.type) {
      case FortuneType.tarot:
        return '${AppStrings.tarot} ${AppStrings.interpretation}';
      case FortuneType.coffee:
        return AppStrings.coffeeFortune;
      case FortuneType.palm:
        return AppStrings.palmFortune;
      case FortuneType.astrology:
        return AppStrings.astrology;
      case FortuneType.face:
        return AppStrings.faceFortune;
      case FortuneType.katina:
        return AppStrings.katinaFortune;
      case FortuneType.dream:
        return AppStrings.dreamInterpretation;
      case FortuneType.daily:
        return AppStrings.dailyFortune;
    }
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
    _backgroundController.dispose();
    _adsService.disposeAllAds();
    super.dispose();
  }
}