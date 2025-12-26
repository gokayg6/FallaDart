import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/ai_service.dart';
import '../../core/widgets/mystical_loading.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_strings.dart';
import '../../core/providers/language_provider.dart';
import '../../core/utils/share_utils.dart';
import '../../core/widgets/shareable_horoscope_card.dart';
import '../../providers/theme_provider.dart';

class HoroscopeDetailScreen extends StatefulWidget {
  final String zodiacName;
  final String emoji;
  const HoroscopeDetailScreen({Key? key, required this.zodiacName, required this.emoji}) : super(key: key);

  @override
  State<HoroscopeDetailScreen> createState() => _HoroscopeDetailScreenState();
}

class _HoroscopeDetailScreenState extends State<HoroscopeDetailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AIService _ai = AIService();
  String? _fullText;
  bool _loading = true;
  String? _error;
  bool _loadingTomorrow = false;
  String? _lastLanguageCode;
  final GlobalKey _cardKey = GlobalKey();
  final GlobalKey _shareableCardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadDetail();
    // Initialize language code
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
      _lastLanguageCode = languageProvider.languageCode;
    });
  }

  Future<void> _loadDetail() async {
    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    try {
      final isEnglish = AppStrings.isEnglish;
      final textKey = isEnglish ? 'texts_en' : 'texts';
      final shortKey = isEnglish ? 'shorts_en' : 'shorts';

      final docRef = _firestore.collection('horoscopes').doc(dateKey);
      final doc = await docRef.get();
      Map<String, dynamic> data = doc.data() ?? {};
      final texts = Map<String, dynamic>.from(data[textKey] ?? {});
      final shorts = Map<String, dynamic>.from(data[shortKey] ?? {});
      String? text = texts[widget.zodiacName]?.toString();
      if (text == null || text.isEmpty) {
        // Generate now, then cache into today's doc
        final aiSign = isEnglish ? _mapTurkishSignToEnglish(widget.zodiacName) : widget.zodiacName;
        text = await _ai.generateDailyHoroscope(
          zodiacSign: aiSign,
          date: today,
          english: isEnglish,
        );
        final short = _summarizeShort(text);
        texts[widget.zodiacName] = text;
        shorts[widget.zodiacName] = short;
        await docRef.set({
          'date': dateKey,
          textKey: texts,
          shortKey: shorts,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      if (!mounted) return;
      setState(() {
        _fullText = text;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '${AppStrings.couldNotLoad} $e';
        _loading = false;
      });
    }
  }

  Future<void> _shareHoroscope() async {
    if (_fullText == null || _fullText!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.couldNotLoad),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    // Get short version (first 1-2 sentences)
    final sentences = _fullText!.split(RegExp(r'[.!?]+')).where((s) => s.trim().isNotEmpty).take(2).toList();
    final shortText = sentences.join('. ') + (sentences.isNotEmpty ? '.' : '');

    // Show shareable card in dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: ShareableHoroscopeCard(
                zodiacName: widget.zodiacName,
                emoji: widget.emoji,
                horoscopeText: shortText,
                repaintKey: _shareableCardKey,
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.white, size: 28),
                    onPressed: () async {
                      try {
                        final isEnglish = AppStrings.isEnglish;
                        final shareText = isEnglish
                            ? 'Check your daily horoscope with Falla Aura!'
                            : 'Falla Aura ile günlük burç yorumunu gör!';
                        
                        await ShareUtils.captureAndShare(
                          key: _shareableCardKey,
                          text: shareText,
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${AppStrings.shareError} $e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LanguageProvider>(
      builder: (context, themeProvider, languageProvider, _) {
        final isDark = themeProvider.isDarkMode;
        
        // Reload detail when language changes
        final currentLanguageCode = languageProvider.languageCode;
        if (_lastLanguageCode != null && _lastLanguageCode != currentLanguageCode) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _loadDetail();
            }
          });
        }
        _lastLanguageCode = currentLanguageCode;
        final textColor = AppColors.getTextPrimary(isDark);
        final textSecondaryColor = AppColors.getTextSecondary(isDark);
        final iconColor = AppColors.getIconColor(isDark);
        final borderColor = isDark 
            ? Colors.white24 
            : Colors.grey.withValues(alpha: 0.3);
        
        return Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: false,
          extendBody: true,
          appBar: AppBar(
            title: Text(
              AppStrings.isEnglish
                  ? '${widget.emoji} ${_mapTurkishSignToEnglish(widget.zodiacName)}'
                  : '${widget.emoji} ${widget.zodiacName}',
              style: TextStyle(color: textColor),
            ),
            backgroundColor: isDark 
                ? Colors.transparent 
                : Colors.white,
            foregroundColor: iconColor,
            elevation: isDark ? 0 : 1,
            actions: [
              IconButton(
                icon: Icon(Icons.share, color: iconColor),
                onPressed: _shareHoroscope,
                tooltip: AppStrings.share,
              ),
            ],
          ),
          body: SizedBox.expand(
            child: Container(
              decoration: BoxDecoration(gradient: themeProvider.backgroundGradient),
              child: SafeArea(
                top: true,
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: MediaQuery.of(context).padding.bottom + 16,
                  ),
                child: _loading
                    ? Center(
                        child: MysticalLoading(
                          type: MysticalLoadingType.spinner,
                          size: 32,
                          color: iconColor,
                        ),
                      )
                    : _error != null
                        ? Center(
                            child: Text(
                              _error!,
                              style: AppTextStyles.bodyMedium.copyWith(color: Colors.redAccent),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                RepaintBoundary(
                                  key: _cardKey,
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      gradient: isDark 
                                          ? AppColors.mysticalGradient 
                                          : LinearGradient(
                                              colors: [AppColors.lightSurface, AppColors.lightCardBackground],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: borderColor),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              AppStrings.isEnglish
                                                  ? '${widget.emoji} ${_mapTurkishSignToEnglish(widget.zodiacName)}'
                                                  : '${widget.emoji} ${widget.zodiacName}',
                                              style: AppTextStyles.headingMedium.copyWith(color: textColor),
                                            ),
                                            const Spacer(),
                                            Text(
                                              AppStrings.dailyHoroscopeReadings,
                                              style: AppTextStyles.bodySmall.copyWith(color: textSecondaryColor),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          _fullText ?? '',
                                          style: AppTextStyles.fortuneResult.copyWith(color: textColor, height: 1.5),
                                          textAlign: TextAlign.justify,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Opacity(
                                  opacity: _loadingTomorrow ? 0.6 : 1.0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isDark 
                                          ? AppColors.cardBackground.withValues(alpha: 0.3)
                                          : AppColors.lightSurface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isDark 
                                            ? AppColors.primary 
                                            : AppColors.primary,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _loadingTomorrow ? null : _generateTomorrow,
                                        borderRadius: BorderRadius.circular(12),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              if (_loadingTomorrow)
                                                SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor: AlwaysStoppedAnimation<Color>(
                                                      isDark ? Colors.white : AppColors.primary,
                                                    ),
                                                  ),
                                                )
                                              else ...[
                                                Icon(
                                                  Icons.auto_awesome,
                                                  color: isDark ? Colors.white : AppColors.primary,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 8),
                                              ],
                                              Text(
                                                AppStrings.tomorrowInsight,
                                                style: AppTextStyles.buttonLarge.copyWith(
                                                  color: isDark ? Colors.white : AppColors.primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _generateTomorrow() async {
    setState(() => _loadingTomorrow = true);
    try {
      final today = DateTime.now();
      final tomorrow = today.add(const Duration(days: 1));
      final tKey = '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
      final isEnglish = AppStrings.isEnglish;
      final aiSign = isEnglish ? _mapTurkishSignToEnglish(widget.zodiacName) : widget.zodiacName;
      final text = await _ai.generateDailyHoroscope(
        zodiacSign: aiSign,
        date: tomorrow,
        english: isEnglish,
      );
      final short = _summarizeShort(text);
      final docRef = _firestore.collection('horoscopes').doc(tKey);
      final textKey = isEnglish ? 'texts_en' : 'texts';
      final shortKey = isEnglish ? 'shorts_en' : 'shorts';
      await docRef.set({
        'date': tKey,
        textKey: { widget.zodiacName: text },
        shortKey: { widget.zodiacName: short },
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      final isDark = themeProvider.isDarkMode;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.getCardBackground(isDark),
          title: Text(AppStrings.tomorrowInsight, style: TextStyle(color: AppColors.getTextPrimary(isDark))),
          content: SingleChildScrollView(child: Text(text, style: TextStyle(color: AppColors.getTextSecondary(isDark), height: 1.5))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(AppStrings.close)),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppStrings.insightCouldNotBeGenerated} $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _loadingTomorrow = false);
    }
  }

  String _summarizeShort(String text) {
    var t = text.trim();
    final idx = t.indexOf('.');
    if (idx != -1) t = t.substring(0, idx + 1);
    if (t.length > 90) t = t.substring(0, 90).trimRight() + '…';
    return t;
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
}


