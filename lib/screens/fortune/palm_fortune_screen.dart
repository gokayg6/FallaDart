import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
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

class PalmFortuneScreen extends StatefulWidget {
  const PalmFortuneScreen({Key? key}) : super(key: key);

  @override
  State<PalmFortuneScreen> createState() => _PalmFortuneScreenState();
}

class _PalmFortuneScreenState extends State<PalmFortuneScreen> {
  final FortuneService _fortuneService = FortuneService();
  final ImagePicker _picker = ImagePicker();
  final AdsService _ads = AdsService();

  File? _leftPalm;
  File? _rightPalm;
  String? _question;

  bool get _canGenerate => _leftPalm != null || _rightPalm != null;

  Future<void> _pickImage(bool isLeft) async {
    if (!mounted) return;
    
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.premiumDarkBg.withOpacity(0.95),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: GlassButton(
                        text: AppStrings.gallery,
                        icon: Icons.photo_library,
                        onPressed: () => Navigator.pop(context, ImageSource.gallery),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GlassButton(
                        text: AppStrings.camera,
                        icon: Icons.camera_alt,
                        onPressed: () => Navigator.pop(context, ImageSource.camera),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    
    if (source == null || !mounted) return;
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    await _pickImageFrom(isLeft, source);
  }

  Future<void> _pickImageFrom(bool isLeft, ImageSource source) async {
    if (!mounted) return;
    
    try {
      final XFile? shot = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
      );
      
      if (mounted && shot != null) {
        await Future.delayed(const Duration(milliseconds: 150));
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              if (isLeft) {
                _leftPalm = File(shot.path);
              } else {
                _rightPalm = File(shot.path);
              }
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 150));
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showError('${AppStrings.imageCaptureError} $e');
          }
        });
      }
    }
  }

  Future<void> _generate() async {
    if (!_canGenerate) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final requiredKarma = PricingConstants.getFortuneCost('palm');
    
    if (!kDebugMode) {
      if (!(userProvider.user?.canUseDailyFortune ?? false)) {
        if ((userProvider.user?.karma ?? 0) < requiredKarma) {
          _showError('${AppStrings.notEnoughKarma}. Gerekli: $requiredKarma karma');
          return;
        }
        
        final karmaSpent = await userProvider.spendKarma(requiredKarma, 'El Falı');
        if (!karmaSpent) {
          _showError('${AppStrings.notEnoughKarma}. Gerekli: $requiredKarma karma');
          return;
        }
      }
    }

    try {
      MysticLoading.show(context);
      final images = <File>[];
      if (_leftPalm != null) images.add(_leftPalm!);
      if (_rightPalm != null) images.add(_rightPalm!);

      final urls = await _fortuneService.uploadImages(images);

      final result = await _fortuneService.generateFortune(
        type: FortuneType.palm,
        inputData: {
          'palmImageUrl': urls.isNotEmpty ? urls.first : '',
          'extraImages': urls,
        },
        question: _question,
      );

      final fm.FortuneModel adapted = fm.FortuneModel(
        id: result.id,
        userId: result.userId,
        type: fm.FortuneType.palm,
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
        try { ok = await loaded.future.timeout(const Duration(seconds: 2)); } catch (_) {}
        if (ok) { await _ads.showInterstitialAd(); }
      } catch (_) {}

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => FortuneResultScreen(fortune: adapted)),
      );
    } catch (e) {
      if (!mounted) return;
      await MysticLoading.hide(context);
      _showError('${AppStrings.palmFortuneCreationError}: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
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
                    _buildInstructionsSection(),
                    const SizedBox(height: 16),
                    _buildQuestionInput(),
                    const SizedBox(height: 16),
                    _buildPickerRow(),
                    const SizedBox(height: 100),
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
                        'assets/icons/palm.png',
                        width: 28, height: 28,
                        errorBuilder: (_,__,___) => Icon(Icons.back_hand, color: AppColors.champagneGold, size: 22),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.palmFortune,
                            style: TextStyle(
                              fontFamily: 'SF Pro Display',
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.warmIvory,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            'El Çizgilerinin Gizemi',
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
              const KarmaCostBadge(fortuneType: 'palm'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntroCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
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
              color: AppColors.champagneGold.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.champagneGold.withOpacity(0.15),
                blurRadius: 20,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            children: [
              // Animated Palm Icon
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.champagneGold.withOpacity(0.4),
                      AppColors.champagneGold.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.champagneGold.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(Icons.back_hand, color: AppColors.champagneGold, size: 32),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.isEnglish ? 'Secrets of Your Palm Lines' : 'El Çizgilerinin Sırları',
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.champagneGold,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                AppStrings.isEnglish
                    ? 'Upload clear photos of your palm. AI will analyze your life line, heart line and fate line.'
                    : 'Avuç içinizin net fotoğraflarını yükleyin. Yapay zeka yaşam çizgisi, kalp çizgisi ve kader çizginizi analiz edecek.',
                style: TextStyle(
                  fontFamily: 'SF Pro Text',
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.white.withOpacity(0.65),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionsSection() {
    final instructions = [
      {'icon': '✋', 'title': AppStrings.isEnglish ? 'Open Your Palm' : 'Elinizi Açın', 'desc': AppStrings.isEnglish ? 'Spread your fingers and open your palm naturally' : 'Parmaklarınızı açın ve avucunuzu doğal şekilde tutun'},
      {'icon': '💡', 'title': AppStrings.isEnglish ? 'Good Lighting' : 'İyi Aydınlatma', 'desc': AppStrings.isEnglish ? 'Make sure palm lines are clearly visible' : 'Avuç çizgilerininizin net görünmesini sağlayın'},
      {'icon': '📸', 'title': AppStrings.isEnglish ? 'Take Photo' : 'Fotoğraf Çekin', 'desc': AppStrings.isEnglish ? 'Capture from directly above, keep the camera steady' : 'Tam üstten çekin, kamerayı sabit tutun'},
    ];
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.08),
                Colors.white.withOpacity(0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.champagneGold.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.lightbulb_outline, color: AppColors.champagneGold, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppStrings.isEnglish ? 'How to Take Photos?' : 'Nasıl Fotoğraf Çekilir?',
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.warmIvory,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...instructions.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Padding(
                  padding: EdgeInsets.only(bottom: index < instructions.length - 1 ? 12 : 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.champagneGold.withOpacity(0.3),
                              AppColors.champagneGold.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(item['icon']!, style: TextStyle(fontSize: 18)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title']!,
                              style: TextStyle(
                                fontFamily: 'SF Pro Text',
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.warmIvory,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item['desc']!,
                              style: TextStyle(
                                fontFamily: 'SF Pro Text',
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.6),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
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
                  hintText: AppStrings.exampleCareer,
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

  Widget _buildPickerRow() {
    return Row(
      children: [
        Expanded(child: _buildPalmPicker(AppStrings.leftPalm, true, _leftPalm)),
        const SizedBox(width: 12),
        Expanded(child: _buildPalmPicker(AppStrings.rightPalm, false, _rightPalm)),
      ],
    );
  }

  Widget _buildPalmPicker(String label, bool isLeft, File? image) {
    return GestureDetector(
      onTap: () => _pickImage(isLeft),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: AspectRatio(
            aspectRatio: 0.75,
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColors.premiumGlassGradient,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.premiumGlassBorder, width: 1),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (image != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.file(image, fit: BoxFit.cover),
                    )
                  else
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.pan_tool_rounded, color: AppColors.champagneGold, size: 36),
                          const SizedBox(height: 8),
                          Text(label, style: PremiumTextStyles.body),
                        ],
                      ),
                    ),
                  if (image != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          setState(() { if (isLeft) _leftPalm = null; else _rightPalm = null; });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.all(6),
                          child: const Icon(Icons.close, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenerateBar() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final requiredKarma = PricingConstants.getFortuneCost('palm');
        final canUseFortune = kDebugMode || 
                             (userProvider.user?.canUseDailyFortune ?? false) || 
                             (userProvider.user?.karma ?? 0) >= requiredKarma;
        final canGenerate = _canGenerate && canUseFortune;
        
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
                text: _canGenerate ? AppStrings.createFortune : AppStrings.takePalmPhoto,
                icon: Icons.auto_awesome,
                onPressed: canGenerate ? _generate : null,
                width: double.infinity,
              ),
            ),
          ),
        );
      },
    );
  }
}
