import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/mystical_card.dart';
import '../../core/widgets/mystical_loading.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/ads_service.dart';
import '../../core/utils/share_utils.dart';
import '../../providers/theme_provider.dart';
import 'dart:async';

class LoveCompatibilityScreen extends StatefulWidget {
  const LoveCompatibilityScreen({super.key});

  @override
  State<LoveCompatibilityScreen> createState() => _LoveCompatibilityScreenState();
}

class _LoveCompatibilityScreenState extends State<LoveCompatibilityScreen> {
  final TextEditingController _nameA = TextEditingController();
  final TextEditingController _nameB = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  DateTime? _birthA;
  DateTime? _birthB;
  String? _zodiacA;
  String? _zodiacB;

  double? _score; // 0..100
  String? _aiText;
  bool _busy = false;

  final AIService _ai = AIService();
  final AdsService _ads = AdsService();
  final GlobalKey _cardKey = GlobalKey();

  // Extra relationship questions
  int _trustLevel = 3; // 1..5
  int _communication = 3; // 1..5
  int _conflictFreq = 2; // 0: hiç, 4: sık
  int _futureAlign = 3; // 1..5

  @override
  void dispose() {
    _nameA.dispose();
    _nameB.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildQuestionsCard() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final textColor = AppColors.getTextPrimary(isDark);
    final cardBg = AppColors.getCardBackground(isDark);
    final chipBg = isDark ? Colors.white.withOpacity(0.08) : Colors.grey.withOpacity(0.15);
    final chipBorder = isDark ? Colors.white24 : Colors.grey.withOpacity(0.3);
    
    Widget meter(String label, int value, ValueChanged<int> onChanged, {int min = 1, int max = 5}) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: AppTextStyles.bodySmall.copyWith(color: textColor)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: List.generate(max - min + 1, (i) {
              final v = min + i;
              final selected = v == value;
              return ChoiceChip(
                label: Text('$v', style: const TextStyle(fontSize: 12)),
                selected: selected,
                onSelected: (_) => onChanged(v),
                selectedColor: AppColors.secondary,
                backgroundColor: chipBg,
                labelStyle: TextStyle(color: selected ? Colors.black : textColor, fontSize: 12),
                shape: StadiumBorder(side: BorderSide(color: chipBorder)),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                visualDensity: VisualDensity.compact,
              );
            }),
          ),
        ],
      );
    }

    return MysticalCard(
      enforceAspectRatio: false,
      toggleFlipOnTap: false,
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppStrings.relationshipQuestions, style: AppTextStyles.headingSmall.copyWith(color: textColor)),
            const SizedBox(height: 8),
            meter(AppStrings.trustLevel, _trustLevel, (v) => setState(() => _trustLevel = v)),
            const SizedBox(height: 8),
            meter(AppStrings.communicationQuality, _communication, (v) => setState(() => _communication = v)),
            const SizedBox(height: 8),
            meter(AppStrings.conflictFrequency, _conflictFreq, (v) => setState(() => _conflictFreq = v), min: 0, max: 5),
            const SizedBox(height: 8),
            meter(AppStrings.futureGoalAlignment, _futureAlign, (v) => setState(() => _futureAlign = v)),
          ],
        ),
      ),
    );
  }

  String _zodiacFrom(DateTime d) {
    final m = d.month, day = d.day;
    String zodiacTr;
    if ((m == 3 && day >= 21) || (m == 4 && day <= 19)) zodiacTr = 'Koç';
    else if ((m == 4 && day >= 20) || (m == 5 && day <= 20)) zodiacTr = 'Boğa';
    else if ((m == 5 && day >= 21) || (m == 6 && day <= 20)) zodiacTr = 'İkizler';
    else if ((m == 6 && day >= 21) || (m == 7 && day <= 22)) zodiacTr = 'Yengeç';
    else if ((m == 7 && day >= 23) || (m == 8 && day <= 22)) zodiacTr = 'Aslan';
    else if ((m == 8 && day >= 23) || (m == 9 && day <= 22)) zodiacTr = 'Başak';
    else if ((m == 9 && day >= 23) || (m == 10 && day <= 22)) zodiacTr = 'Terazi';
    else if ((m == 10 && day >= 23) || (m == 11 && day <= 21)) zodiacTr = 'Akrep';
    else if ((m == 11 && day >= 22) || (m == 12 && day <= 21)) zodiacTr = 'Yay';
    else if ((m == 12 && day >= 22) || (m == 1 && day <= 19)) zodiacTr = 'Oğlak';
    else if ((m == 1 && day >= 20) || (m == 2 && day <= 18)) zodiacTr = 'Kova';
    else zodiacTr = 'Balık';
    return AppStrings.getZodiacName(zodiacTr);
  }

  int _nameNumerology(String name) {
    final letters = name.toUpperCase().runes;
    int sum = 0;
    for (final r in letters) {
      final ch = String.fromCharCode(r);
      if (RegExp(r'[A-ZÇĞİÖŞÜ]').hasMatch(ch)) {
        // Map Turkish chars into ranges by stripping diacritics
        final plain = ch
            .replaceAll('Ç', 'C')
            .replaceAll('Ğ', 'G')
            .replaceAll('İ', 'I')
            .replaceAll('Ö', 'O')
            .replaceAll('Ş', 'S')
            .replaceAll('Ü', 'U');
        final code = plain.codeUnitAt(0) - 64; // A=1
        sum += code.clamp(1, 26);
      }
    }
    // Reduce to 1..9
    while (sum > 9) {
      int s = 0;
      for (final d in sum.toString().runes) {
        s += int.parse(String.fromCharCode(d));
      }
      sum = s;
    }
    return sum == 0 ? 1 : sum;
  }

  double _zodiacAffinity(String a, String b) {
    // Lightweight pairing grid (0..1)
    final fire = AppStrings.zodiacFireElements;
    final earth = AppStrings.zodiacEarthElements;
    final air = AppStrings.zodiacAirElements;
    final water = AppStrings.zodiacWaterElements;
    double group(String z) {
      if (fire.contains(z)) return 0;
      if (earth.contains(z)) return 1;
      if (air.contains(z)) return 2;
      if (water.contains(z)) return 3;
      return 3; // fallback
    }
    final ga = group(a), gb = group(b);
    if (ga == gb) return 0.9; // same element
    final pairs = {
      {0, 2}, // fire-air
      {1, 3}, // earth-water
    };
    final ok = pairs.any((p) => p.contains(ga) && p.contains(gb));
    return ok ? 0.75 : 0.5;
  }

  Future<void> _calculate() async {
    final nameA = _nameA.text.trim();
    final nameB = _nameB.text.trim();
    if (nameA.isEmpty || nameB.isEmpty || _birthA == null || _birthB == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.fillNameAndBirthDates)),
      );
      return;
    }
    setState(() {
      _busy = true;
      _aiText = null;
      _score = null;
    });
    MysticLoading.show(context);
    try {
      final zA = _zodiacA ?? _zodiacFrom(_birthA!);
      final zB = _zodiacB ?? _zodiacFrom(_birthB!);
      final numA = _nameNumerology(nameA);
      final numB = _nameNumerology(nameB);
      final numDelta = (9 - (numA - numB).abs()) / 9.0; // 0..1 (closer better)
      final zodiac = _zodiacAffinity(zA, zB); // 0..1
      var score = (numDelta * 0.45 + zodiac * 0.55) * 100.0;
      // Adjust with answers (max ~ +/- 15)
      score += (_trustLevel - 3) * 2.5; // -5..+5
      score += (_communication - 3) * 2.0; // -4..+4
      score += (_futureAlign - 3) * 2.5; // -5..+5
      score -= (_conflictFreq - 1) * 2.0; // -6..+6 (daha çok kavga => düşüş)

      final prompt = 'Aşk uyumu analizi yap. Kişi A: "$nameA", doğum: ${_birthA!.toIso8601String()}, burç: $zA. '
          'Kişi B: "$nameB", doğum: ${_birthB!.toIso8601String()}, burç: $zB. '
          'İlişki ipuçları: güven ${_trustLevel}/5, iletişim ${_communication}/5, kavga sıklığı ${_conflictFreq}/5, gelecek uyumu ${_futureAlign}/5. '
          'Kısa (2-3 cümle) mistik yorum yaz; güçlü yanlar + dikkat edilmesi gerekenler. Emoji kullan.';

      // Show interstitial before revealing result
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

      final text = await _ai.generateMysticReply(
        userMessage: prompt,
        topic: MysticTopic.zodiac,
        extras: {
          'type': 'love_compatibility',
          'numerology': {'A': numA, 'B': numB},
          'affinity': zodiac,
          'relationship': {
            'trust': _trustLevel,
            'communication': _communication,
            'conflictFrequency': _conflictFreq,
            'futureAlignment': _futureAlign,
          }
        },
      );

      if (!mounted) return;
      setState(() {
        _score = double.parse(score.toStringAsFixed(1));
        _aiText = text;
      });
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
        SnackBar(content: Text('${AppStrings.calculationFailed} $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _busy = false;
      });
      await MysticLoading.hide(context);
    }
  }

  Future<void> _pickDate(bool first) async {
    final now = DateTime.now();
    final init = first ? (_birthA ?? DateTime(now.year - 20)) : (_birthB ?? DateTime(now.year - 20));
    final picked = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year, now.month, now.day),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary,
              surface: const Color(0xFF0D0B1A),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;
    setState(() {
      if (first) {
        _birthA = picked;
        _zodiacA = _zodiacFrom(picked);
      } else {
        _birthB = picked;
        _zodiacB = _zodiacFrom(picked);
      }
    });
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
                    children: [
                      _buildInputCard(AppStrings.personA, _nameA, _birthA, _zodiacA, () => _pickDate(true)),
                      const SizedBox(height: 12),
                      _buildInputCard(AppStrings.personB, _nameB, _birthB, _zodiacB, () => _pickDate(false)),
                    const SizedBox(height: 12),
                    _buildQuestionsCard(),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _busy ? null : _calculate,
                          icon: _busy
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
                              : const Icon(Icons.favorite, color: Colors.white),
                          label: Text(
                            _busy ? AppStrings.calculating : AppStrings.calculateLoveCompatibility,
                            style: AppTextStyles.buttonLarge.copyWith(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      if (_score != null || _aiText != null) ...[
                        const SizedBox(height: 16),
                        _buildResultCard(),
                      ],
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
              AppStrings.loveCompatibilityTest,
              style: AppTextStyles.headingLarge.copyWith(color: textColor),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          const Text('💞', style: TextStyle(fontSize: 24)),
        ],
      ),
    );
  }

  Widget _buildInputCard(
    String title,
    TextEditingController name,
    DateTime? birth,
    String? zodiac,
    VoidCallback onPickDate,
  ) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        final textColor = AppColors.getTextPrimary(isDark);
        final inputTextColor = AppColors.getInputTextColor(isDark);
        final inputHintColor = AppColors.getInputHintColor(isDark);
        final inputBorderColor = AppColors.getInputBorderColor(isDark);
        final cardBg = AppColors.getCardBackground(isDark);
        
    return MysticalCard(
      enforceAspectRatio: false,
      toggleFlipOnTap: false,
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(minHeight: 140),
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
                Text(title, style: AppTextStyles.headingSmall.copyWith(color: textColor)),
            const SizedBox(height: 6),
            TextField(
              controller: name,
                  style: AppTextStyles.bodyMedium.copyWith(color: inputTextColor),
              decoration: InputDecoration(
                labelText: AppStrings.name,
                    labelStyle: TextStyle(color: inputHintColor),
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
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPickDate,
                        icon: Icon(Icons.cake, color: textColor),
                    label: Text(
                      birth == null ? AppStrings.birthDate : '${birth.day}.${birth.month}.${birth.year}',
                          style: AppTextStyles.bodyMedium.copyWith(color: textColor),
                    ),
                    style: OutlinedButton.styleFrom(
                          side: BorderSide(color: inputBorderColor),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                        border: Border.all(color: inputBorderColor),
                    borderRadius: BorderRadius.circular(8),
                        color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                  ),
                  child: Text(
                    zodiac ?? (birth != null ? _zodiacFrom(birth) : AppStrings.zodiacLabel),
                        style: AppTextStyles.bodyMedium.copyWith(color: textColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
        );
      },
    );
  }

  Widget _buildResultCard() {
    return RepaintBoundary(
      key: _cardKey,
      child: MysticalCard(
      enforceAspectRatio: false,
      toggleFlipOnTap: false,
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
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
            if (_score != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
              Text(AppStrings.compatibilityScore, style: AppTextStyles.headingSmall.copyWith(color: Colors.white)),
                    IconButton(
                      icon: const Icon(Icons.share, color: Colors.white70),
                      onPressed: () => ShareUtils.captureAndShare(
                        key: _cardKey,
                        text: AppStrings.loveCompatibilityTestResult.replaceAll('{0}', _score!.toStringAsFixed(1)),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text('${_score!.toStringAsFixed(1)}%', style: AppTextStyles.heading1.copyWith(color: Colors.white)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (_score!.clamp(0, 100)) / 100.0,
                      backgroundColor: Colors.white12,
                      color: AppColors.secondary,
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ],
            if (_aiText != null) ...[
              const SizedBox(height: 12),
              Text(AppStrings.whatDoesFallaSay, style: AppTextStyles.headingSmall.copyWith(color: Colors.white)),
              const SizedBox(height: 6),
              Text(
                _aiText!,
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
              ),
            ],
          ],
          ),
        ),
      ),
    );
  }
}
