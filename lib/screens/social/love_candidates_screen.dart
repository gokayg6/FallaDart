import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/love_candidate_model.dart';
import '../../core/services/firebase_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/helpers.dart';
import '../../providers/theme_provider.dart';
import '../../core/providers/user_provider.dart';
import 'love_candidate_form_screen.dart';
import 'love_compatibility_result_screen.dart';
import '../../screens/astrology/daily_astrology_screen.dart';
import '../../screens/astrology/astrology_calendar_screen.dart';

class LoveCandidatesScreen extends StatefulWidget {
  const LoveCandidatesScreen({super.key});

  @override
  State<LoveCandidatesScreen> createState() => _LoveCandidatesScreenState();
}

class _LoveCandidatesScreenState extends State<LoveCandidatesScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<LoveCandidateModel> _candidates = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCandidates();
  }

  Future<void> _loadCandidates() async {
    setState(() => _loading = true);
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.user?.id;
      if (userId == null) {
        setState(() {
          _candidates = [];
          _loading = false;
        });
        return;
      }

      final candidates = await _firebaseService.getLoveCandidates(userId);
      if (mounted) {
        setState(() {
          _candidates = candidates;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _candidates = [];
          _loading = false;
        });
      }
    }
  }

  Future<void> _deleteCandidate(LoveCandidateModel candidate) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.deleteAccount),
        content: Text('${candidate.name} adayını silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final userId = userProvider.user?.id;
        if (userId != null) {
          await _firebaseService.deleteLoveCandidate(userId, candidate.id);
          _loadCandidates();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hata: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        final textColor = AppColors.getTextPrimary(isDark);
        final textSecondaryColor = AppColors.getTextSecondary(isDark);
        final cardBg = AppColors.getCardBackground(isDark);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Aşk Adaylarım'),
            backgroundColor: isDark ? AppColors.surface : AppColors.lightSurface,
            foregroundColor: textColor,
            elevation: 0,
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: themeProvider.backgroundGradient,
            ),
            child: SafeArea(
              child: _loading
                  ? Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : Column(
                      children: [
                        // Header description
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hoşlandığın kişileri ekle, burç ve doğum bilgilerine göre aşk uyumunu gör.',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: textSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Add candidate button
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoveCandidateFormScreen(),
                                  ),
                                );
                                if (result == true) {
                                  _loadCandidates();
                                }
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Aday Ekle'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Candidates list
                        Expanded(
                          child: _candidates.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.favorite_border,
                                        size: 64,
                                        color: textSecondaryColor,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Henüz aday eklenmedi',
                                        style: AppTextStyles.bodyLarge.copyWith(
                                          color: textSecondaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  itemCount: _candidates.length,
                                  itemBuilder: (context, index) {
                                    final candidate = _candidates[index];
                                    return _buildCandidateCard(
                                      candidate,
                                      isDark,
                                      textColor,
                                      textSecondaryColor,
                                      cardBg,
                                    );
                                  },
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

  Widget _buildCandidateCard(
    LoveCandidateModel candidate,
    bool isDark,
    Color textColor,
    Color textSecondaryColor,
    Color cardBg,
  ) {
    final zodiacEmoji = Helpers.getZodiacEmoji(candidate.zodiacSign);
    final score = candidate.lastCompatibilityScore;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: cardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LoveCompatibilityResultScreen(
                candidate: candidate,
              ),
            ),
          );
          if (result == true) {
            _loadCandidates();
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                backgroundImage: candidate.avatarUrl != null
                    ? NetworkImage(candidate.avatarUrl!)
                    : null,
                child: candidate.avatarUrl == null
                    ? Text(
                        candidate.name[0].toUpperCase(),
                        style: AppTextStyles.headingSmall.copyWith(
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              // Name and zodiac
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      candidate.name,
                      style: AppTextStyles.headingSmall.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          zodiacEmoji,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            candidate.zodiacSign,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: textSecondaryColor,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              // Score or calculate button
              if (score != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppColors.karmaGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '%${score.toInt()}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.calculate, size: 18),
                  iconSize: 18,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                  color: AppColors.primary,
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoveCompatibilityResultScreen(
                          candidate: candidate,
                        ),
                      ),
                    );
                    if (result == true) {
                      _loadCandidates();
                    }
                  },
                ),
              // Chart button
              IconButton(
                icon: const Icon(Icons.auto_graph, size: 18),
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 28,
                  minHeight: 28,
                ),
                color: AppColors.primary,
                tooltip: AppStrings.isEnglish ? 'Chart' : 'Grafik',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DailyAstrologyScreen(
                        candidate: candidate,
                      ),
                    ),
                  );
                },
              ),
              // Calendar button
              IconButton(
                icon: const Icon(Icons.calendar_today, size: 18),
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 28,
                  minHeight: 28,
                ),
                color: AppColors.secondary,
                tooltip: AppStrings.isEnglish ? 'Calendar' : 'Takvim',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AstrologyCalendarScreen(
                        candidate: candidate,
                      ),
                    ),
                  );
                },
              ),
              // Delete button
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 28,
                  minHeight: 28,
                ),
                color: AppColors.error,
                onPressed: () => _deleteCandidate(candidate),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

