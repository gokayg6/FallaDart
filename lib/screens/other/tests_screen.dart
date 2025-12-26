import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/models/test_model.dart';
import '../../core/models/quiz_test_model.dart';
import '../../core/providers/test_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../providers/theme_provider.dart';
import '../../core/services/quiz_test_service.dart';
import '../../core/widgets/mystical_loading.dart';
import '../tests/general_test_screen.dart';
import '../tests/test_result_screen.dart';
import '../../core/utils/helpers.dart';

class TestsScreen extends StatefulWidget {
  const TestsScreen({Key? key}) : super(key: key);

  @override
  State<TestsScreen> createState() => _TestsScreenState();
}

class _TestsScreenState extends State<TestsScreen> with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late Animation<double> _backgroundAnimation;
  
  String _selectedCategory = 'available';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadTests();
  }

  void _initializeAnimations() {
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));
  }

  void _loadTests() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final testProvider = Provider.of<TestProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      if (userProvider.currentUser != null) {
        testProvider.initialize(userProvider.currentUser!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        // iOS System Background Colors
        final backgroundColor = isDark 
            ? const Color(0xFF0F172A) 
            : const Color(0xFFF5F5F7); // iOS Light Gray

        return Scaffold(
          backgroundColor: backgroundColor,
          body: Stack(
            children: [
              // Ambient Background Particles
              if (isDark) ...[
                Positioned(
                  top: -100,
                  right: -100,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF4A00E0).withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -50,
                  left: -50,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFE91E63).withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                 // Light Mode Subtle Warmth
                 Positioned(
                  top: -100,
                  right: -50,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF6200EA).withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                ),
              ],

              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(isDark),
                    _buildElegantCategorySelector(isDark),
                    Expanded(
                      child: Consumer<TestProvider>(
                        builder: (context, testProvider, child) {
                          if (testProvider.isLoading) {
                            return Center(
                              child: MysticalLoading(
                                type: MysticalLoadingType.stars,
                                message: AppStrings.isEnglish ? 'Loading tests...' : 'Testler yükleniyor...',
                              ),
                            );
                          }

                          return _selectedCategory == 'available'
                                  ? _buildAvailableTests(testProvider, isDark)
                                  : _buildCompletedTests(testProvider, isDark);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        AppStrings.tests,
        style: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : const Color(0xFF1C1C1E),
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildElegantCategorySelector(bool isDark) {
    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE5E5EA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            alignment: _selectedCategory == 'available' ? Alignment.centerLeft : Alignment.centerRight,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.5 - 24, // Approx half width minus padding
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF334155) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedCategory = 'available'),
                  behavior: HitTestBehavior.translucent,
                  child: Center(
                    child: Text(
                      AppStrings.all,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _selectedCategory == 'available' 
                            ? (isDark ? Colors.white : Colors.black) 
                            : (isDark ? Colors.white54 : Colors.black54),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedCategory = 'completed'),
                  behavior: HitTestBehavior.translucent,
                  child: Center(
                    child: Text(
                      AppStrings.completedTests,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _selectedCategory == 'completed' 
                            ? (isDark ? Colors.white : Colors.black) 
                            : (isDark ? Colors.white54 : Colors.black54),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableTests(TestProvider testProvider, bool isDark) {
    final quizTestService = QuizTestService();
    final allTests = quizTestService.getAllTests();
    
    // Popüler testler
    final popularTestIds = ['personality', 'friendship', 'love', 'compatibility', 'love_what_you_want'];
    final popularTests = allTests.where((test) => 
      popularTestIds.contains(test.id)
    ).toList();
    
    // Diğer testler
    final otherTests = allTests.where((test) => 
      !popularTestIds.contains(test.id)
    ).toList();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (popularTests.isNotEmpty) ...[
            Text(
              AppStrings.popularTests,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1C1C1E),
              ),
            ),
            const SizedBox(height: 16),
            ...popularTests.map((test) => _buildGlassTestCard(test, isDark)).toList(),
            const SizedBox(height: 32),
          ],
          if (otherTests.isNotEmpty) ...[
            Text(
              AppStrings.otherTests,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1C1C1E),
              ),
            ),
            const SizedBox(height: 16),
            ...otherTests.map((test) => _buildGlassTestCard(test, isDark)).toList(),
          ],
        ],
      ),
    );
  }

  String? _getTestGifPath(QuizTestDefinition test) {
    switch (test.id) {
      case 'personality':
      return 'assets/gif/Popüler Testler/Kişilik Testi/kişiliktesti.gif';
      case 'friendship':
      return 'assets/gif/Popüler Testler/Arkadaşlık Testi/arkadaşlıktesti.gif';
      case 'love':
      return 'assets/gif/Popüler Testler/Aşk Testi/aşktesti.gif';
      case 'compatibility':
      return 'assets/gif/Popüler Testler/İlişki Uyum Testi/ilişkiuyumtesti.gif';
      case 'love_what_you_want':
      return 'assets/gif/Popüler Testler/İlişkinde Gerçekten Ne İstiyorsun/ilişkindegerçektenneistiyorsun.gif';
      default:
      return null;
    }
  }

  Color _getTestColor(String testId) {
    if (testId.contains('love') || testId.contains('aşk')) return const Color(0xFFE91E63); // Pink
    if (testId.contains('personality') || testId.contains('kişilik')) return const Color(0xFF9C27B0); // Purple
    if (testId.contains('friend') || testId.contains('arkadaş')) return const Color(0xFFFF9800); // Orange
    if (testId.contains('compatibility') || testId.contains('uyum')) return const Color(0xFFF06292); // Light Pink
    return const Color(0xFF2196F3); // Blue default
  }

  String _getLocalizedQuizTitle(QuizTestDefinition test) {
    if (!AppStrings.isEnglish) return test.title;
    final lower = test.title.toLowerCase();
    if (lower.contains('kişilik testi')) return AppStrings.personalityTest;
    if (lower.contains('arkadaşlık testi')) return AppStrings.friendshipTest;
    if (lower.contains('aşk testi')) return AppStrings.loveTest;
    if (lower.contains('ilişkinde gerçekten ne istiyorsun')) return AppStrings.relationshipWhatYouWantTest;
    if (lower.contains('aşkta kırmızı bayrakları görebiliyor musun')) return AppStrings.loveRedFlagsTest;
    if (lower.contains('burcuna göre ne kadar eğlencelisin')) return AppStrings.zodiacFunLevelTest;
    if (lower.contains('burcuna göre ne kadar kaotiksin')) return AppStrings.zodiacChaosLevelTest;
    return test.title;
  }

  String _getLocalizedQuizSubtitle(QuizTestDefinition test) {
    if (!AppStrings.isEnglish) return test.description;
    switch (test.id) {
      case 'personality': return AppStrings.personalityTestSubtitle;
      case 'friendship': return AppStrings.friendshipTestSubtitle;
      case 'love': return AppStrings.loveTestSubtitle;
      case 'compatibility': return AppStrings.relationshipCompatibilitySubtitle;
      case 'love_what_you_want': return AppStrings.relationshipWhatYouWantSubtitle;
      default: return test.description;
    }
  }

  Widget _buildGlassTestCard(QuizTestDefinition test, bool isDark) {
    final gifPath = _getTestGifPath(test);
    final baseColor = _getTestColor(test.id);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GeneralTestScreen(testDefinition: test),
            ),
          );
        },
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            color: isDark 
                ? Colors.white.withValues(alpha: 0.05) 
                : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isDark 
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Subtle Gradient Background
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [baseColor.withValues(alpha: 0.1), Colors.transparent]
                            : [baseColor.withValues(alpha: 0.05), Colors.white],
                      ),
                    ),
                  ),
                ),
                
                Row(
                  children: [
                     // GIF/Image Section
                     if (gifPath != null)
                      Container(
                        width: 100,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(
                              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                            )
                          )
                        ),
                        child: Image.asset(
                          gifPath,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(test.emoji, style: const TextStyle(fontSize: 32)),
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 100,
                        height: double.infinity,
                         decoration: BoxDecoration(
                          color: baseColor.withValues(alpha: 0.1),
                          border: Border(
                            right: BorderSide(
                              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                            )
                          )
                        ),
                        child: Center(
                          child: Text(test.emoji, style: const TextStyle(fontSize: 40)),
                        ),
                      ),
                      
                    // Content Section
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _getLocalizedQuizTitle(test),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _getLocalizedQuizSubtitle(test),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.normal,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Arrow
                    Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: isDark ? Colors.white30 : Colors.black26,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedTests(TestProvider testProvider, bool isDark) {
    final completedTests = testProvider.userTests
        .where((test) => test.status == TestStatus.completed)
        .toList();
    final quizTestResults = testProvider.quizTestResults;

    if (completedTests.isEmpty && quizTestResults.isEmpty) {
      return _buildEmptyCompletedState(isDark);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (quizTestResults.isNotEmpty) ...[
            Text(
              AppStrings.testResults,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1C1C1E),
              ),
            ),
            const SizedBox(height: 16),
            ...quizTestResults.map((result) => _buildGlassResultCard(result, isDark)).toList(),
            const SizedBox(height: 32),
          ],
          if (completedTests.isNotEmpty) ...[
             Text(
              AppStrings.otherTests,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1C1C1E),
              ),
            ),
            const SizedBox(height: 16),
            ...completedTests.map((test) => _buildGlassLegacyResultCard(test, isDark)).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyCompletedState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.checklist_rtl_rounded,
            size: 64,
            color: isDark ? Colors.white12 : Colors.black12,
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.noCompletedTests,
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.black45,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassResultCard(QuizTestResult result, bool isDark) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TestResultScreen(result: result),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark 
              ? Colors.white.withValues(alpha: 0.05) 
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isDark 
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    result.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.testTitle,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(result.createdAt),
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        AppStrings.testCompleted,
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _cleanText(result.resultText),
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : Colors.black87,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassLegacyResultCard(TestModel test, bool isDark) {
    // Legacy support for old test format if needed
    return Container(); 
  }

  String _cleanText(String text) {
    final cleaned = Helpers.cleanMarkdown(text);
    return cleaned.length > 150 ? '${cleaned.substring(0, 150)}...' : cleaned;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays == 0) return 'Bugün';
    if (difference.inDays == 1) return 'Dün';
    if (difference.inDays < 7) return '${difference.inDays} gün önce';
    return '${date.day}/${date.month}/${date.year}';
  }
}