import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_strings.dart';
import '../../core/providers/user_provider.dart';
import '../../core/providers/language_provider.dart';
import '../../core/services/ai_service.dart';
import '../../core/widgets/mystical_card.dart';
import '../../core/widgets/mystical_loading.dart' as loading;
import '../../core/widgets/mystical_button.dart';
import '../../core/models/fortune_model.dart' as fm;
import 'horoscope_detail_screen.dart';
import '../fortune/fortune_result_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/utils/share_utils.dart';
import '../../widgets/fortune/karma_cost_badge.dart';
import '../../providers/theme_provider.dart';

extension DateTimeExtension on DateTime {
  int get dayOfYear {
    return difference(DateTime(year, 1, 1)).inDays + 1;
  }
}

class AstrologyScreen extends StatefulWidget {
  const AstrologyScreen({super.key});

  @override
  State<AstrologyScreen> createState() => _AstrologyScreenState();
}

class _AstrologyScreenState extends State<AstrologyScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AIService _ai = AIService();
  
  Map<String, String> _horoscopes = {};
  Map<String, Map<String, int>> _horoscopeStats = {};
  bool _loadingHoroscopes = false;
  
  bool _loadingNatalChart = false;
  bool _localeInitialized = false;
  String? _lastLanguageCode;
  
  String _selectedTimeframe = AppStrings.today;
  String? _userZodiacSign;
  String? _userZodiacEmoji;
  String? _userZodiacAsset;
  final GlobalKey _cardKey = GlobalKey();
  
  String _zodiacAssetFor(String zodiacName) {
    final lower = zodiacName.toLowerCase().replaceAll('ı', 'i').replaceAll('ş', 's').replaceAll('ğ', 'g').replaceAll('ç', 'c').replaceAll('ö', 'o').replaceAll('ü', 'u');
    late final String key;
    if (lower.contains('koc') || lower.contains('aries')) {
      key = 'koc';
    } else if (lower.contains('boga') || lower.contains('taurus')) {
      key = 'boga';
    } else if (lower.contains('ikiz') || lower.contains('gemini')) {
      key = 'ikizler';
    } else if (lower.contains('yengec') || lower.contains('cancer')) {
      key = 'yengec';
    } else if (lower.contains('aslan') || lower.contains('leo')) {
      key = 'aslan';
    } else if (lower.contains('basak') || lower.contains('virgo')) {
      key = 'basak';
    } else if (lower.contains('terazi') || lower.contains('libra')) {
      key = 'terazi';
    } else if (lower.contains('akrep') || lower.contains('scorpio')) {
      key = 'akrep';
    } else if (lower.contains('yay') || lower.contains('sagittarius')) {
      key = 'yay';
    } else if (lower.contains('oglak') || lower.contains('capricorn')) {
      key = 'oglak';
    } else if (lower.contains('kova') || lower.contains('aquarius')) {
      key = 'kova';
    } else if (lower.contains('balik') || lower.contains('pisces')) {
      key = 'balik';
    } else {
      return 'assets/icons/astrology.png';
    }
    return 'assets/burclar/$key.png';
  }
  
  List<Map<String, String>> _getZodiacList() {
    return [
      {'name': AppStrings.aries, 'emoji': '♈', 'date': AppStrings.zodiacDateAries},
      {'name': AppStrings.taurus, 'emoji': '♉', 'date': AppStrings.zodiacDateTaurus},
      {'name': AppStrings.gemini, 'emoji': '♊', 'date': AppStrings.zodiacDateGemini},
      {'name': AppStrings.cancer, 'emoji': '♋', 'date': AppStrings.zodiacDateCancer},
      {'name': AppStrings.leo, 'emoji': '♌', 'date': AppStrings.zodiacDateLeo},
      {'name': AppStrings.virgo, 'emoji': '♍', 'date': AppStrings.zodiacDateVirgo},
      {'name': AppStrings.libra, 'emoji': '♎', 'date': AppStrings.zodiacDateLibra},
      {'name': AppStrings.scorpio, 'emoji': '♏', 'date': AppStrings.zodiacDateScorpio},
      {'name': AppStrings.sagittarius, 'emoji': '♐', 'date': AppStrings.zodiacDateSagittarius},
      {'name': AppStrings.capricorn, 'emoji': '♑', 'date': AppStrings.zodiacDateCapricorn},
      {'name': AppStrings.aquarius, 'emoji': '♒', 'date': AppStrings.zodiacDateAquarius},
      {'name': AppStrings.pisces, 'emoji': '♓', 'date': AppStrings.zodiacDatePisces},
    ];
  }

  @override
  void initState() {
    super.initState();
    _initializeLocale();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeUserZodiac();
    _loadHoroscopes();
      // Initialize language code
      final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
      _lastLanguageCode = languageProvider.languageCode;
    });
  }

  void _initializeUserZodiac() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;
    if (user?.birthDate != null) {
      final sign = _calculateZodiacSign(user!.birthDate);
      final zodiacList = _getZodiacList();
      final z = zodiacList.firstWhere((element) => element['name'] == sign, orElse: () => {'emoji': '⭐', 'date': ''});
      setState(() {
        _userZodiacSign = sign;
        _userZodiacEmoji = z['emoji'];
        _userZodiacAsset = _zodiacAssetFor(sign);
      });
    }
  }

  Future<void> _initializeLocale() async {
    try {
      await initializeDateFormatting('tr_TR', null);
      if (mounted) {
        setState(() {
          _localeInitialized = true;
        });
      }
    } catch (e) {
      // If locale initialization fails, continue without Turkish locale
      if (mounted) {
        setState(() {
          _localeInitialized = true;
        });
      }
    }
  }

  Future<void> _loadHoroscopes() async {
    if (_loadingHoroscopes) return;
    setState(() => _loadingHoroscopes = true);
    
    final today = DateTime.now();
    DateTime targetDate = today;
    
    if (_selectedTimeframe == AppStrings.yesterday) {
      targetDate = today.subtract(const Duration(days: 1));
    } else if (_selectedTimeframe == AppStrings.tomorrow) {
      targetDate = today.add(const Duration(days: 1));
    }
    
    String periodKey = 'daily';
    String docKey = '';
    
    if (_selectedTimeframe == AppStrings.weekly) {
      periodKey = 'weekly';
      // ISO week number calculation approximately
      int weekNum = ((targetDate.dayOfYear - targetDate.weekday + 10) / 7).floor();
      docKey = 'weekly_${targetDate.year}-W${weekNum.toString().padLeft(2, '0')}';
    } else if (_selectedTimeframe == AppStrings.monthly) {
      periodKey = 'monthly';
      docKey = 'monthly_${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}';
    } else if (_selectedTimeframe == AppStrings.yearly) {
      periodKey = 'yearly';
      docKey = 'yearly_${targetDate.year}';
    } else {
      // Daily (Dün, Bugün, Yarın)
      periodKey = 'daily';
      docKey = 'daily_${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';
    }
    
    final zodiacList = _getZodiacList();
    final signs = zodiacList.map((z) => z['name']!).toList();
    
    try {
      final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
      final isEnglish = languageProvider.isEnglish;
      final textKey = isEnglish ? 'texts_en' : 'texts';
      
      final docRef = _firestore.collection('horoscopes').doc(docKey);
      final doc = await docRef.get();

      bool isNewFormat = false;
      Map<String, dynamic>? data;
      Map<String, dynamic>? textsData;

      if (doc.exists && doc.data() != null) {
        final docData = doc.data()!;
        
        // First check for language-specific texts/shorts (new format)
        if (docData.containsKey(textKey) && docData[textKey] is Map) {
          textsData = Map<String, dynamic>.from(docData[textKey]);
          isNewFormat = true;
        }
        
        // Fallback to horoscopes format (old format with stats)
        if (!isNewFormat && docData.containsKey('horoscopes')) {
          final rawData = docData['horoscopes'];
        if (rawData is Map && rawData.isNotEmpty) {
          data = Map<String, dynamic>.from(rawData);
          // Check if first value is Map (new format with stats)
          if (data.values.first is Map) {
            isNewFormat = true;
      }
          }
        }
      }

      if (isNewFormat) {
        final Map<String, String> mappedHoroscopes = {};
        final Map<String, Map<String, int>> mappedStats = {};
        
        if (textsData != null) {
          // Use language-specific texts
          final englishToTurkish = {
            'Aries': AppStrings.aries,
            'Taurus': AppStrings.taurus,
            'Gemini': AppStrings.gemini,
            'Cancer': AppStrings.cancer,
            'Leo': AppStrings.leo,
            'Virgo': AppStrings.virgo,
            'Libra': AppStrings.libra,
            'Scorpio': AppStrings.scorpio,
            'Sagittarius': AppStrings.sagittarius,
            'Capricorn': AppStrings.capricorn,
            'Aquarius': AppStrings.aquarius,
            'Pisces': AppStrings.pisces,
          };
          
          // Get stats from horoscopes if available
          if (doc.exists && doc.data() != null && doc.data()!.containsKey('horoscopes')) {
            final horoscopesData = doc.data()!['horoscopes'];
            if (horoscopesData is Map) {
              horoscopesData.forEach((key, value) {
                if (value is Map && value.containsKey('stats')) {
                  final trKey = englishToTurkish[key] ?? key;
                  final stats = value['stats'] as Map;
                  mappedStats[trKey] = {
                    'love': (stats['love'] as num?)?.toInt() ?? 50,
                    'career': (stats['career'] as num?)?.toInt() ?? 50,
                    'health': (stats['health'] as num?)?.toInt() ?? 50,
                  };
                }
              });
            }
          }
          
          // Map texts to current language zodiac names
          textsData.forEach((key, value) {
            final trKey = englishToTurkish[key] ?? key;
            mappedHoroscopes[trKey] = value.toString();
          });
        } else if (data != null) {
          // Fallback to horoscopes format
        final englishToTurkish = {
          'Aries': AppStrings.aries,
          'Taurus': AppStrings.taurus,
          'Gemini': AppStrings.gemini,
          'Cancer': AppStrings.cancer,
          'Leo': AppStrings.leo,
          'Virgo': AppStrings.virgo,
          'Libra': AppStrings.libra,
          'Scorpio': AppStrings.scorpio,
          'Sagittarius': AppStrings.sagittarius,
          'Capricorn': AppStrings.capricorn,
          'Aquarius': AppStrings.aquarius,
          'Pisces': AppStrings.pisces,
        };
        
        data.forEach((key, value) {
          final trKey = englishToTurkish[key] ?? key;
          if (value is Map) {
            mappedHoroscopes[trKey] = value['text']?.toString() ?? '';
            if (value['stats'] is Map) {
              final stats = value['stats'] as Map;
              mappedStats[trKey] = {
                'love': (stats['love'] as num?)?.toInt() ?? 50,
                'career': (stats['career'] as num?)?.toInt() ?? 50,
                'health': (stats['health'] as num?)?.toInt() ?? 50,
              };
            }
          }
        });
        }
        
        if (mounted) {
          setState(() {
            _horoscopes = mappedHoroscopes;
            _horoscopeStats = mappedStats;
            _loadingHoroscopes = false;
          });
          }
      } else {
        // Generate if missing or old format
        await _fetchOrGenerateHoroscopes(targetDate, periodKey, docKey);
      }
    } catch (e) {
      // Fallback
      final newHoroscopes = <String, String>{};
      for (final sign in signs) {
        newHoroscopes[sign] = _getDefaultHoroscope(sign);
      }
    if (mounted) {
      setState(() {
        _horoscopes = newHoroscopes;
          _horoscopeStats = {};
        _loadingHoroscopes = false;
      });
    }
  }
  }

  Future<void> _fetchOrGenerateHoroscopes(DateTime date, String period, String docKey) async {
    try {
      final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
      final isEnglish = languageProvider.isEnglish;
      final resultJson = await _ai.generateBatchDailyHoroscopes(date: date, period: period, english: isEnglish);
      
      // Robust JSON extraction
      String jsonStr = resultJson.trim();
      final startIndex = jsonStr.indexOf('{');
      final endIndex = jsonStr.lastIndexOf('}');
      
      if (startIndex != -1 && endIndex != -1) {
        jsonStr = jsonStr.substring(startIndex, endIndex + 1);
      } else {
        // Fallback cleanup if braces not found (unlikely for valid JSON)
        jsonStr = jsonStr.replaceAll('```json', '').replaceAll('```', '').trim();
      }
      
      Map<String, dynamic> parsedData;
      try {
        parsedData = Map<String, dynamic>.from(jsonDecode(jsonStr));
      } catch (e) {
        debugPrint('JSON Parse Error: $e');
        debugPrint('Raw JSON: $jsonStr');
        parsedData = {};
      }
      
      if (parsedData.isNotEmpty) {
        // Save to Firestore with language-specific keys
        final textKey = isEnglish ? 'texts_en' : 'texts';
        final shortKey = isEnglish ? 'shorts_en' : 'shorts';
        
        // Convert parsedData to language-specific format
        final Map<String, String> texts = {};
        final Map<String, String> shorts = {};
        parsedData.forEach((key, value) {
          if (value is Map) {
            texts[key] = value['text']?.toString() ?? '';
            // Generate short version
            final fullText = value['text']?.toString() ?? '';
            shorts[key] = _summarizeShort(fullText);
          } else {
            texts[key] = value.toString();
            shorts[key] = _summarizeShort(value.toString());
          }
        });
        
        await _firestore.collection('horoscopes').doc(docKey).set({
          'date': date.toIso8601String(),
          'period': period,
          'horoscopes': parsedData, // Keep original format for stats
          textKey: texts,
          shortKey: shorts,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        // Update UI
        final Map<String, String> mappedHoroscopes = {};
        final Map<String, Map<String, int>> mappedStats = {};
        final englishToTurkish = {
          'Aries': AppStrings.aries,
          'Taurus': AppStrings.taurus,
          'Gemini': AppStrings.gemini,
          'Cancer': AppStrings.cancer,
          'Leo': AppStrings.leo,
          'Virgo': AppStrings.virgo,
          'Libra': AppStrings.libra,
          'Scorpio': AppStrings.scorpio,
          'Sagittarius': AppStrings.sagittarius,
          'Capricorn': AppStrings.capricorn,
          'Aquarius': AppStrings.aquarius,
          'Pisces': AppStrings.pisces,
        };
        
        parsedData.forEach((key, value) {
          final trKey = englishToTurkish[key] ?? key;
          if (value is Map) {
            mappedHoroscopes[trKey] = value['text']?.toString() ?? '';
            if (value['stats'] is Map) {
              final stats = value['stats'] as Map;
              mappedStats[trKey] = {
                'love': (stats['love'] as num?)?.toInt() ?? 50,
                'career': (stats['career'] as num?)?.toInt() ?? 50,
                'health': (stats['health'] as num?)?.toInt() ?? 50,
              };
            }
          } else {
            mappedHoroscopes[trKey] = value.toString();
          }
        });
        
        if (mounted) {
          setState(() {
            _horoscopes = mappedHoroscopes;
            _horoscopeStats = mappedStats;
            _loadingHoroscopes = false;
          });
        }
      } else {
        throw Exception('Empty AI response');
    }
    } catch (e) {
      // Fallback
      final zodiacList = _getZodiacList();
      final signs = zodiacList.map((z) => z['name']!).toList();
      final newHoroscopes = <String, String>{};
      for (final sign in signs) {
        newHoroscopes[sign] = _getDefaultHoroscope(sign);
      }
    if (mounted) {
      setState(() {
        _horoscopes = newHoroscopes;
          _horoscopeStats = {};
        _loadingHoroscopes = false;
      });
    }
  }
  }

  String _getDefaultHoroscope(String sign) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isEnglish = languageProvider.isEnglish;
    return isEnglish 
        ? 'For $sign sign, the guidance of the stars awaits you today...'
        : '$sign burcu için bugün yıldızların rehberliği sizi bekliyor...';
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

  Future<void> _generateNatalChart() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;
    
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.userInfoNotFound), backgroundColor: Colors.redAccent),
      );
      return;
    }
    
    if (user.birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.addBirthDateForNatalChart), backgroundColor: Colors.orange),
      );
      return;
    }
    
    setState(() {
      _loadingNatalChart = true;
    });
    
    try {
      loading.MysticLoading.show(context, message: AppStrings.creatingNatalChart);
      
      final reading = await _ai.generateAstrologyReading(
        birthDate: user.birthDate!,
        birthPlace: user.birthPlace ?? 'İstanbul',
        user: user,
      );
      
      // Save to Firestore readings collection
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        if (mounted) {
          await loading.MysticLoading.hide(context);
          setState(() {
            _loadingNatalChart = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.userLoginRequired), backgroundColor: Colors.redAccent),
          );
        }
        return;
      }

      // Calculate wait time
      final waitMinutes = 15 + (DateTime.now().millisecond % 11);
      final availableAt = DateTime.now().add(Duration(minutes: waitMinutes));
      
      // Save to readings collection
      final docRef = _firestore.collection('readings').doc();
      final fortuneData = {
        'userId': userId,
        'type': 'astrology',
        'title': AppStrings.natalChart,
        'interpretation': reading,
        'createdAt': FieldValue.serverTimestamp(),
        'completedAt': FieldValue.serverTimestamp(),
        'rating': 0.0,
        'isFavorite': false,
        'metadata': {
          'source': 'natal_chart',
          'birthDate': user.birthDate!.toIso8601String(),
          'birthPlace': user.birthPlace ?? 'İstanbul',
          'availableAt': availableAt.toIso8601String(),
          'waitMinutes': waitMinutes,
        },
      };
      await docRef.set(fortuneData);

      // Create FortuneModel for navigation
      final fortune = fm.FortuneModel(
        id: docRef.id,
        userId: userId,
        type: fm.FortuneType.astrology,
        status: fm.FortuneStatus.completed,
        title: 'Kişisel Harita (Natal Chart)',
        interpretation: reading,
        createdAt: DateTime.now(),
        completedAt: DateTime.now(),
        isFavorite: false,
        rating: 0,
        metadata: {
          'source': 'natal_chart',
          'birthDate': user.birthDate!.toIso8601String(),
          'birthPlace': user.birthPlace ?? 'İstanbul',
        },
      );

      if (mounted) {
        await loading.MysticLoading.hide(context);
        setState(() {
          _loadingNatalChart = false;
        });
        
        // Navigate to result screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FortuneResultScreen(fortune: fortune),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        await loading.MysticLoading.hide(context);
        setState(() {
          _loadingNatalChart = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppStrings.natalChartCouldNotBeCreated} $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  String _calculateZodiacSign(DateTime? birthDate) {
    if (birthDate == null) return AppStrings.notSpecified;
    final month = birthDate.month;
    final day = birthDate.day;
    
    if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) return AppStrings.aries;
    if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) return AppStrings.taurus;
    if ((month == 5 && day >= 21) || (month == 6 && day <= 20)) return AppStrings.gemini;
    if ((month == 6 && day >= 21) || (month == 7 && day <= 22)) return AppStrings.cancer;
    if ((month == 7 && day >= 23) || (month == 8 && day <= 22)) return AppStrings.leo;
    if ((month == 8 && day >= 23) || (month == 9 && day <= 22)) return AppStrings.virgo;
    if ((month == 9 && day >= 23) || (month == 10 && day <= 22)) return AppStrings.libra;
    if ((month == 10 && day >= 23) || (month == 11 && day <= 21)) return AppStrings.scorpio;
    if ((month == 11 && day >= 22) || (month == 12 && day <= 21)) return AppStrings.sagittarius;
    if ((month == 12 && day >= 22) || (month == 1 && day <= 19)) return AppStrings.capricorn;
    if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) return AppStrings.aquarius;
    return AppStrings.pisces;
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;
    final zodiacSign = _calculateZodiacSign(user?.birthDate);
    
    return Consumer2<ThemeProvider, LanguageProvider>(
      builder: (context, themeProvider, languageProvider, child) {
        final isDark = themeProvider.isDarkMode;
        
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
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
            decoration: BoxDecoration(gradient: themeProvider.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
                  _buildHeader(zodiacSign, isDark),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                          _buildNatalChartSection(user, isDark),
                      const SizedBox(height: 24),
                          _buildDailyHoroscopesSection(isDark),
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

  Widget _buildHeader(String zodiacSign, bool isDark) {
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
            AppStrings.astrology,
            style: AppTextStyles.headingLarge.copyWith(color: textColor),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
          ),
          ),
          const SizedBox(width: 8),
          const KarmaCostBadge(fortuneType: 'astrology'),
          if (zodiacSign != AppStrings.notSpecified) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    _zodiacAssetFor(zodiacSign),
                    width: 18,
                    height: 18,
                    errorBuilder: (_, __, ___) => const Text('♈', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    zodiacSign,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNatalChartSection(user, bool isDark) {
    final textColor = AppColors.getTextPrimary(isDark);
    final textSecondary = AppColors.getTextSecondary(isDark);
    final cardBg = AppColors.getCardBackground(isDark);
    
    return MysticalCard(
      showGlow: false,
      enforceAspectRatio: false,
      toggleFlipOnTap: false,
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.secondary.withValues(alpha: isDark ? 0.2 : 0.15),
              cardBg.withValues(alpha: isDark ? 0.8 : 0.95),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.stars, color: textColor, size: 26),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    AppStrings.natalChart,
                    style: AppTextStyles.headingMedium.copyWith(color: textColor),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              AppStrings.natalChartDesc,
              style: AppTextStyles.bodySmall.copyWith(color: textSecondary),
            ),
            if (user?.birthDate != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.surfaceColor : Colors.grey[200]!).withOpacity(0.35),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cake, color: AppColors.secondary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _localeInitialized
                            ? '${AppStrings.birthDateLabel} ${DateFormat('dd MMMM yyyy', 'tr_TR').format(user.birthDate)}'
                            : '${AppStrings.birthDateLabel} ${user.birthDate.day}/${user.birthDate.month}/${user.birthDate.year}',
                        style: AppTextStyles.bodyMedium.copyWith(color: textColor),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (_loadingNatalChart)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: loading.MysticalLoading(
                    type: loading.MysticalLoadingType.spinner,
                    size: 36,
                    color: AppColors.primary,
                  ),
                ),
              )
            else
              MysticalButton.primary(
                text: AppStrings.createMyNatalChart,
                onPressed: _generateNatalChart,
                icon: Icons.auto_awesome,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyHoroscopesSection(bool isDark) {
    final textColor = AppColors.getTextPrimary(isDark);
    final textSecondary = AppColors.getTextSecondary(isDark);
    final cardBg = AppColors.getCardBackground(isDark);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.calendar_today, color: AppColors.primary, size: 24),
            const SizedBox(width: 8),
            Text(
              AppStrings.dailyHoroscopeReadings,
              style: AppTextStyles.headingMedium.copyWith(color: textColor),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Filter bar like in the screenshot
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(AppStrings.yesterday, isDark),
                _buildFilterChip(AppStrings.today, isDark),
                _buildFilterChip(AppStrings.tomorrow, isDark),
                _buildFilterChip(AppStrings.weekly, isDark),
                _buildFilterChip(AppStrings.monthly, isDark),
                _buildFilterChip(AppStrings.yearly, isDark),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Auto Person's Zodiac Circle
        Center(
          child: Column(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary.withOpacity(0.5), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: _userZodiacSign != null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_userZodiacAsset != null)
                            Image.asset(
                              _userZodiacAsset!,
                              width: 40,
                              height: 40,
                            )
                          else
                            Text(_userZodiacEmoji ?? '⭐', style: const TextStyle(fontSize: 40)),
        const SizedBox(height: 8),
        Text(
                            _userZodiacSign!,
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              AppStrings.autoUserZodiac,
                              style: TextStyle(color: textSecondary),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        
        Text(
          AppStrings.statistics,
          style: AppTextStyles.headingMedium.copyWith(color: textColor),
        ),
        // Placeholder for statistics
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(AppStrings.horoscopeLove, 'love', Colors.pinkAccent, isDark),
              _buildStatItem(AppStrings.horoscopeCareer, 'career', Colors.amberAccent, isDark),
              _buildStatItem(AppStrings.horoscopeHealth, 'health', Colors.greenAccent, isDark),
            ],
          ),
        ),

        Text(
          AppStrings.dailyComment,
          style: AppTextStyles.headingMedium.copyWith(color: textColor),
        ),
        const SizedBox(height: 8),
        
        // Specific comment for user's zodiac
        if (_userZodiacSign != null && _horoscopes.containsKey(_userZodiacSign))
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: RepaintBoundary(
              key: _cardKey,
              child: MysticalCard(
                enforceAspectRatio: false,
                toggleFlipOnTap: false,
                padding: EdgeInsets.zero,
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HoroscopeDetailScreen(
                        zodiacName: _userZodiacSign!,
                        emoji: _userZodiacEmoji ?? '',
                      ),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.secondary.withValues(alpha: isDark ? 0.2 : 0.15),
                        cardBg.withValues(alpha: isDark ? 0.8 : 0.95),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              AppStrings.horoscopeFor(_userZodiacSign!, _selectedTimeframe),
                              style: AppTextStyles.headingSmall.copyWith(color: textColor),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.share, color: textSecondary),
                            onPressed: () => ShareUtils.captureAndShare(
                              key: _cardKey,
                              text: AppStrings.isEnglish
                                  ? 'My $_userZodiacSign horoscope for ${_selectedTimeframe.toLowerCase()}: ${_horoscopes[_userZodiacSign]!}\n\nCheck your fortune with Falla!'
                                  : '$_userZodiacSign burcu için ${_selectedTimeframe.toLowerCase()} yorumum: ${_horoscopes[_userZodiacSign]!}\n\nFalla ile falına bak!',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _horoscopes[_userZodiacSign]!,
                        style: AppTextStyles.bodyMedium.copyWith(color: textColor),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            AppStrings.continueReading,
                            style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward, size: 16, color: AppColors.secondary),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // Daily comment content here (currently loaded horoscopes)
        _loadingHoroscopes
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: loading.MysticalLoading(
                    type: loading.MysticalLoadingType.spinner,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
              )
            : _buildAllZodiacsGrid(isDark),
      ],
    );
  }

  Widget _buildStatItem(String label, String key, Color color, bool isDark) {
    int value = 0;
    if (_userZodiacSign != null && _horoscopeStats.containsKey(_userZodiacSign)) {
      value = _horoscopeStats[_userZodiacSign]![key] ?? 0;
    }
    final textColor = AppColors.getTextPrimary(isDark);
    final textSecondary = AppColors.getTextSecondary(isDark);
    
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                value: value > 0 ? value / 100 : 0,
                color: color,
                backgroundColor: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                strokeWidth: 4,
              ),
            ),
            Text(
              value > 0 ? '%$value' : '-',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: textSecondary, fontSize: 12)),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isDark) {
    final selected = _selectedTimeframe == label;
    final textColor = AppColors.getTextPrimary(isDark);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTimeframe = label;
          _horoscopes = {}; // Clear old data to show loading or new
        });
        _loadHoroscopes();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? (isDark ? Colors.white : Colors.black).withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? (isDark ? Colors.white54 : Colors.black38) : Colors.transparent),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildAllZodiacsGrid(bool isDark) {
    return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.75,
                ),
                itemCount: _getZodiacList().length,
                itemBuilder: (context, index) {
                  final zodiac = _getZodiacList()[index];
                  final desc = _horoscopes[zodiac['name']] ?? _getDefaultHoroscope(zodiac['name']!);
                  return _buildZodiacCard(zodiac, desc, isDark);
                },
    );
  }

  Widget _buildZodiacCard(Map<String, String> zodiac, String description, bool isDark) {
    final textColor = AppColors.getTextPrimary(isDark);
    final cardBg = AppColors.getCardBackground(isDark);
    
    return MysticalCard(
      showGlow: false,
      toggleFlipOnTap: false,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HoroscopeDetailScreen(
              zodiacName: zodiac['name']!,
              emoji: zodiac['emoji'] ?? '',
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark ? [
              const Color(0xFF1A1A2E).withOpacity(0.9),
              const Color(0xFF4A148C).withOpacity(0.25),
            ] : [
              cardBg,
              AppColors.primary.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black : Colors.grey[400]!).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: Image.asset(
                      _zodiacAssetFor(zodiac['name']!),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Text(
                        zodiac['emoji'] ?? '⭐',
                        style: const TextStyle(fontSize: 42),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      zodiac['name']!,
                      style: AppTextStyles.headingSmall.copyWith(
                        color: textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Text(
                  description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: textColor.withOpacity(0.85),
                    fontSize: 14,
                    height: 1.5,
                  ),
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                  Text(
                    AppStrings.detail,
                    style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                    ),
                  ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_ios, size: 10, color: AppColors.secondary),
                ],
                    ),
              ),
            ],
              ),
            ],
          ),
          ),
        ),
    );
  }
}