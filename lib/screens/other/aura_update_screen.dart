import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/ai_service.dart';
import '../../core/widgets/mystical_card.dart';
import '../../core/widgets/mystical_loading.dart';
import '../../core/providers/user_provider.dart';
import '../../core/utils/helpers.dart';
import '../../providers/theme_provider.dart';

class AuraUpdateScreen extends StatefulWidget {
  const AuraUpdateScreen({super.key});

  @override
  State<AuraUpdateScreen> createState() => _AuraUpdateScreenState();
}

class _AuraUpdateScreenState extends State<AuraUpdateScreen> with SingleTickerProviderStateMixin {
  final AIService _ai = AIService();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;

  // Inputs
  String _selectedMood = '';
  double _sleepHours = 8.0;
  String _selectedEmotion = '';
  DateTime? _birthDate;
  String? _zodiacSign;

  // Results
  Color? _auraColor;
  String? _auraColorName;
  double? _auraFrequency;
  String? _auraDescription;
  bool _isLoading = false;

  List<String> get _moods => [
    AppStrings.happy,
    AppStrings.tired,
    AppStrings.stressed,
    AppStrings.calm,
    AppStrings.energetic,
    AppStrings.anxious,
    AppStrings.relaxed,
  ];
  List<String> get _emotions => [
    AppStrings.happy,
    AppStrings.tired,
    AppStrings.stressed,
    AppStrings.calm,
    AppStrings.energetic,
    AppStrings.anxious,
    AppStrings.sad,
    AppStrings.excited,
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _initializeMoodAndEmotion();
    _loadUserData();
  }

