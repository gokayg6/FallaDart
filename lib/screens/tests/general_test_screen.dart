import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/pricing_constants.dart';
import '../../core/models/quiz_test_model.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/firebase_service.dart';
import '../../core/providers/user_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../core/widgets/mystical_loading.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/fortune/karma_cost_badge.dart';
import '../../core/services/ads_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'test_result_screen.dart';

class GeneralTestScreen extends StatefulWidget {
  final QuizTestDefinition testDefinition;

  const GeneralTestScreen({
    Key? key,
    required this.testDefinition,
  }) : super(key: key);

  @override
  State<GeneralTestScreen> createState() => _GeneralTestScreenState();
}

class _GeneralTestScreenState extends State<GeneralTestScreen> {
  final PageController _pageController = PageController();
  final AdsService _ads = AdsService();
  int _currentPage = 0;
  Map<String, dynamic> _formData = {};
  Map<String, String> _answers = {};
  bool _isSubmitting = false;
  bool _adShownOnEntry = false;
  
  @override
  void initState() {
    super.initState();
    // İlk girişte reklam göster
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showInterstitialAdOnEntry();
    });
  }

  @override
  void dispose() {
    // Çıkışta reklam göster
    _showInterstitialAdOnExit();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _showInterstitialAdOnEntry() async {
    if (_adShownOnEntry) return;
    _adShownOnEntry = true;
    
    await _ads.createInterstitialAd(
      adUnitId: _ads.interstitialAdUnitId,
      onAdLoaded: (ad) {
        ad.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose();
            _ads.createInterstitialAd(
              adUnitId: _ads.interstitialAdUnitId,
            );
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            ad.dispose();
          },
        );
        ad.show();
      },
      onAdFailedToLoad: (error) {
        if (kDebugMode) {
          print('❌ Interstitial ad failed to load on entry: $error');
        }
      },
    );
  }

  Future<void> _showInterstitialAdOnExit() async {
    await _ads.createInterstitialAd(
      adUnitId: _ads.interstitialAdUnitId,
      onAdLoaded: (ad) {
        ad.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose();
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            ad.dispose();
          },
        );
        ad.show();
      },
      onAdFailedToLoad: (error) {
        if (kDebugMode) {
          print('❌ Interstitial ad failed to load on exit: $error');
        }
      },
    );
  }

  Future<bool> _checkKarmaAvailability() async {
    // Debug modunda karma kontrolü bypass
    if (kDebugMode) {
      return true;
    }
    
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final requiredKarma = PricingConstants.testCost;
    
    if (userProvider.user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.userNotLoggedIn),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return false;
    }
    
    if (userProvider.user!.karma < requiredKarma) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.notEnoughKarma}. Gerekli: $requiredKarma ${AppStrings.karma}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return false;
    }
    
    return true;
  }

  void _nextPage() {
    if (!_canProceed()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.pleaseAnswerAllQuestions),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_currentPage < widget.testDefinition.sections.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Son sayfada tamamla butonuna basıldı
      _submitTest();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  bool _canProceed() {
    final section = widget.testDefinition.sections[_currentPage];
    
    if (section.type == QuizSectionType.form) {
      // Tüm required alanlar doldurulmuş mu kontrol et
      for (final field in section.fields) {
        if (field.required && (_formData[field.id] == null || _formData[field.id] == '')) {
          return false;
        }
      }
    } else if (section.type == QuizSectionType.question) {
      // Tüm sorular cevaplanmış mı kontrol et
      for (final question in section.questions) {
        if (_answers[question.id] == null) {
          return false;
        }
      }
    }
    
    return true;
  }

  Future<void> _submitTest() async {
    if (!_canProceed()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.pleaseAnswerAllQuestions),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Loading dialog göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: Colors.transparent,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MysticalLoading(
                type: MysticalLoadingType.stars,
                message: AppStrings.resultsPreparing,
                showMessage: true,
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.currentUser;
      
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.userInfoNotFound),
              backgroundColor: AppColors.error,
            ),
          );
          Navigator.pop(context);
        }
        return;
      }

      // Tüm cevapları birleştir
      final allAnswers = <String, String>{};
      for (final question in widget.testDefinition.sections
          .where((s) => s.type == QuizSectionType.question)
          .expand((s) => s.questions)) {
        if (_answers.containsKey(question.id)) {
          final optionId = _answers[question.id]!;
          final option = question.options.firstWhere((opt) => opt.id == optionId);
          allAnswers[question.id] = option.text;
        }
      }

      // Test sorularını ve cevapları formatla
      final questionsWithAnswers = <String>[];
      for (final section in widget.testDefinition.sections) {
        if (section.type == QuizSectionType.question) {
          for (final question in section.questions) {
            if (_answers.containsKey(question.id)) {
              final optionId = _answers[question.id]!;
              final selectedOption = question.options.firstWhere((opt) => opt.id == optionId);
              questionsWithAnswers.add('Soru: ${question.question}\nCevap: ${selectedOption.text}');
            }
          }
        }
      }

      final userName = _formData.containsKey('name') ? _formData['name'] as String : AppStrings.dearUser;
      final birthDate = _formData.containsKey('birthDate') 
          ? DateTime.tryParse(_formData['birthDate'] as String)?.toString().split(' ')[0] 
          : null;

      // Karma kontrolü yap (ama henüz kesme)
      final hasEnoughKarma = await _checkKarmaAvailability();
      if (!hasEnoughKarma) {
        if (mounted) {
          Navigator.pop(context); // Loading dialog'u kapat
        }
        return;
      }

      // AI ile test sonucu oluştur
      final aiService = AIService();
      final resultText = await aiService.generateMysticReply(
        userMessage: '''
${widget.testDefinition.title} ${AppStrings.testCompletedMessage}

TEST BİLGİLERİ:
${AppStrings.testName} ${widget.testDefinition.title}
${AppStrings.testDescription} ${widget.testDefinition.description}
${birthDate != null ? '${AppStrings.birthDateLabel} $birthDate' : ''}

${AppStrings.questionsAndAnswers}
${questionsWithAnswers.map((q) => '- $q').join('\n\n')}

LÜTFEN ŞUNLARI YAP:
1. Kullanıcının cevaplarını analiz et ve derinlemesine bir kişilik/profil analizi yap
2. Test konusuna göre (aşk, kişilik, uyumluluk vb.) özel sonuçlar üret
3. Pozitif, ilham verici ve destekleyici bir ton kullan
4. Kullanıcıya kişiselleştirilmiş öneriler ve içgörüler ver
5. Mistik ama profesyonel bir dil kullan
6. Sonucu 200-300 kelime arası tut

ÖNEMLİ: Bu bir fal değil, bir psikolojik/kişilik testi. Fal dilini kullanma, bunun yerine test sonuçlarını analiz et ve kullanıcı hakkında bilgi ver.
''',
        extras: {
          'testId': widget.testDefinition.id,
          'testTitle': widget.testDefinition.title,
          'testType': 'quiz_result',
          'userName': userName,
        },
      );
      
      // AI sonucu başarıyla alındı, şimdi karma kes
      final requiredKarma = PricingConstants.testCost;
      final karmaSuccess = await userProvider.spendKarma(
        requiredKarma,
        '${AppStrings.testCompletion} ${widget.testDefinition.title}',
      );
      
      if (!karmaSuccess) {
        // Karma kesilemedi, hata göster
        if (mounted) {
          Navigator.pop(context); // Loading dialog'u kapat
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${AppStrings.notEnoughKarma}. Gerekli: $requiredKarma ${AppStrings.karma}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
      
      // Test sonucunu Firestore'a kaydet
      final firebaseService = FirebaseService();
      
      // Wait time oluştur (15-25 dakika)
      final waitMinutes = 15 + (DateTime.now().millisecond % 11);
      final availableAt = DateTime.now().add(Duration(minutes: waitMinutes));
      
      final testResult = QuizTestResult(
        id: '',
        userId: user.id,
        testId: widget.testDefinition.id,
        testTitle: widget.testDefinition.title,
        testDescription: widget.testDefinition.description,
        emoji: widget.testDefinition.emoji,
        resultText: resultText,
        formData: _formData,
        answers: _answers,
        createdAt: DateTime.now(),
      );

      // Metadata ile kaydet
      final resultData = testResult.toFirestore();
      resultData['metadata'] = {
        'availableAt': availableAt.toIso8601String(),
        'waitMinutes': waitMinutes,
      };

      final resultId = await firebaseService.saveQuizTestResult(user.id, resultData);
      
      if (resultId == null) {
        throw Exception('Test sonucu kaydedilemedi');
      }

      // Record quest completion for love test
      if (widget.testDefinition.id == 'love') {
        try {
          final completedQuests = await firebaseService.getCompletedQuests(user.id);
          if (!completedQuests.contains('love_test')) {
            await firebaseService.recordQuestCompletion(user.id, 'love_test');
            // Add karma reward
            final questReward = PricingConstants.getQuestById('love_test')?['karma'] as int? ?? 2;
            await userProvider.addKarma(
              questReward,
              'Görev tamamlandı: Aşk testi',
            );
          }
        } catch (e) {
          // Quest completion error - silent fail
        }
      }

      // Loading dialog'u kapat
      if (mounted) {
        Navigator.of(context).pop(); // Loading dialog'u kapat
      }
      
      // Test sonucu sayfasına git
      if (mounted) {
        final savedResult = testResult.copyWith(id: resultId);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => TestResultScreen(result: savedResult),
          ),
        );
      }
    } catch (e) {
      // Loading dialog'u kapat
      if (mounted) {
        Navigator.of(context).pop(); // Loading dialog'u kapat
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: themeProvider.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: widget.testDefinition.sections.length,
                  itemBuilder: (context, index) {
                    return _buildSection(widget.testDefinition.sections[index]);
                  },
                ),
              ),
              _buildNavigation(),
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
    final textSecondaryColor = AppColors.getTextSecondary(isDark);
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.testDefinition.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.testDefinition.title,
                        style: AppTextStyles.headingMedium.copyWith(
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${_currentPage + 1} / ${widget.testDefinition.sections.length}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          const KarmaCostBadge(customCost: 5),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildSection(QuizSection section) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    final textColor = AppColors.getTextPrimary(isDark);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (section.title.isNotEmpty) ...[
            Text(
              section.title,
              style: AppTextStyles.headingSmall.copyWith(
                color: textColor,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (section.type == QuizSectionType.form)
            ...section.fields.map((field) => _buildFormField(field)),
          if (section.type == QuizSectionType.question)
            ...section.questions.map((question) => _buildQuestion(question)),
        ],
      ),
    );
  }

  Widget _buildFormField(QuizField field) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    final textColor = AppColors.getTextPrimary(isDark);
    final textSecondaryColor = AppColors.getTextSecondary(isDark);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (field.hint != null) ...[
            const SizedBox(height: 4),
            Text(
              field.hint!,
              style: AppTextStyles.bodySmall.copyWith(
                color: textSecondaryColor,
              ),
            ),
          ],
          const SizedBox(height: 8),
          _buildFieldInput(field),
        ],
      ),
    );
  }

  Widget _buildFieldInput(QuizField field) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    final inputTextColor = AppColors.getInputTextColor(isDark);
    final inputHintColor = AppColors.getInputHintColor(isDark);
    final inputBgColor = isDark ? AppColors.cardBackground.withValues(alpha: 0.6) : AppColors.getInputBackground(isDark);
    final inputBorderColor = AppColors.getInputBorderColor(isDark);
    
    switch (field.type) {
      case QuizFieldType.text:
        return TextFormField(
          initialValue: _formData[field.id]?.toString() ?? '',
          style: TextStyle(color: inputTextColor),
          decoration: InputDecoration(
            hintText: field.placeholder ?? field.label,
            hintStyle: TextStyle(color: inputHintColor),
            filled: true,
            fillColor: inputBgColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: inputBorderColor,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: inputBorderColor,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.primary,
                width: 2,
              ),
            ),
          ),
          onChanged: (value) {
            setState(() {
              _formData[field.id] = value;
            });
          },
        );
      case QuizFieldType.date:
        return GestureDetector(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: isDark ? const ColorScheme.dark(
                      primary: AppColors.primary,
                      onPrimary: Colors.white,
                      surface: AppColors.cardBackground,
                      onSurface: Colors.white,
                    ) : ColorScheme.light(
                      primary: AppColors.primary,
                      onPrimary: Colors.white,
                      surface: Colors.white,
                      onSurface: Colors.grey[900]!,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (date != null) {
              setState(() {
                _formData[field.id] = date.toIso8601String();
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: inputBgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: inputBorderColor,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formData[field.id] != null
                      ? DateTime.parse(_formData[field.id])
                          .toString()
                          .split(' ')[0]
                      : field.placeholder ?? AppStrings.selectYourBirthDate,
                  style: TextStyle(
                    color: _formData[field.id] != null
                        ? inputTextColor
                        : inputHintColor,
                  ),
                ),
                Icon(Icons.calendar_today, color: inputHintColor),
              ],
            ),
          ),
        );
      case QuizFieldType.mood:
        final moods = [AppStrings.moodGood, AppStrings.moodMixed, AppStrings.moodTired, AppStrings.moodEnergetic];
        final moodTextColor = AppColors.getTextPrimary(isDark);
        final moodBg = AppColors.getCardBackground(isDark).withValues(alpha: 0.6);
        
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: moods.map((mood) {
            final isSelected = _formData[field.id] == mood;
            return ChoiceChip(
              label: Text(mood),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _formData[field.id] = mood;
                });
              },
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : moodTextColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              backgroundColor: moodBg,
              side: BorderSide(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.3),
              ),
            );
          }).toList(),
        );
    }
  }

  Widget _buildQuestion(QuizQuestion question) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    final textColor = AppColors.getTextPrimary(isDark);
    final textSecondaryColor = AppColors.getTextSecondary(isDark);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.question,
            style: AppTextStyles.bodyLarge.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (question.hint != null) ...[
            const SizedBox(height: 4),
            Text(
              question.hint!,
              style: AppTextStyles.bodySmall.copyWith(
                color: textSecondaryColor,
              ),
            ),
          ],
          const SizedBox(height: 16),
          ...question.options.map((option) => _buildOption(question.id, option)),
        ],
      ),
    );
  }

  Widget _buildOption(String questionId, QuizOption option) {
    final isSelected = _answers[questionId] == option.id;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    final textColor = AppColors.getTextPrimary(isDark);
    final optionBg = isSelected
        ? AppColors.primary.withValues(alpha: 0.2)
        : AppColors.getCardBackground(isDark).withValues(alpha: 0.6);
    final borderColor = isSelected
        ? AppColors.primary
        : AppColors.primary.withValues(alpha: 0.3);
    final circleBorderColor = isSelected
        ? AppColors.primary
        : isDark 
            ? Colors.white.withValues(alpha: 0.5)
            : Colors.grey.withValues(alpha: 0.5);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _answers[questionId] = option.id;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: optionBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? AppColors.primary
                      : Colors.transparent,
                  border: Border.all(
                    color: circleBorderColor,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  option.text,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: textColor,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground.withValues(alpha: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: CustomButton(
                text: 'Geri',
                type: CustomButtonType.secondary,
                icon: Icons.arrow_back,
                onPressed: _previousPage,
                isFullWidth: true,
              ),
            )
          else
            Expanded(
              child: CustomButton(
                text: AppStrings.cancel,
                type: CustomButtonType.secondary,
                icon: Icons.close,
                onPressed: () => Navigator.pop(context),
                isFullWidth: true,
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: CustomButton(
              text: _currentPage == widget.testDefinition.sections.length - 1
                  ? AppStrings.complete
                  : AppStrings.continue_,
              type: CustomButtonType.primary,
              icon: _currentPage == widget.testDefinition.sections.length - 1
                  ? Icons.check_circle
                  : Icons.arrow_forward,
              onPressed: _canProceed() && !_isSubmitting ? _nextPage : null,
              isFullWidth: true,
              isLoading: _isSubmitting,
            ),
          ),
        ],
      ),
    );
  }
}

