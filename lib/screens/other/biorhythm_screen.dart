import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/providers/user_provider.dart';
import '../../core/services/ai_service.dart';
import '../../core/widgets/mystical_loading.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/mystical_card.dart';
import '../../core/widgets/mystical_button.dart';
import '../../core/utils/share_utils.dart';
import '../../providers/theme_provider.dart';

class BiorhythmScreen extends StatefulWidget {
  const BiorhythmScreen({super.key});

  @override
  State<BiorhythmScreen> createState() => _BiorhythmScreenState();
}

class _BiorhythmScreenState extends State<BiorhythmScreen> {
  DateTime? _birth;
  DateTime _date = DateTime.now();
  String? _aiText;
  bool _busy = false;
  final AIService _ai = AIService();
  final GlobalKey _cardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<UserProvider>(context, listen: false).user;
      if (user?.birthDate != null) {
        setState(() {
          _birth = user!.birthDate;
        });
      }
    });
  }

  int _daysSinceBirth() {
    if (_birth == null) return 0;
    return _date.difference(_birth!).inDays;
  }

  double _sin(double days, double period) => math.sin(2 * math.pi * days / period);

  Map<String, double> _compute() {
    final d = _daysSinceBirth().toDouble();
    final physical = _sin(d, 23);
    final emotional = _sin(d, 28);
    final mental = _sin(d, 33);
    final score = ((physical + emotional + mental) / 3.0 + 1) * 50; // 0-100 ölçek
    return {
      'physical': physical,
      'emotional': emotional,
      'mental': mental,
      'score': score.clamp(0, 100),
    };
  }

  Future<void> _aiComment() async {
    if (_birth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.selectBirthDateFirst)),
      );
      return;
    }
    setState(() {
      _busy = true;
      _aiText = null;
    });
    MysticLoading.show(context);
    try {
      final res = _compute();
      final p = res['physical']!.toStringAsFixed(2);
      final e = res['emotional']!.toStringAsFixed(2);
      final m = res['mental']!.toStringAsFixed(2);
      final s = res['score']!.toStringAsFixed(0);
      final msg = 'Biyoritim yorumu isteği. Tarih: ${DateFormat('yyyy-MM-dd').format(_date)}. '
          'Değerler (-1 ile +1 arası): Fiziksel:$p, Duygusal:$e, Zihinsel:$m. '
          'Ortalama Enerji Puanı: %$s. '
          'Bu değerlere göre kişinin güncel durumunu analiz et. Hangi döngü yüksek, hangisi düşük? '
          'Buna göre günün enerjisini 2-3 cümleyle yorumla ve tavsiye ver. Mistik ve motive edici bir dil kullan. Emoji ekle.';
      final text = await _ai.generateMysticReply(
        userMessage: msg,
        topic: MysticTopic.biorhythm,
        extras: {
          'type': 'biorhythm',
          'birthDate': _birth!.toIso8601String(),
          'date': _date.toIso8601String(),
        },
      );
      if (!mounted) return;
      setState(() => _aiText = text);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppStrings.aiCommentCouldNotBeRetrieved} $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (!mounted) return;
      setState(() => _busy = false);
      await MysticLoading.hide(context);
    }
  }

  Future<void> _pickBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 20, now.month, now.day),
      firstDate: DateTime(1950),
      lastDate: now,
    );
    if (picked != null) setState(() => _birth = picked);
  }

  @override
  Widget build(BuildContext context) {
    final res = _compute();
    
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: BoxDecoration(gradient: themeProvider.backgroundGradient),
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(isDark),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _tile(
                                  AppStrings.birthDateLabel.replaceAll(':', ''),
                                  _birth == null ? AppStrings.select : DateFormat('dd.MM.yyyy').format(_birth!),
                                  onTap: _pickBirth,
                                  isDark: isDark,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _tile(
                                  AppStrings.date,
                                  DateFormat('dd.MM.yyyy').format(_date),
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _date,
                                      firstDate: DateTime(1950),
                                      lastDate: DateTime.now().add(const Duration(days: 365)),
                                    );
                                    if (picked != null) setState(() => _date = picked);
                                  },
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _scoreCard(res['score']!.toDouble(), isDark),
                          const SizedBox(height: 16),
                          _miniChart(isDark),
                          const SizedBox(height: 16),
                          _series(AppStrings.physical, res['physical']!, Colors.redAccent, isDark),
                          const SizedBox(height: 10),
                          _series(AppStrings.emotional, res['emotional']!, Colors.lightBlueAccent, isDark),
                          const SizedBox(height: 10),
                          _series(AppStrings.mental, res['mental']!, Colors.amberAccent, isDark),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.center,
                            child: MysticalButton.primary(
                              text: _busy ? AppStrings.gettingComment : AppStrings.getAIComment,
                              onPressed: _busy ? null : _aiComment,
                            ),
                          ),
                          if (_aiText != null) ...[
                            const SizedBox(height: 16),
                            _buildResultCard(res['score']!, isDark),
                          ],
                          const SizedBox(height: 12),
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

  Widget _buildResultCard(double score, bool isDark) {
    final textColor = AppColors.getTextPrimary(isDark);
    final textSecondary = AppColors.getTextSecondary(isDark);
    final cardBg = AppColors.getCardBackground(isDark);
    
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
                  Text(AppStrings.dailyBalance, style: AppTextStyles.headingSmall.copyWith(color: textColor)),
                  IconButton(
                    icon: Icon(Icons.share, color: textSecondary),
                    onPressed: () => ShareUtils.captureAndShare(
                      key: _cardKey,
                      text: 'Günlük Biyoritim Dengem: %${score.toStringAsFixed(0)}\n\n$_aiText\n\nFalla ile enerjini keşfet!',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text('%${score.toStringAsFixed(0)}', style: AppTextStyles.heading1.copyWith(color: textColor)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (score.clamp(0, 100)) / 100.0,
                      backgroundColor: (isDark ? Colors.white : Colors.black).withOpacity(0.12),
                      color: AppColors.secondary,
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(AppStrings.whatDoesFallaSay, style: AppTextStyles.headingSmall.copyWith(color: textColor)),
              const SizedBox(height: 6),
              Text(
                _aiText!,
                style: AppTextStyles.bodyMedium.copyWith(color: textColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
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
          Text(
            AppStrings.biorhythmTitle,
            style: AppTextStyles.headingLarge.copyWith(color: textColor),
          ),
          const Spacer(),
          const Text('📊', style: TextStyle(fontSize: 24)),
        ],
      ),
    );
  }

  Widget _tile(String title, String value, {VoidCallback? onTap, required bool isDark}) {
    final textColor = AppColors.getTextPrimary(isDark);
    final textSecondary = AppColors.getTextSecondary(isDark);
    
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Text(
                title,
                style: TextStyle(color: textSecondary),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 6,
              child: Text(
                value,
                style: TextStyle(color: textColor),
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scoreCard(double score, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(colors: [Color(0xFF3B2E77), Color(0xFF7E18A6)]),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(AppStrings.dailyBalance, style: const TextStyle(color: Colors.white70)),
          Text('%${score.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _series(String title, double v, Color color, bool isDark) {
    final pct = ((v + 1) / 2 * 100).clamp(0, 100); // -1..1 -> 0..100
    final textColor = AppColors.getTextPrimary(isDark);
    final textSecondary = AppColors.getTextSecondary(isDark);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: textSecondary)),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: pct / 100.0,
                  backgroundColor: (isDark ? Colors.white : Colors.black).withOpacity(0.12),
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(6),
                )
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text('%${pct.toStringAsFixed(0)}', style: TextStyle(color: textColor)),
        ],
      ),
    );
  }

  Widget _miniChart(bool isDark) {
    // Generate values for last 6 to next 6 days
    final days = List.generate(13, (i) => i - 6);
    final base = _daysSinceBirth().toDouble();
    final phys = days.map((d) => _sin(base + d, 23)).toList();
    final emo = days.map((d) => _sin(base + d, 28)).toList();
    final ment = days.map((d) => _sin(base + d, 33)).toList();
    final textColor = AppColors.getTextPrimary(isDark);
    final textSecondary = AppColors.getTextSecondary(isDark);
    
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: CustomPaint(
        painter: _BiorhythmPainter(phys, emo, ment, isDark),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(AppStrings.minus6Days, style: TextStyle(color: textSecondary)),
            Text(AppStrings.today, style: TextStyle(color: textColor.withOpacity(0.7))),
            Text(AppStrings.plus6Days, style: TextStyle(color: textSecondary)),
          ],
        ),
      ),
    );
  }
}


class _BiorhythmPainter extends CustomPainter {
  final List<double> phys;
  final List<double> emo;
  final List<double> ment;
  final bool isDark;
  _BiorhythmPainter(this.phys, this.emo, this.ment, this.isDark);

  @override
  void paint(Canvas canvas, Size size) {
    final axis = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.24)
      ..strokeWidth = 1;
    // midline
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), axis);

    void drawLine(List<double> vals, Color color) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      final path = Path();
      for (int i = 0; i < vals.length; i++) {
        final x = i / (vals.length - 1) * size.width;
        final y = size.height * (1 - (vals[i] + 1) / 2); // -1..1 -> 1..0
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paint);
    }

    drawLine(phys, Colors.redAccent);
    drawLine(emo, Colors.lightBlueAccent);
    drawLine(ment, Colors.amberAccent);
  }

  @override
  bool shouldRepaint(covariant _BiorhythmPainter oldDelegate) =>
      oldDelegate.phys != phys || oldDelegate.emo != emo || oldDelegate.ment != ment || oldDelegate.isDark != isDark;
}