  void _initializeMoodAndEmotion() {
    final moods = _moods;
    final emotions = _emotions;
    if (mounted) {
      setState(() {
        _selectedMood = moods.isNotEmpty ? moods[0] : '';
        _selectedEmotion = emotions.isNotEmpty ? emotions[0] : '';
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user != null) {
      setState(() {
        _birthDate = user.birthDate;
        _zodiacSign = user.zodiacSign ?? (user.birthDate != null ? Helpers.calculateZodiacSign(user.birthDate!) : null);
        if (user.preferences.containsKey('auraColor')) {
          final savedColor = user.preferences['auraColor'] as String?;
          if (savedColor != null && savedColor.isNotEmpty) {
            _auraColorName = savedColor;
            _auraColor = _parseColorFromName(savedColor);
          }
        }
        if (user.preferences.containsKey('auraFrequency')) {
          _auraFrequency = (user.preferences['auraFrequency'] as num?)?.toDouble();
        }
        if (user.preferences.containsKey('auraDescription')) {
          _auraDescription = user.preferences['auraDescription'] as String?;
        }
      });
    }
  }

  Color? _parseColorFromName(String name) {
    final colorMap = {
      'Mor': const Color(0xFF9B59B6),
      'Mavi': const Color(0xFF3498DB),
      'Yeşil': const Color(0xFF2ECC71),
      'Sarı': const Color(0xFFF1C40F),
      'Turuncu': const Color(0xFFE67E22),
      'Kırmızı': const Color(0xFFE74C3C),
      'Pembe': const Color(0xFFE91E63),
      'Indigo': const Color(0xFF6C5CE7),
      'Turkuaz': const Color(0xFF1ABC9C),
    };
    return colorMap[name] ?? const Color(0xFF9B59B6);
  }

  // HSV temelli aura rengi hesaplama
  bool _isMood(String value, String turkish, String english) {
    return value.toLowerCase() == turkish.toLowerCase() || value.toLowerCase() == english.toLowerCase();
  }

  Color _calculateAuraColor(String mood, String emotion, double sleepHours) {
    double hue = 0;
    double saturation = 0.7;
    double value = 0.9;

    // Duygusal harita: Mood bazlı
    if (_isMood(mood, AppStrings.happy, AppStrings.happy)) {
      hue = 45; // Sarı
      value = 0.95;
    } else if (_isMood(mood, AppStrings.tired, AppStrings.tired)) {
      hue = 200; // Mavi
      value = 0.6;
      saturation = 0.5;
    } else if (_isMood(mood, AppStrings.stressed, AppStrings.stressed)) {
      hue = 330; // Mor-Kırmızı
      value = 0.7;
      saturation = 0.8;
    } else if (_isMood(mood, AppStrings.calm, AppStrings.calm)) {
      hue = 180; // Turkuaz
      value = 0.85;
      saturation = 0.6;
    } else if (_isMood(mood, AppStrings.energetic, AppStrings.energetic)) {
      hue = 15; // Turuncu-Kırmızı
      value = 1.0;
      saturation = 0.9;
    } else if (_isMood(mood, AppStrings.anxious, AppStrings.anxious)) {
      hue = 280; // Mor
      value = 0.65;
      saturation = 0.7;
    } else if (_isMood(mood, AppStrings.relaxed, AppStrings.relaxed)) {
      hue = 140; // Yeşil
      value = 0.8;
      saturation = 0.6;
    } else {
      hue = 200;
    }

    // Emotion ek etkisi
    if (_isMood(emotion, AppStrings.happy, AppStrings.happy)) {
      hue = (hue + 20) % 360;
      value = math.min(1.0, value + 0.1);
    } else if (_isMood(emotion, AppStrings.tired, AppStrings.tired)) {
      hue = (hue - 30) % 360;
      value = math.max(0.5, value - 0.2);
    } else if (_isMood(emotion, AppStrings.stressed, AppStrings.stressed)) {
      hue = (hue + 40) % 360;
      saturation = math.min(1.0, saturation + 0.2);
    } else if (_isMood(emotion, AppStrings.energetic, AppStrings.energetic)) {
      hue = (hue + 10) % 360;
      value = math.min(1.0, value + 0.15);
      saturation = math.min(1.0, saturation + 0.1);
    }

    // Uyku süresi etkisi (az uyku = daha koyu, soluk)
    if (sleepHours < 6) {
      value = math.max(0.5, value - 0.2);
      saturation = math.max(0.4, saturation - 0.2);
    } else if (sleepHours > 9) {
      value = math.min(1.0, value + 0.1);
    }

    return HSVColor.fromAHSV(1.0, hue, saturation, value).toColor();
  }

  String _getColorName(Color color) {
    final hsv = HSVColor.fromColor(color);
    final hue = hsv.hue;

    if (hue >= 0 && hue < 15) return 'Kırmızı';
    if (hue >= 15 && hue < 45) return 'Turuncu';
    if (hue >= 45 && hue < 75) return 'Sarı';
    if (hue >= 75 && hue < 150) return 'Yeşil';
    if (hue >= 150 && hue < 210) return 'Turkuaz';
    if (hue >= 210 && hue < 270) return 'Mavi';
    if (hue >= 270 && hue < 300) return 'Indigo';
    if (hue >= 300 && hue < 330) return 'Pembe';
    return 'Mor';
  }

  // Aura frekansı hesaplama (0-100)
  double _calculateAuraFrequency(String mood, String emotion, double sleepHours, DateTime? birthDate) {
    double frequency = 50.0; // Base

    // Uyku etkisi (8 saat = optimal = +30)
    if (sleepHours >= 7 && sleepHours <= 9) {
      frequency += 30;
    } else if (sleepHours >= 6 && sleepHours < 7) {
      frequency += 15;
    } else if (sleepHours > 9) {
      frequency += 20;
    } else if (sleepHours < 6) {
      frequency -= 20;
    }

    // Mood etkisi
    if (_isMood(mood, AppStrings.happy, AppStrings.happy) || _isMood(mood, AppStrings.energetic, AppStrings.energetic)) {
      frequency += 25;
    } else if (_isMood(mood, AppStrings.calm, AppStrings.calm) || _isMood(mood, AppStrings.relaxed, AppStrings.relaxed)) {
      frequency += 15;
    } else if (_isMood(mood, AppStrings.tired, AppStrings.tired)) {
      frequency -= 15;
    } else if (_isMood(mood, AppStrings.stressed, AppStrings.stressed) || _isMood(mood, AppStrings.anxious, AppStrings.anxious)) {
      frequency -= 25;
    }

    // Emotion etkisi
    if (_isMood(emotion, AppStrings.happy, AppStrings.happy) || _isMood(emotion, AppStrings.excited, AppStrings.excited)) {
      frequency += 10;
    } else if (_isMood(emotion, AppStrings.tired, AppStrings.tired) || _isMood(emotion, AppStrings.sad, AppStrings.sad)) {
      frequency -= 10;
    }

    // Günün zamanı etkisi
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 12) {
      frequency += 10; // Sabah
    } else if (hour >= 18 && hour < 22) {
      frequency += 5; // Akşam
    } else if (hour >= 22 || hour < 6) {
      frequency -= 10; // Gece
    }

    return frequency.clamp(0.0, 100.0);
  }

  Future<void> _updateAura() async {
    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.addBirthDateToProfileFirst), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _auraDescription = null;
    });

    try {
      MysticLoading.show(context);

      // Aura rengi ve frekans hesapla
      final color = _calculateAuraColor(_selectedMood, _selectedEmotion, _sleepHours);
      final colorName = _getColorName(color);
      final frequency = _calculateAuraFrequency(_selectedMood, _selectedEmotion, _sleepHours, _birthDate);

      // AI açıklama üret
      final prompt = 'Kullanıcının aura analizi:\n'
          'Ruh hali: $_selectedMood\n'
          'Duygu: $_selectedEmotion\n'
          'Uyku süresi: ${_sleepHours.toStringAsFixed(1)} saat\n'
          'Burç: $_zodiacSign\n'
          'Aura rengi: $colorName\n'
          'Aura frekansı: ${frequency.toStringAsFixed(0)}/100\n\n'
          'Bu bilgilere göre kullanıcının aura enerjisini, ruhsal durumunu ve bugünkü potansiyelini 3-4 cümleyle mistik ve şiirsel bir dille açıkla. Türkçe yaz.';

      final description = await _ai.generateMysticReply(
        userMessage: prompt,
        topic: MysticTopic.zodiac,
      );

      // Firestore'a kaydet
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'preferences.auraColor': colorName,
          'preferences.auraFrequency': frequency,
          'preferences.auraDescription': description,
          'preferences.auraMood': _selectedMood,
          'preferences.auraEmotion': _selectedEmotion,
          'preferences.auraSleepHours': _sleepHours,
          'preferences.auraUpdatedAt': FieldValue.serverTimestamp(),
        });

        // UserProvider'ı güncelle (yeniden yükle)
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        if (userId == FirebaseAuth.instance.currentUser?.uid) {
          await userProvider.initialize();
        }
      }

      if (!mounted) return;
      setState(() {
        _auraColor = color;
        _auraColorName = colorName;
        _auraFrequency = frequency;
        _auraDescription = description;
      });

      // Scroll to result
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          await _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
          );
        } catch (_) {}
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppStrings.auraCouldNotBeUpdated} $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        await MysticLoading.hide(context);
      }
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
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildIntroCard(),
                      const SizedBox(height: 16),
                      _buildMoodCard(),
                      const SizedBox(height: 16),
                      _buildSleepCard(),
                      const SizedBox(height: 16),
                      _buildEmotionCard(),
                      const SizedBox(height: 16),
                      _buildBirthDateCard(),
                      const SizedBox(height: 24),
                      if (_auraColor != null && _auraFrequency != null && _auraDescription != null) ...[
                        _buildAuraRing(),
                        const SizedBox(height: 16),
                        _buildAuraResultCard(),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: _buildUpdateButton(),
              ),
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
          Text(AppStrings.auraAnalysisTitle, style: AppTextStyles.headingLarge.copyWith(color: textColor)),
          const Spacer(),
          const Text('🌈', style: TextStyle(fontSize: 24)),
        ],
      ),
    );
  }

  Widget _buildIntroCard() => MysticalCard(
        enforceAspectRatio: false,
        toggleFlipOnTap: false,
        padding: EdgeInsets.zero,
        showGlow: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          constraints: const BoxConstraints(minHeight: 140),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.secondary.withValues(alpha: 0.2),
                AppColors.cardBackground.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  AppStrings.discoverYourSpiritualEnergy,
                  style: AppTextStyles.headingSmall.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 6),
              Flexible(
                child: Text(
                  AppStrings.auraDesc,
                  style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildMoodCard() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final textColor = AppColors.getTextPrimary(isDark);
    final cardBg = AppColors.getCardBackground(isDark);
    final chipBg = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.15);
    final chipSelectedBg = isDark ? Colors.white : AppColors.secondary;
    
    return MysticalCard(
        enforceAspectRatio: false,
        toggleFlipOnTap: false,
        padding: EdgeInsets.zero,
        showGlow: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          constraints: const BoxConstraints(minHeight: 140),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark ? [
                AppColors.secondary.withValues(alpha: 0.2),
                AppColors.cardBackground.withValues(alpha: 0.8),
              ] : [
                AppColors.secondary.withValues(alpha: 0.1),
                cardBg.withValues(alpha: 0.9),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: isDark ? null : Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.mood,
              style: AppTextStyles.headingSmall.copyWith(color: textColor),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _moods.map((mood) {
                final selected = mood == _selectedMood;
                return ChoiceChip(
                  label: Text(mood, style: AppTextStyles.bodySmall.copyWith(color: selected ? (isDark ? Colors.black : Colors.white) : textColor)),
                  selected: selected,
                  onSelected: (v) {
                    if (v) setState(() => _selectedMood = mood);
                  },
                  selectedColor: chipSelectedBg,
                  backgroundColor: chipBg,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  labelStyle: AppTextStyles.bodySmall.copyWith(fontSize: 12),
                );
              }).toList(),
              ),
            ),
          ],
          ),
        ),
      );
  }

  Widget _buildSleepCard() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final textColor = AppColors.getTextPrimary(isDark);
    final cardBg = AppColors.getCardBackground(isDark);
    
    return MysticalCard(
        enforceAspectRatio: false,
        toggleFlipOnTap: false,
        padding: EdgeInsets.zero,
        showGlow: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          constraints: const BoxConstraints(minHeight: 140),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark ? [
                AppColors.secondary.withValues(alpha: 0.2),
                AppColors.cardBackground.withValues(alpha: 0.8),
              ] : [
                AppColors.secondary.withValues(alpha: 0.1),
                cardBg.withValues(alpha: 0.9),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: isDark ? null : Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.sleepDuration,
              style: AppTextStyles.headingSmall.copyWith(color: textColor),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              '${_sleepHours.toStringAsFixed(1)} ${AppStrings.hours}',
              style: AppTextStyles.bodyMedium.copyWith(color: textColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Slider(
              value: _sleepHours,
              min: 0,
              max: 12,
              divisions: 48,
              onChanged: (v) => setState(() => _sleepHours = v),
              activeColor: AppColors.primary,
            ),
          ],
          ),
        ),
      );
  }

  Widget _buildEmotionCard() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final textColor = AppColors.getTextPrimary(isDark);
    final cardBg = AppColors.getCardBackground(isDark);
    final chipBg = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.15);
    final chipSelectedBg = isDark ? Colors.white : AppColors.secondary;
    
    return MysticalCard(
        enforceAspectRatio: false,
        toggleFlipOnTap: false,
        padding: EdgeInsets.zero,
        showGlow: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          constraints: const BoxConstraints(minHeight: 140),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark ? [
                AppColors.secondary.withValues(alpha: 0.2),
                AppColors.cardBackground.withValues(alpha: 0.8),
              ] : [
                AppColors.secondary.withValues(alpha: 0.1),
                cardBg.withValues(alpha: 0.9),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: isDark ? null : Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.todaysEmotion,
              style: AppTextStyles.headingSmall.copyWith(color: textColor),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _emotions.map((emotion) {
                final selected = emotion == _selectedEmotion;
                return ChoiceChip(
                  label: Text(emotion, style: AppTextStyles.bodySmall.copyWith(color: selected ? (isDark ? Colors.black : Colors.white) : textColor)),
                  selected: selected,
                  onSelected: (v) {
                    if (v) setState(() => _selectedEmotion = emotion);
                  },
                  selectedColor: chipSelectedBg,
                  backgroundColor: chipBg,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  labelStyle: AppTextStyles.bodySmall.copyWith(fontSize: 12),
                );
              }).toList(),
              ),
            ),
          ],
          ),
        ),
      );
  }

  Widget _buildBirthDateCard() => MysticalCard(
        enforceAspectRatio: false,
        toggleFlipOnTap: false,
        padding: EdgeInsets.zero,
        showGlow: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          constraints: const BoxConstraints(minHeight: 140),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.secondary.withValues(alpha: 0.2),
                AppColors.cardBackground.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppStrings.birthDateLabel.replaceAll(':', ''),
                      style: AppTextStyles.headingSmall.copyWith(color: Colors.white),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _birthDate != null
                          ? '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}'
                          : AppStrings.notSpecified,
                      style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_zodiacSign != null)
                      Text(
                        '${AppStrings.zodiac}: $_zodiacSign',
                        style: AppTextStyles.bodySmall.copyWith(color: Colors.white54),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildAuraRing() {
    if (_auraColor == null) return const SizedBox.shrink();
    return Center(
      child: MysticalCard(
        aspectRatio: 1,
        padding: EdgeInsets.zero,
        toggleFlipOnTap: false,
        showGlow: true,
        child: CustomPaint(
          painter: AuraRingPainter(
            color: _auraColor!,
            frequency: _auraFrequency ?? 50,
            animationValue: _animationController.value,
          ),
          child: Container(
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _auraColorName ?? '',
                  style: AppTextStyles.headingMedium.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(_auraFrequency ?? 0).toStringAsFixed(0)}/100',
                  style: AppTextStyles.bodyLarge.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuraResultCard() {
    if (_auraDescription == null) return const SizedBox.shrink();
    return MysticalCard(
      padding: EdgeInsets.zero,
      toggleFlipOnTap: false,
      showGlow: false,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.secondary.withValues(alpha: 0.2),
              AppColors.cardBackground.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.auraDescription, style: AppTextStyles.headingSmall.copyWith(color: Colors.white)),
          const SizedBox(height: 12),
          Text(_auraDescription!, style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70)),
        ],
        ),
      ),
    );
  }

  Widget _buildUpdateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _updateAura,
        icon: _isLoading
            ? SizedBox(
                width: 18,
                height: 18,
                child: MysticalLoading(
                  type: MysticalLoadingType.spinner,
                  size: 18,
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.auto_awesome, color: Colors.white),
        label: Text(
          _isLoading ? AppStrings.analyzing : AppStrings.updateAura,
          style: AppTextStyles.buttonLarge.copyWith(color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

// 3D parıltılı halka animasyonu
class AuraRingPainter extends CustomPainter {
  final Color color;
  final double frequency;
  final double animationValue;

  AuraRingPainter({
    required this.color,
    required this.frequency,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.35;

    // Outer glow rings
    for (int i = 0; i < 3; i++) {
      final ringRadius = radius + (i * 15) + (math.sin(animationValue * 2 * math.pi + i) * 5);
      final opacity = (0.3 - (i * 0.1)) * (0.5 + 0.5 * math.sin(animationValue * 2 * math.pi));
      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10);

      canvas.drawCircle(center, ringRadius, paint);
    }

    // Main aura ring
    final mainPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 15);

    // Frequency-based intensity
    final sweepAngle = (frequency / 100) * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2 + (animationValue * 0.1),
      sweepAngle,
      false,
      mainPaint,
    );

    // Inner sparkles
    final sparkleCount = (frequency / 10).round();
    for (int i = 0; i < sparkleCount; i++) {
      final angle = (i / sparkleCount) * 2 * math.pi + (animationValue * 2 * math.pi);
      final sparkleRadius = radius * 0.6 + (math.sin(animationValue * 4 * math.pi + i) * 10);
      final x = center.dx + math.cos(angle) * sparkleRadius;
      final y = center.dy + math.sin(angle) * sparkleRadius;
      final sparklePaint = Paint()
        ..color = color.withValues(alpha: 0.8)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5);

      canvas.drawCircle(Offset(x, y), 3, sparklePaint);
    }
  }

  @override
  bool shouldRepaint(AuraRingPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.color != color ||
        oldDelegate.frequency != frequency;
  }
}
