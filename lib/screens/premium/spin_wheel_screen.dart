import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/ads_service.dart';
import '../../core/providers/user_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/pricing_constants.dart';
import '../../core/widgets/mystical_button.dart';
import '../../providers/theme_provider.dart';

class SpinWheelScreen extends StatefulWidget {
  const SpinWheelScreen({super.key});

  @override
  State<SpinWheelScreen> createState() => _SpinWheelScreenState();
}

class _SpinWheelScreenState extends State<SpinWheelScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _rotation;
  bool _spinning = false;
  String? _resultText;
  final AdsService _adsService = AdsService();
  final FirebaseService _firebase = FirebaseService();
  bool _canSpinWithAd = false;
  bool _canUse2xReward = false;
  Map<String, dynamic>? _lastReward;
  bool _rewardDoubled = false;

  // Get rewards from pricing constants, weighted by probability
  List<Map<String, dynamic>> get _rewards {
    final List<Map<String, dynamic>> rewards = [];
    for (var reward in PricingConstants.spinWheelRewards) {
      rewards.add({
        'type': 'karma',
        'amount': reward['karma'] as int,
        'label': reward['label'] as String,
        'probability': reward['probability'] as double,
      });
    }
    return rewards;
  }
  
  // Select a reward based on probability
  Map<String, dynamic> _selectRewardByProbability() {
    final rnd = math.Random.secure();
    final randomValue = rnd.nextDouble();
    double cumulative = 0.0;
    
    for (var reward in _rewards) {
      cumulative += reward['probability'] as double;
      if (randomValue <= cumulative) {
        return reward;
      }
    }
    // Fallback to first reward (shouldn't happen)
    return _rewards[0];
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    // Initialize with zero rotation to avoid LateInitializationError before first spin
    _rotation = Tween<double>(begin: 0, end: 0).animate(_controller);
    _checkSpinAvailability();
  }

  Future<void> _checkSpinAvailability() async {
    final user = _firebase.currentUser;
    if (user == null) return;
    
    final canFreeSpin = await _firebase.canSpin(user.uid);
    final canSpinWithAd = await _firebase.canSpinWithAd(user.uid);
    final canUse2x = await _firebase.canUse2xReward(user.uid);
    
    if (mounted) {
      setState(() {
        // Show ad spin button if free spin was used today (not available) and ad spin is available
        _canSpinWithAd = !canFreeSpin && canSpinWithAd;
        _canUse2xReward = canUse2x;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _spin() async {
    if (_spinning) return;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final firebase = FirebaseService();
    final user = firebase.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.sessionNotFound)),
      );
      return;
    }

    final can = await firebase.canSpin(user.uid);
    if (!can) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.canSpinOncePerDay)),
      );
      return;
    }

    setState(() { _spinning = true; _resultText = null; });

    final rnd = math.Random.secure();
    final turns = 4 + rnd.nextInt(4); // 4-7 tur
    final selectedReward = _selectRewardByProbability();
    final index = _rewards.indexWhere((r) => r['label'] == selectedReward['label']);
    final slice = 2 * math.pi / _rewards.length;
    // Align chosen slice center to the top pointer (top = -pi/2). Transform.rotate uses clockwise +angle.
    // To bring a slice originally at centerAngle to top, rotate by: turns*2π - (centerAngle + π/2)
    final centerAngle = (index * slice) + slice / 2;
    final targetAngle = (turns * 2 * math.pi) - (centerAngle + math.pi / 2);

    _rotation = Tween<double>(begin: 0, end: turns * 2 * math.pi + targetAngle)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    await _controller.forward(from: 0);

    final reward = selectedReward;

    // apply reward
    final rewardAmount = reward['amount'] as int;
    if (reward['type'] == 'karma') {
      await userProvider.addKarma(rewardAmount, 'spin');
    }
    await firebase.recordSpin(user.uid, reward, isAdSpin: false);

    setState(() {
      _spinning = false;
      _resultText = reward['label'] as String;
      _lastReward = reward;
      _rewardDoubled = false;
    });
    
    // Refresh availability
    await _checkSpinAvailability();
  }

  Future<void> _spinWithAd() async {
    if (_spinning) return;
    final user = _firebase.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.sessionNotFound)),
      );
      return;
    }

    final can = await _firebase.canSpinWithAd(user.uid);
    if (!can) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.dailyExtraSpinUsed)),
      );
      return;
    }

    // Show rewarded ad
    final reward = await _showRewardedAd();
    if (reward == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.adNotWatchedExtraSpin)),
      );
      return;
    }

    // Perform spin with ad
    setState(() { _spinning = true; _resultText = null; });

    final rnd = math.Random.secure();
    final turns = 4 + rnd.nextInt(4);
    final selectedReward = _selectRewardByProbability();
    final index = _rewards.indexWhere((r) => r['label'] == selectedReward['label']);
    final slice = 2 * math.pi / _rewards.length;
    final centerAngle = (index * slice) + slice / 2;
    final targetAngle = (turns * 2 * math.pi) - (centerAngle + math.pi / 2);

    _rotation = Tween<double>(begin: 0, end: turns * 2 * math.pi + targetAngle)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    await _controller.forward(from: 0);

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final rewardAmount = selectedReward['amount'] as int;
    if (selectedReward['type'] == 'karma') {
      await userProvider.addKarma(rewardAmount, 'spin (ad)');
    }
    await _firebase.recordSpin(user.uid, selectedReward, isAdSpin: true);

    setState(() {
      _spinning = false;
      _resultText = selectedReward['label'] as String;
      _lastReward = selectedReward;
      _rewardDoubled = false;
      _canSpinWithAd = false; // Ad spin kullanıldı, artık gösterilmesin
    });

    await _checkSpinAvailability();
  }

  Future<void> _doubleRewardWithAd() async {
    if (_lastReward == null) return;

    final user = _firebase.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.sessionNotFound)),
      );
      return;
    }

    final can = await _firebase.canUse2xReward(user.uid);
    if (!can) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.daily2xRewardUsed)),
      );
      return;
    }

    // Show rewarded ad
    final reward = await _showRewardedAd();
    if (reward == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.adNotWatched2xReward)),
      );
      return;
    }

    // Double the reward
    final doubledReward = Map<String, dynamic>.from(_lastReward!);
    final originalAmount = doubledReward['amount'] as int;
    final extraAmount = originalAmount; // Ekstra karma miktarı (zaten originalAmount kazanılmış, şimdi bir tane daha)
    doubledReward['amount'] = originalAmount * 2;
    doubledReward['label'] = '2x ${_lastReward!['label']}';

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (doubledReward['type'] == 'karma') {
      // Kullanıcı zaten originalAmount karma kazandı, şimdi ekstra originalAmount daha ekliyoruz (toplam 2x)
      await userProvider.addKarma(extraAmount, 'spin (2x reward)');
      
      // Karma ekleme işleminin başarılı olduğunu kontrol et
      final currentKarma = userProvider.user?.karma ?? 0;
      print('2x Reward: Added $extraAmount karma. New total: $currentKarma');
    }
    
    await _firebase.recordSpin(user.uid, doubledReward, doubledReward: true);

    setState(() {
      _resultText = doubledReward['label'] as String;
      _lastReward = doubledReward;
      _rewardDoubled = true;
      _canUse2xReward = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppStrings.rewardDoubled.replaceAll('{amount}', '$extraAmount')),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<RewardItem?> _showRewardedAd() async {
    try {
      final loadedCompleter = Completer<bool>();
      await _adsService.createRewardedAd(
        adUnitId: _adsService.rewardedAdUnitId,
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
        return await _adsService.showRewardedAd();
      }
      return null;
    } catch (e) {
      print('Rewarded ad error: $e');
      return null;
    }
  }

  // dynamic preview disabled for consistency; showing final target upfront

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final diameter = MediaQuery.of(context).size.width * 0.82;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(gradient: themeProvider.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
            // Removed top preview banner per request
            SizedBox(
              width: diameter,
              height: diameter + 56,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Wheel placed slightly below the badge
                  Positioned(
                    top: 40,
                    left: 0,
                    right: 0,
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (_, __) {
                        return Transform.rotate(
                          angle: _rotation.value,
                          child: _Wheel(diameter: diameter, rewards: _rewards),
                        );
                      },
                    ),
                  ),
                  // Pointer triangle
                  Positioned(
                    top: 24,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: CustomPaint(
                        size: const Size(0, 0),
                        painter: _PointerPainter(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            MysticalButton.primary(
              text: _spinning ? AppStrings.spinning : AppStrings.spin,
              icon: Icons.casino,
              onPressed: _spinning ? null : _spin,
              width: 200,
            ),
            if (_resultText != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: AppColors.karmaGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      _resultText!,
                      style: AppTextStyles.headingSmall.copyWith(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    if (_lastReward != null && !_rewardDoubled && _canUse2xReward) ...[
                      const SizedBox(height: 12),
                      MysticalButton.secondary(
                        text: AppStrings.doubleReward,
                        icon: Icons.bolt,
                        onPressed: _doubleRewardWithAd,
                        width: double.infinity,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppStrings.watchAdToDoubleReward,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ],
            if (!_spinning && _canSpinWithAd) ...[
              const SizedBox(height: 16),
              MysticalButton.secondary(
                text: AppStrings.watchAdAndSpinExtra,
                icon: Icons.play_circle_outline,
                onPressed: _spinWithAd,
                width: 200,
              ),
              const SizedBox(height: 4),
              Text(
                AppStrings.daily1ExtraSpin,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white60,
                  fontSize: 11,
                ),
              ),
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
              AppStrings.spinWheel,
              style: AppTextStyles.headingLarge.copyWith(color: textColor),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          Consumer<UserProvider>(
            builder: (context, userProvider, _) {
              final karma = userProvider.user?.karma ?? 0;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppColors.karmaGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/karma/karma.png',
                      width: 16,
                      height: 16,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$karma',
                      style: AppTextStyles.bodySmall.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          const Text('🎰', style: TextStyle(fontSize: 24)),
        ],
      ),
    );
  }
}

class _Wheel extends StatelessWidget {
  final double diameter;
  final List<Map<String, dynamic>> rewards;
  const _Wheel({required this.diameter, required this.rewards});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: const [Color(0xFF1B1F3A), Color(0xFF2C2E57), Color(0xFF3E2B74)],
            stops: const [0.2, 0.6, 1.0],
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 18, offset: const Offset(0, 10)),
          ],
        ),
        child: CustomPaint(
          painter: _WheelPainter(rewards: rewards),
        ),
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  final List<Map<String, dynamic>> rewards;
  _WheelPainter({required this.rewards});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final slice = 2 * math.pi / rewards.length;
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < rewards.length; i++) {
      paint.shader = SweepGradient(
        startAngle: i * slice,
        endAngle: (i + 1) * slice,
        colors: i.isEven
            ? const [Color(0xFF8E2DE2), Color(0xFF4A00E0)]
            : const [Color(0xFF00C6FF), Color(0xFF0072FF)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
      final start = i * slice;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start, slice, true, paint);

      // Draw reward label on slice
      final mid = start + slice / 2;
      final label = (rewards[i]['label'] ?? '').toString();
      if (label.isNotEmpty) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              shadows: [Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 1))],
            ),
          ),
          textDirection: TextDirection.ltr,
          maxLines: 1,
          ellipsis: '…',
        )..layout(maxWidth: radius * 0.9);

        final r = radius * 0.62; // distance from center
        final dx = center.dx + r * math.cos(mid) - textPainter.width / 2;
        final dy = center.dy + r * math.sin(mid) - textPainter.height / 2;
        textPainter.paint(canvas, Offset(dx, dy));
      }
    }

    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.white70;
    canvas.drawCircle(center, radius, border);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


class _PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final path = Path();
    // Draw a small downward triangle pointer
    path.moveTo(0, 0);
    path.addPolygon([
      const Offset(-12, 0),
      const Offset(12, 0),
      const Offset(0, 18),
    ], true);
    canvas.drawPath(path, paint);
    // Inner accent
    final accent = Paint()..color = Colors.deepPurpleAccent;
    final inner = Path()
      ..addPolygon([
        const Offset(-6, 2),
        const Offset(6, 2),
        const Offset(0, 12),
      ], true);
    canvas.drawPath(inner, accent);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


