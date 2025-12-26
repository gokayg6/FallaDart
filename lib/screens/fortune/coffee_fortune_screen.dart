import 'dart:io';
import 'dart:async';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/glassmorphism_components.dart';
import '../../providers/theme_provider.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/pricing_constants.dart';
import '../../core/models/fortune_type.dart';
import '../../core/models/fortune_model.dart' as fm;
import '../../core/services/fortune_service.dart';
import '../../core/services/firebase_service.dart';
import '../../core/widgets/mystical_loading.dart';
import '../../core/services/ads_service.dart';
import '../../core/providers/user_provider.dart';
import 'fortune_result_screen.dart';
import '../../widgets/fortune/karma_cost_badge.dart';

class CoffeeFortuneScreen extends StatefulWidget {
  final String? question;

  const CoffeeFortuneScreen({Key? key, this.question}) : super(key: key);

  @override
  State<CoffeeFortuneScreen> createState() => _CoffeeFortuneScreenState();
}

class _CoffeeFortuneScreenState extends State<CoffeeFortuneScreen>
    with TickerProviderStateMixin {
  final FortuneService _fortuneService = FortuneService();
  final ImagePicker _imagePicker = ImagePicker();
  final AdsService _ads = AdsService();
  
  late AnimationController _floatController;
  late AnimationController _glowController;

  List<File> _selectedImages = [];
  String? _question;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images.map((xFile) => File(xFile.path)));
        });
      }
    } catch (e) {
      _showError('${AppStrings.photoSelectionError} $e');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
        });
      }
    } catch (e) {
      _showError('${AppStrings.photoCaptureError} $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _generateFortune() async {
    if (_selectedImages.isEmpty) {
      _showError(AppStrings.pleaseSelectAtLeastOnePhoto);
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final requiredKarma = PricingConstants.getFortuneCost('coffee');
    
    if (!kDebugMode) {
      if (!(userProvider.user?.canUseDailyFortune ?? false)) {
        if ((userProvider.user?.karma ?? 0) < requiredKarma) {
          _showError('${AppStrings.notEnoughKarma}. Gerekli: $requiredKarma karma');
          return;
        }
        final karmaSpent = await userProvider.spendKarma(requiredKarma, AppStrings.coffeeFortune);
        if (!karmaSpent) {
          _showError('${AppStrings.notEnoughKarma}. Gerekli: $requiredKarma karma');
          return;
        }
      }
    }

    try {
      MysticLoading.show(context);
      final imageUrls = await _fortuneService.uploadImages(_selectedImages);
      
      final result = await _fortuneService.generateFortune(
        type: FortuneType.coffee,
        inputData: {'imageUrls': imageUrls},
        question: _question,
      );

      final fm.FortuneModel adapted = fm.FortuneModel(
        id: result.id,
        userId: result.userId,
        type: fm.FortuneType.coffee,
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

      // Show interstitial ad
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

      // Record quest completion
      try {
        final firebaseService = FirebaseService();
        final userId = userProvider.user?.id;
        if (userId != null) {
          final completedQuests = await firebaseService.getCompletedQuests(userId);
          if (!completedQuests.contains('coffee_fortune')) {
            await firebaseService.recordQuestCompletion(userId, 'coffee_fortune');
            await userProvider.addKarma(5, 'Kahve falı görevi');
          }
        }
      } catch (_) {}

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => FortuneResultScreen(fortune: adapted)),
      );
    } catch (e) {
      if (!mounted) return;
      await MysticLoading.hide(context);
      _showError('${AppStrings.fortuneCreationError}: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: BoxDecoration(
              gradient: themeProvider.backgroundGradient,
            ),
            child: Stack(
              children: [
                // Animated background particles (only in dark mode for performance)
                if (isDark)
                  ...List.generate(15, (index) => _buildFloatingParticle(index, isDark)),
                
                // Main content
                SafeArea(
                  child: Column(
                    children: [
                      _buildLiquidGlassHeader(isDark),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              _buildHeroSection(isDark),
                              const SizedBox(height: 24),
                              _buildImageUploadSection(isDark),
                              const SizedBox(height: 24),
                              _buildQuestionSection(isDark),
                              const SizedBox(height: 24),
                              _buildInstructionsSection(isDark),
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ),
                      _buildActionBar(isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingParticle(int index, bool isDark) {
    final random = math.Random(index);
    final size = 2.0 + random.nextDouble() * 4;
    final left = random.nextDouble() * MediaQuery.of(context).size.width;
    final top = random.nextDouble() * MediaQuery.of(context).size.height;
    final delay = random.nextDouble();
    
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        final value = math.sin((_floatController.value + delay) * math.pi * 2);
        return Positioned(
          left: left,
          top: top + value * 20,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (isDark ? AppColors.mysticPurpleAccent : AppColors.primary).withOpacity(0.15 + value.abs() * 0.1),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? AppColors.mysticPurpleAccent : AppColors.primary).withOpacity(0.2),
                  blurRadius: size * 2,
                  spreadRadius: size / 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLiquidGlassHeader(bool isDark) {
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
              // Back button with glass effect
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
                    color: AppColors.getTextPrimary(isDark),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Title with coffee cup icon
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
                      child: Text('☕', style: TextStyle(fontSize: 22)),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.coffeeFortune,
                          style: TextStyle(
                            fontFamily: 'SF Pro Display',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.getTextPrimary(isDark),
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'Fincanınızın sırları',
                          style: TextStyle(
                            fontFamily: 'SF Pro Text',
                            fontSize: 12,
                            color: AppColors.getTextSecondary(isDark),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const KarmaCostBadge(fortuneType: 'coffee'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(bool isDark) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        final glowIntensity = 0.3 + _glowController.value * 0.2;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.08),
                Colors.white.withOpacity(0.03),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.champagneGold.withOpacity(glowIntensity),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.champagneGold.withOpacity(glowIntensity * 0.3),
                blurRadius: 30,
                spreadRadius: 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Column(
                children: [
                  // Animated coffee cup
                  AnimatedBuilder(
                    animation: _floatController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, math.sin(_floatController.value * math.pi) * 5),
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.champagneGold.withOpacity(0.4),
                                AppColors.champagneGold.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.champagneGold.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text('☕', style: TextStyle(fontSize: 40)),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Fincanınızın Gizli Mesajları',
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.champagneGold,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Kahve fincanınızın fotoğraflarını yükleyin ve yapay zeka destekli mistik yorumlarınızı keşfedin.',
                    style: TextStyle(
                      fontFamily: 'SF Pro Text',
                      fontSize: 14,
                      height: 1.6,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageUploadSection(bool isDark) {
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
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
            ),
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
                    child: Icon(Icons.photo_camera, color: AppColors.champagneGold, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppStrings.coffeePhotos,
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
              
              // Upload buttons
              Row(
                children: [
                  Expanded(child: _buildUploadButton(Icons.photo_library_rounded, 'Galeri', _pickImages)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildUploadButton(Icons.camera_alt_rounded, 'Kamera', _takePhoto)),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Selected images grid or placeholder
              _selectedImages.isEmpty
                  ? _buildEmptyImagePlaceholder()
                  : _buildSelectedImagesGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.champagneGold.withOpacity(0.25),
              AppColors.champagneGold.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.champagneGold.withOpacity(0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.champagneGold.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.champagneGold, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'SF Pro Text',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.champagneGold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyImagePlaceholder() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.05),
            Colors.white.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              color: Colors.white.withOpacity(0.3),
              size: 40,
            ),
            const SizedBox(height: 10),
            Text(
              AppStrings.noPhotoSelected,
              style: TextStyle(
                fontFamily: 'SF Pro Text',
                color: Colors.white.withOpacity(0.4),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedImagesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _selectedImages.length,
      itemBuilder: (context, index) {
        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.champagneGold.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _selectedImages[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _removeImage(index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.black.withOpacity(0.6),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuestionSection(bool isDark) {
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
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
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
                    child: Icon(Icons.help_outline, color: AppColors.champagneGold, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Sorunuz (İsteğe Bağlı)',
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
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.08),
                      Colors.white.withOpacity(0.04),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: TextField(
                  onChanged: (v) => setState(() => _question = v.trim().isEmpty ? null : v.trim()),
                  style: TextStyle(
                    fontFamily: 'SF Pro Text',
                    color: AppColors.warmIvory,
                    fontSize: 15,
                  ),
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Falınızda öğrenmek istediğiniz bir konu var mı?',
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.35),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionsSection(bool isDark) {
    final instructions = [
      {'icon': '☕', 'title': 'Fincanı Çevirin', 'desc': 'Kahveyi içtikten sonra fincanı tabağın üzerine kapatın'},
      {'icon': '⏳', 'title': 'Bekleyin', 'desc': 'Telvesinin kuruyup şekillenmesi için birkaç dakika bekleyin'},
      {'icon': '📸', 'title': 'Fotoğraf Çekin', 'desc': 'Fincanın içini farklı açılardan net bir şekilde çekin'},
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
                    'Nasıl Hazırlanır?',
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

  Widget _buildActionBar(bool isDark) {
    final hasImages = _selectedImages.isNotEmpty;
    
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
              top: BorderSide(
                color: AppColors.champagneGold.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          child: Consumer<UserProvider>(
            builder: (context, userProvider, child) {
              final requiredKarma = PricingConstants.getFortuneCost('coffee');
              final canUseFortune = kDebugMode || 
                                   (userProvider.user?.canUseDailyFortune ?? false) || 
                                   (userProvider.user?.karma ?? 0) >= requiredKarma;
              final canGenerate = hasImages && canUseFortune;
              
              return GestureDetector(
                onTap: canGenerate ? _generateFortune : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: canGenerate
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.champagneGold,
                              AppColors.champagneGold.withOpacity(0.8),
                            ],
                          )
                        : LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.1),
                              Colors.white.withOpacity(0.05),
                            ],
                          ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: canGenerate
                          ? AppColors.champagneGold.withOpacity(0.5)
                          : Colors.white.withOpacity(0.1),
                    ),
                    boxShadow: canGenerate
                        ? [
                            BoxShadow(
                              color: AppColors.champagneGold.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        hasImages ? Icons.auto_awesome : Icons.add_photo_alternate,
                        color: canGenerate ? Colors.black87 : Colors.white.withOpacity(0.4),
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        hasImages ? AppStrings.createFortune : AppStrings.uploadPhotos,
                        style: TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: canGenerate ? Colors.black87 : Colors.white.withOpacity(0.4),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
