import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;
import 'dart:ui';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/providers/user_provider.dart';
import '../../core/providers/language_provider.dart';
import '../../providers/theme_provider.dart';
import '../../core/widgets/mystical_loading.dart';
import '../../core/widgets/mystical_dialog.dart';
import '../../core/services/firebase_service.dart';
import 'edit_profile_screen.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  late AnimationController _glowController;
  int _totalFortunesCount = 0;
  int _favoriteFortunesCount = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    
    _loadTotalFortunes();
    _loadFavoriteFortunes();
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _loadTotalFortunes() async {
    try {
      final userId = Provider.of<UserProvider>(context, listen: false).user?.id;
      if (userId != null) {
        final docs = await FirebaseService().getUserFortunesFromReadings(userId);
        if (mounted) setState(() => _totalFortunesCount = docs.length);
      }
    } catch (e) {}
  }

  Future<void> _loadFavoriteFortunes() async {
    try {
      final userId = Provider.of<UserProvider>(context, listen: false).user?.id;
      if (userId != null) {
        final docs = await FirebaseService().getUserFortunesFromReadings(userId);
        final favCount = docs.where((d) => (d.data() as Map<String, dynamic>)['isFavorite'] == true).length;
        if (mounted) setState(() => _favoriteFortunesCount = favCount);
      }
    } catch (e) {}
  }

  void _signOut() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.isGuest) {
      final confirmed = await MysticalDialog.show(
        context: context,
        title: AppStrings.signingOut,
        type: MysticalDialogType.warning,
        customIcon: Icons.warning_amber_rounded,
        customIconColor: AppColors.warning,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.guestSignOutWarning, style: TextStyle(color: Colors.white)),
            const SizedBox(height: 16),
            Text("• ${AppStrings.allFortunesWillBeDeleted}", style: TextStyle(color: Colors.white70)),
            Text("• ${AppStrings.karmaPointsWillBeLost}", style: TextStyle(color: Colors.white70)),
          ],
        ),
        confirmText: AppStrings.signOut,
        cancelText: AppStrings.cancel,
        onConfirm: () => Navigator.pop(context, true),
        onCancel: () => Navigator.pop(context, false),
      );
      if (confirmed != true) return;
    }

    setState(() => _isLoading = true);
    try {
      await userProvider.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final now = DateTime.now();
    var diff = now.difference(local);
    if (diff.isNegative) diff = Duration.zero;

    if (diff.inMinutes < 1) return AppStrings.now;
    if (diff.inMinutes < 60) return '${diff.inMinutes} ${AppStrings.minAgo}';
    if (diff.inHours < 24) return '${diff.inHours} ${AppStrings.hoursAgo}';
    if (diff.inDays < 7) return '${diff.inDays} ${AppStrings.daysAgoShort}';
    final two = (int n) => n.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              // Clean Abstract Background - Ultra Premium
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: themeProvider.backgroundGradient,
                  ),
                ),
              ),
              // Soft Top Glow - Moonlight Cyan
              Positioned(
                top: -100,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                       shape: BoxShape.circle,
                       color: (isDark ? AppColors.mysticPurpleAccent : AppColors.moonlightCyan).withOpacity(0.05),
                       boxShadow: [
                         BoxShadow(
                           color: (isDark ? AppColors.mysticPurpleAccent : AppColors.aquaIndigo).withOpacity(isDark ? 0.2 : 0.15),
                           blurRadius: 100,
                           spreadRadius: 20,
                         ),
                       ],
                    ),
                  ),
                ),
              ),

              SafeArea(
                bottom: false,
                child: Consumer<UserProvider>(
                  builder: (context, userProvider, child) {
                    if (userProvider.isLoading) return Center(child: MysticalLoading(type: MysticalLoadingType.crystal));

                    return CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(child: _buildSimpleHeader(isDark)),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            child: _buildMasterpieceProfileHero(userProvider, isDark),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            child: _buildCleanStatsRow(isDark, userProvider),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 8, bottom: 12),
                                  child: Text(
                                    AppStrings.settings,
                                    style: TextStyle(
                                      color: (isDark ? Colors.white : Colors.black).withOpacity(0.5),
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                                _buildGlassSettingsGroup(isDark, [
                                  _SettingsItem(
                                     title: AppStrings.themeSettings, 
                                     icon: Icons.palette_outlined, 
                                     color: Colors.purpleAccent,
                                     trailing: Switch(
                                       value: themeProvider.isDarkThemeSelected,
                                       activeColor: AppColors.primary,
                                       onChanged: (v) => themeProvider.toggleTheme(),
                                     ),
                                     onTap: () => themeProvider.toggleTheme(),
                                  ),
                                  _SettingsItem(
                                    title: AppStrings.language,
                                    icon: Icons.language,
                                    color: Colors.blueAccent,
                                    onTap: () => _showLanguageDialog(context, Provider.of<LanguageProvider>(context, listen: false)),
                                  ),
                                ]),
                                const SizedBox(height: 16),
                                _buildGlassSettingsGroup(isDark, [
                                  _SettingsItem(title: AppStrings.privacy, icon: Icons.privacy_tip_outlined, color: Colors.tealAccent, onTap: () => _showPrivacyDialog(context)),
                                  _SettingsItem(title: AppStrings.help, icon: Icons.help_outline, color: Colors.orangeAccent, onTap: () => _showHelpDialog(context)),
                                  _SettingsItem(title: AppStrings.about, icon: Icons.info_outline, color: Colors.pinkAccent, onTap: () => _showAboutDialog(context)),
                                ]),
                                const SizedBox(height: 16),
                                _buildGlassSettingsGroup(isDark, [
                                  _SettingsItem(title: AppStrings.editProfile, icon: Icons.edit_outlined, color: Colors.greenAccent, onTap: () {
                                     Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                                  }),
                                ]),
                                const SizedBox(height: 24),
                                _buildDangerButton(isDark, AppStrings.signOut, Icons.logout, Colors.orange, _signOut),
                                const SizedBox(height: 12),
                                _buildDangerButton(isDark, AppStrings.deleteAccount, Icons.delete_outline, Colors.red, () => _showDeleteAccountDialog(userProvider)),
                                const SizedBox(height: 100),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSimpleHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
      child: Text(
        AppStrings.profile,
        style: AppTextStyles.headingLarge.copyWith(
          color: isDark ? Colors.white : AppColors.slateText,
          fontSize: 32,
        ),
      ),
    );
  }

  Widget _buildMasterpieceProfileHero(UserProvider userProvider, bool isDark) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
          ),
          child: Column(
            children: [
              // Avatar with Moonlight Glow
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isDark ? AppColors.mysticPurpleAccent : AppColors.aquaIndigo)
                              .withOpacity(0.4 + (_glowController.value * 0.2)),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    radius: 46,
                    backgroundColor: isDark ? const Color(0xFF1E1E2C) : AppColors.moonlightCyan.withOpacity(0.1),
                    child: Text(
                      userProvider.user?.name != null && userProvider.user!.name.isNotEmpty 
                        ? userProvider.user!.name[0].toUpperCase() 
                        : 'M',
                      style: AppTextStyles.headingLarge.copyWith(
                         color: isDark ? Colors.white : AppColors.aquaIndigo,
                         fontSize: 36,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                userProvider.user?.name ?? AppStrings.guest,
                style: AppTextStyles.headingMedium.copyWith(
                  color: isDark ? Colors.white : AppColors.slateText,
                  fontSize: 24,
                ),
              ),
              if (userProvider.user?.email != null) ...[
                const SizedBox(height: 4),
                Text(
                  userProvider.user?.email ?? '',
                  style: AppTextStyles.bodyMedium.copyWith(
                     color: isDark ? Colors.white70 : AppColors.slateTextMid,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              // Glowing Karma Badge
              Container(
                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                 decoration: BoxDecoration(
                   color: AppColors.karma.withOpacity(0.15),
                   borderRadius: BorderRadius.circular(20),
                   border: Border.all(color: AppColors.karma.withOpacity(0.3)),
                   boxShadow: [
                     BoxShadow(
                       color: AppColors.karma.withOpacity(0.2),
                       blurRadius: 10,
                       offset: const Offset(0, 2),
                     ),
                   ],
                 ),
                 child: Row(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     Icon(Icons.auto_awesome, color: AppColors.karma, size: 16),
                     const SizedBox(width: 8),
                     Text(
                       '${userProvider.user?.karma ?? 0} Karma',
                       style: AppTextStyles.bodyMedium.copyWith(
                         color: AppColors.karma,
                         fontWeight: FontWeight.bold,
                       ),
                     ),
                   ],
                 ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildCleanStatsRow(bool isDark, UserProvider userProvider) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _buildCleanStatItem(isDark, "$_totalFortunesCount", AppStrings.totalFortunes)),
          const SizedBox(width: 12),
          Expanded(child: _buildCleanStatItem(isDark, "$_favoriteFortunesCount", AppStrings.favorites)),
          const SizedBox(width: 12),
          Expanded(child: _buildCleanStatItem(isDark, _formatDate(userProvider.user?.createdAt ?? DateTime.now()), AppStrings.memberSince)),
        ],
      ),
    );
  }

  Widget _buildCleanStatItem(bool isDark, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: isDark 
          ? AppColors.darkGlassCardDecoration.copyWith(
              borderRadius: BorderRadius.circular(20),
            )
          : AppColors.pearlGlassCardDecoration.copyWith(
              borderRadius: BorderRadius.circular(20),
            ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.headingMedium.copyWith(
              color: isDark ? Colors.white : AppColors.slateText,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
               color: isDark ? Colors.white70 : AppColors.slateTextMuted,
               fontSize: 12,
               fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

   Widget _buildGlassSettingsGroup(bool isDark, List<_SettingsItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.04)),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          
          return Column(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: item.onTap,
                  borderRadius: index == 0 && items.length == 1 ? BorderRadius.circular(24) :
                              index == 0 ? const BorderRadius.vertical(top: Radius.circular(24)) :
                              index == items.length - 1 ? const BorderRadius.vertical(bottom: Radius.circular(24)) :
                              BorderRadius.zero,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: item.color.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(item.icon, color: item.color, size: 18),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            item.title,
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: isDark ? Colors.white : AppColors.slateText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (item.trailing != null) 
                          item.trailing!
                        else
                          Icon(Icons.chevron_right, color: (isDark ? Colors.white : AppColors.slateText).withOpacity(0.2), size: 18),
                      ],
                    ),
                  ),
                ),
              ),
              if (index != items.length - 1)
                 Divider(height: 1, indent: 60, endIndent: 20, color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
            ],
          );
        }).toList(),
      ),
    );
   }

   Widget _buildDangerButton(bool isDark, String title, IconData icon, Color color, VoidCallback onTap) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 18),
                  const SizedBox(width: 8),
                  Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
      );
   }
   
  // Dialog stubs for restored connectivity - implementing base functionality
  
  void _showDeleteAccountDialog(UserProvider userProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.getSurface(true), 
        title: Text(AppStrings.deleteAccount, style: TextStyle(color: Colors.white)),
        content: Text(AppStrings.areYouSure, style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(AppStrings.cancel)),
          ElevatedButton(onPressed: () {Navigator.pop(context); _deleteAccount(userProvider);}, child: Text(AppStrings.delete, style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(UserProvider userProvider) async {
     setState(() => _isLoading = true);
     try {
       await userProvider.deleteAccount();
       if(mounted) Navigator.pushNamedAndRemoveUntil(context, '/', (r)=>false);
     } catch(e) {}
     finally { if(mounted) setState(() => _isLoading = false); } 
  }

  Future<void> _showLanguageDialog(BuildContext context, LanguageProvider languageProvider) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    final dialogBg = AppColors.getSurface(isDark);
    final textColor = AppColors.getTextPrimary(isDark);
    
    final selectedLanguage = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          AppStrings.selectLanguage,
          style: AppTextStyles.headingSmall.copyWith(
            color: textColor,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: LanguageProvider.availableLanguages.map((lang) {
            final isSelected = languageProvider.currentLanguage == lang;
            final flagEmoji = _getLanguageFlag(lang.code);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildLanguageOptionNew(
                context,
                lang.name,
                lang.code,
                isSelected,
                lang.isRTL,
                flagEmoji,
                () => Navigator.pop(context, lang.code),
                isDark,
              ),
            );
          }).toList(),
        ),
      ),
    );

    if (selectedLanguage != null && mounted) {
      await languageProvider.setLanguageByCode(selectedLanguage);
      
      if (mounted) {
        // Simple refresh logic
        setState(() {});
      }
    }
  }

  String _getLanguageFlag(String code) {
    switch (code) {
      case 'tr': return '🇹🇷';
      case 'en': return '🇬🇧';
      case 'it': return '🇮🇹';
      case 'fr': return '🇫🇷';
      case 'ru': return '🇷🇺';
      case 'de': return '🇩🇪';
      case 'ar': return '🇸🇦';
      case 'fa': return '🇮🇷';
      default: return '🌐';
    }
  }

  Widget _buildLanguageOptionNew(
    BuildContext context,
    String languageName,
    String languageCode,
    bool isSelected,
    bool isRTL,
    String flagEmoji,
    VoidCallback onTap,
    bool isDark,
  ) {
    final textColor = AppColors.getTextPrimary(isDark);
    final textSecondaryColor = AppColors.getTextSecondary(isDark);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDark ? AppColors.moonlightCyan.withOpacity(0.2) : AppColors.aquaIndigo.withOpacity(0.15))
              : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.08)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? (isDark ? AppColors.moonlightCyan : AppColors.aquaIndigo)
                : (isDark ? Colors.white.withOpacity(0.15) : Colors.grey.withOpacity(0.2)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? (isDark ? AppColors.moonlightCyan : AppColors.aquaIndigo) : textSecondaryColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              languageName,
              style: AppTextStyles.bodyMedium.copyWith(
                color: textColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (isRTL) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.aquaIndigo.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'RTL',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? AppColors.moonlightCyan : AppColors.aquaIndigo,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            const Spacer(),
            Text(
              flagEmoji,
              style: const TextStyle(fontSize: 24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    String trText,
    String enText,
    String languageCode,
    bool isSelected,
    VoidCallback onTap,
    bool isDark,
  ) {
    final isEnglish = Provider.of<LanguageProvider>(context, listen: false).isEnglish;
    final textColor = AppColors.getTextPrimary(isDark);
    final textSecondaryColor = AppColors.getTextSecondary(isDark);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.karma.withValues(alpha: 0.2)
              : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? AppColors.karma
                : (isDark ? Colors.white.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.3)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? AppColors.karma : textSecondaryColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              isEnglish ? enText : trText,
              style: AppTextStyles.bodyMedium.copyWith(
                color: textColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const Spacer(),
            Text(
              languageCode == 'tr' ? '🇹🇷' : '🇬🇧',
              style: const TextStyle(fontSize: 24),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    final dialogBg = AppColors.getSurface(isDark);
    final textColor = AppColors.getTextPrimary(isDark);
    final textSecondaryColor = AppColors.getTextSecondary(isDark);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.privacy_tip, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(AppStrings.privacy, style: AppTextStyles.headingSmall.copyWith(color: textColor)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.privacyPolicy,
                style: AppTextStyles.bodyMedium.copyWith(color: textColor, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                '${AppStrings.privacyPolicyDesc}${AppStrings.privacyPolicyPoints}',
                style: AppTextStyles.bodySmall.copyWith(color: textSecondaryColor),
              ),
              const SizedBox(height: 16),
              _buildPolicyLinksInDialog(textSecondaryColor),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.close, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPolicyLinksInDialog(Color textSecondaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.byPurchasingYouAccept, style: AppTextStyles.bodySmall.copyWith(color: textSecondaryColor)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _buildPolicyLink(AppStrings.privacyPolicyLink, 'https://www.loegs.com/falla/PrivacyPolicy.html'),
            Text(', ', style: AppTextStyles.bodySmall.copyWith(color: textSecondaryColor)),
            _buildPolicyLink(AppStrings.userAgreementLink, 'https://www.loegs.com/falla/UserAgreement.html'),
            Text(', ', style: AppTextStyles.bodySmall.copyWith(color: textSecondaryColor)),
            _buildPolicyLink(AppStrings.termsOfServiceLink, 'https://www.loegs.com/falla/TermsOfService.html'),
          ],
        ),
      ],
    );
  }

  Widget _buildPolicyLink(String text, String url) {
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
      },
      child: Text(text, style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, decoration: TextDecoration.underline)),
    );
  }

  void _showHelpDialog(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    final dialogBg = AppColors.getSurface(isDark);
    final textColor = AppColors.getTextPrimary(isDark);
    final textSecondaryColor = AppColors.getTextSecondary(isDark);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.help, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(AppStrings.help, style: AppTextStyles.headingSmall.copyWith(color: textColor)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.helpAndSupport,
                style: AppTextStyles.bodyMedium.copyWith(color: textColor, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                '${AppStrings.helpDesc}${AppStrings.helpPoints}',
                style: AppTextStyles.bodySmall.copyWith(color: textSecondaryColor),
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.questionsContact,
                style: AppTextStyles.bodyMedium.copyWith(color: textColor, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'falla@loegs.com',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.close, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    final dialogBg = AppColors.getSurface(isDark);
    final textColor = AppColors.getTextPrimary(isDark);
    final textSecondaryColor = AppColors.getTextSecondary(isDark);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.info, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(AppStrings.about, style: AppTextStyles.headingSmall.copyWith(color: textColor)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                   color: AppColors.primary.withOpacity(0.1),
                  ),
                   child: const Center(child: Text('🔮', style: TextStyle(fontSize: 32))),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Falla v1.0.0',
                style: AppTextStyles.bodyMedium.copyWith(color: textColor, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                '${AppStrings.mysticalFortuneApp}${AppStrings.fallaWith}${AppStrings.fallaFeatures}${AppStrings.copyright}',
                style: AppTextStyles.bodySmall.copyWith(color: textSecondaryColor),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.close, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

class _SettingsItem {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final Widget? trailing;
  _SettingsItem({required this.title, required this.icon, required this.color, required this.onTap, this.trailing});
}
