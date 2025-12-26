import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/widgets/mystical_card.dart';
import '../../core/widgets/mystical_loading.dart';
import '../../core/widgets/image_viewer.dart';
import '../../core/models/fortune_model.dart' as fm;
import 'fortune_result_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/theme_provider.dart';

class DreamDrawScreen extends StatefulWidget {
  final String? initialPrompt;
  const DreamDrawScreen({super.key, this.initialPrompt});

  @override
  State<DreamDrawScreen> createState() => _DreamDrawScreenState();
}

class _DreamDrawScreenState extends State<DreamDrawScreen> {
  final TextEditingController _promptController = TextEditingController();
  final AIService _ai = AIService();
  final ScrollController _scrollController = ScrollController();

  String _style = AppStrings.dreamDrawStyles.first;
  bool _isLoading = false;
  Uint8List? _imageBytes;
  String? _error;
  final FirebaseService _firebase = FirebaseService();

  @override
  void initState() {
    super.initState();
    if (widget.initialPrompt != null && widget.initialPrompt!.trim().isNotEmpty) {
      _promptController.text = widget.initialPrompt!.trim();
    }
  }

  Future<void> _generate() async {
    final base = _promptController.text.trim();
    if (base.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.youMustWriteDream)),
      );
      return;
    }

    // Quick connectivity check to avoid DNS errors on emulator/devices
    try {
      final res = await InternetAddress.lookup('api.openai.com');
      if (res.isEmpty || res.first.rawAddress.isEmpty) {
        throw const SocketException('No DNS result');
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.noInternetConnection),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final prompt = AppStrings.dreamVisualizePrompt
        .replaceAll('{0}', base)
        .replaceAll('{1}', _style);

    setState(() {
      _isLoading = true;
      _error = null;
      _imageBytes = null;
    });

    try {
      MysticLoading.show(context);
      final bytes = await _ai.generateMysticImage(
        prompt: prompt,
        width: 1024,
        height: 1024,
      );
      if (!mounted) return;
      setState(() {
        _imageBytes = bytes;
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

      // Upload image to Storage and save to readings collection
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        if (!mounted) return;
        await MysticLoading.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.userLoginRequired), backgroundColor: Colors.red),
        );
        return;
      }

      // Upload image to Firebase Storage
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final imagePath = 'dream_draws/${userId}/${timestamp}.jpg';
      final imageUrl = await _firebase.uploadImage(imagePath, bytes);
      
      if (imageUrl == null) {
        if (!mounted) return;
        await MysticLoading.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.imageCouldNotBeUploaded), backgroundColor: Colors.red),
        );
        return;
      }

      // Save to readings collection as a fortune result
      final docRef = FirebaseFirestore.instance.collection('readings').doc();
      final fortuneData = {
        'userId': userId,
        'type': 'dream',
        'title': AppStrings.dreamDrawing,
        'interpretation': '${AppStrings.dreamVisualized}: $base',
        'imageUrls': [imageUrl],
        'createdAt': FieldValue.serverTimestamp(),
        'rating': 0.0,
        'isFavorite': false,
        'metadata': {
          'source': 'dream_draw',
          'prompt': base,
          'style': _style,
          'availableAt': DateTime.now().add(Duration(minutes: 15 + (DateTime.now().millisecond % 11))).toIso8601String(),
          'waitMinutes': 15 + (DateTime.now().millisecond % 11),
        },
      };
      await docRef.set(fortuneData);

      // Create FortuneModel and navigate to result screen
      final adapted = fm.FortuneModel(
        id: docRef.id,
        userId: userId,
        type: fm.FortuneType.dream,
        status: fm.FortuneStatus.completed,
        title: AppStrings.dreamDrawing,
        interpretation: '${AppStrings.isEnglish ? "Your dream has been visualized" : "Rüyanız görselleştirildi"}: $base',
        imageUrls: [imageUrl],
        createdAt: DateTime.now(),
        completedAt: DateTime.now(),
        isFavorite: false,
        rating: 0,
        metadata: {
          'source': 'dream_draw',
          'prompt': base,
          'style': _style,
        },
      );

      if (!mounted) return;
      await MysticLoading.hide(context);
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FortuneResultScreen(fortune: adapted),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '${AppStrings.imageCouldNotBeGenerated} $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_error!), backgroundColor: AppColors.error),
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
                    children: [
                      _buildPromptCard(),
                      const SizedBox(height: 16),
                      _buildStyleCard(),
                      const SizedBox(height: 20),
                      if (_isLoading)
                        MysticalCard(
                          toggleFlipOnTap: false,
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Center(
                              child: MysticalLoading(
                                type: MysticalLoadingType.spinner,
                                size: 32,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      if (_error != null)
                        MysticalCard(
                          toggleFlipOnTap: false,
                          child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(_error!, style: AppTextStyles.bodyMedium.copyWith(color: Colors.redAccent)),
                          ),
                        ),
                      if (_imageBytes != null) ...[
                        const SizedBox(height: 20),
                        _buildImageResultCard(),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: _buildGenerateButton(),
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
          Text(AppStrings.drawMyDreamTitle, style: AppTextStyles.headingLarge.copyWith(color: textColor)),
          const Spacer(),
          const Text('🎨', style: TextStyle(fontSize: 24)),
        ],
      ),
    );
  }

  Widget _buildPromptCard() => Consumer<ThemeProvider>(
    builder: (context, themeProvider, child) {
      final isDark = themeProvider.isDarkMode;
      final inputTextColor = AppColors.getInputTextColor(isDark);
      final inputHintColor = AppColors.getInputHintColor(isDark);
      final inputBorderColor = AppColors.getInputBorderColor(isDark);
      final textColor = AppColors.getTextPrimary(isDark);
      final cardBg = AppColors.getCardBackground(isDark);
      
      return MysticalCard(
        showGlow: false,
        enforceAspectRatio: false,
        toggleFlipOnTap: false,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.secondary.withValues(alpha: isDark ? 0.25 : 0.2),
                cardBg.withValues(alpha: isDark ? 0.9 : 0.85),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
              Text(
                AppStrings.describeYourDream,
                style: AppTextStyles.headingSmall.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
          TextField(
            controller: _promptController,
                style: AppTextStyles.bodyMedium.copyWith(color: inputTextColor),
            decoration: InputDecoration(
              hintText: AppStrings.dreamDrawExampleHint,
                  hintStyle: AppTextStyles.bodyMedium.copyWith(color: inputHintColor),
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
              contentPadding: const EdgeInsets.all(12),
                  filled: true,
                  fillColor: isDark 
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.white.withValues(alpha: 0.3),
            ),
            maxLines: 5,
            minLines: 3,
          ),
        ],
      ),
    ),
  );
    },
  );

  Widget _buildStyleCard() => Consumer<ThemeProvider>(
    builder: (context, themeProvider, child) {
      final isDark = themeProvider.isDarkMode;
      final textColor = AppColors.getTextPrimary(isDark);
      final cardBg = AppColors.getCardBackground(isDark);
      
      return MysticalCard(
        showGlow: false,
        enforceAspectRatio: false,
        toggleFlipOnTap: false,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    child: Container(
      width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.secondary.withValues(alpha: isDark ? 0.25 : 0.2),
                cardBg.withValues(alpha: isDark ? 0.9 : 0.85),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
              Text(
                AppStrings.selectStyle,
                style: AppTextStyles.headingSmall.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
          _buildStyleChips(),
        ],
      ),
    ),
      );
    },
  );

  Widget _buildImageResultCard() => MysticalCard(
    aspectRatio: 1,
    toggleFlipOnTap: false,
    onTap: () => ImageViewer.show(
      context: context,
      imageBytes: _imageBytes,
      title: AppStrings.dreamDrawing,
    ),
    padding: EdgeInsets.zero,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.memory(_imageBytes!, fit: BoxFit.cover),
    ),
  );

  Widget _buildStyleChips() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        final textColor = AppColors.getTextPrimary(isDark);
        
    final styles = AppStrings.dreamDrawStyles;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: styles.map((s) {
        final selected = s == _style;
        return ChoiceChip(
          label: Text(
            s,
            style: AppTextStyles.bodySmall.copyWith(
                  color: selected 
                      ? Colors.black
                      : textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          selected: selected,
          onSelected: (v) {
            if (v) setState(() => _style = s);
          },
          selectedColor: Colors.white,
              backgroundColor: isDark 
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
              shape: StadiumBorder(
                side: BorderSide(
                  color: isDark ? Colors.white24 : Colors.black.withValues(alpha: 0.2),
                ),
              ),
        );
      }).toList(),
        );
      },
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _generate,
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
          _isLoading ? AppStrings.drawing : AppStrings.drawMyDreamButton,
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

