import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/providers/user_provider.dart';
import '../../providers/theme_provider.dart';
import '../../core/widgets/mystical_loading.dart';
import '../auth/login_screen.dart';

class FixedProfileScreen extends StatefulWidget {
  const FixedProfileScreen({Key? key}) : super(key: key);

  @override
  State<FixedProfileScreen> createState() => _FixedProfileScreenState();
}

class _FixedProfileScreenState extends State<FixedProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late Animation<double> _backgroundAnimation;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
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
    
    // Blinking animation disabled
    // _backgroundController.repeat(reverse: true);
  }

  void _signOut() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.signOut();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Çıkış yapıldı'),
            backgroundColor: Colors.green,
          ),
        );
        // Go to login screen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) => Container(
        decoration: BoxDecoration(
            gradient: themeProvider.backgroundGradient,
        ),
        child: SafeArea(
          child: Consumer<UserProvider>(
            builder: (context, userProvider, child) {
            if (userProvider.isLoading) {
              return const Center(
                child: MysticalLoading(
                  type: MysticalLoadingType.crystal,
                  message: 'Profil yükleniyor...',
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildProfileCard(userProvider),
                  const SizedBox(height: 24),
                  _buildStatsCard(userProvider),
                  const SizedBox(height: 24),
                  _buildSettingsSection(),
                  const SizedBox(height: 24),
                  _buildActionButtons(userProvider),
                  const SizedBox(height: 100),
                ],
              ),
            );
            },
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Text(
      AppStrings.profile,
      style: AppTextStyles.headingLarge.copyWith(
        color: Colors.white,
      ),
    );
  }

  Widget _buildProfileCard(UserProvider userProvider) {
    return AnimatedBuilder(
      animation: _backgroundAnimation,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.cardBackground.withValues(alpha: 0.8 + (_backgroundAnimation.value * 0.1)),
                AppColors.cardBackground.withValues(alpha: 0.6 + (_backgroundAnimation.value * 0.1)),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.2 + (_backgroundAnimation.value * 0.1)),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.primary,
                child: Text(
                  userProvider.user?.name != null && userProvider.user!.name.isNotEmpty
                      ? userProvider.user!.name[0].toUpperCase()
                      : 'M',
                  style: AppTextStyles.headingLarge.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                userProvider.user?.name ?? AppStrings.guest,
                style: AppTextStyles.headingMedium.copyWith(
                  color: Colors.white,
                ),
              ),
              if (userProvider.user?.email != null) ...[
                const SizedBox(height: 8),
                Text(
                  userProvider.user?.email ?? '',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: AppColors.karma,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${userProvider.user?.karma ?? 0} Karma',
                    style: AppTextStyles.karmaDisplay.copyWith(
                      color: AppColors.karma,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsCard(UserProvider userProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.mysticalGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.statistics,
            style: AppTextStyles.headingSmall.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  AppStrings.totalFortunes,
                  '${userProvider.user?.totalFortunes ?? 0}',
                  Icons.auto_awesome,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  AppStrings.dailyFortunes,
                  '${userProvider.user?.dailyFortunesUsed ?? 0}/3',
                  Icons.today,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  AppStrings.memberSince,
                  _formatDate(userProvider.user?.createdAt ?? DateTime.now()),
                  Icons.calendar_today,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  AppStrings.lastLogin,
                  _formatDate(userProvider.user?.lastLoginAt ?? DateTime.now()),
                  Icons.login,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white70,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.headingSmall.copyWith(
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: AppTextStyles.bodySmall.copyWith(
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.karmaGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.karma.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.karma.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.settings,
            style: AppTextStyles.headingSmall.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingItem(
            AppStrings.notifications,
            Icons.notifications,
            () {},
          ),
          _buildSettingItem(
            AppStrings.privacy,
            Icons.privacy_tip,
            () {},
          ),
          _buildSettingItem(
            AppStrings.help,
            Icons.help,
            () {},
          ),
          _buildSettingItem(
            AppStrings.about,
            Icons.info,
            () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white54,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(UserProvider userProvider) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        final textColor = AppColors.getTextPrimary(isDark);
        
    return Column(
      children: [
        // Theme Settings Section
        _buildThemeSettingsSection(),
            const SizedBox(height: 24),
        
        if (userProvider.user != null) ...[
              _buildModernButton(
            text: AppStrings.editProfile,
                icon: Icons.edit_outlined,
                iconColor: AppColors.primary,
                backgroundColor: isDark 
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : AppColors.primary.withValues(alpha: 0.1),
                borderColor: AppColors.primary,
                textColor: textColor,
            onPressed: () {
              // TODO: Navigate to edit profile screen
            },
                isDark: isDark,
          ),
              const SizedBox(height: 12),
        ],
            _buildModernButton(
          text: userProvider.user != null ? AppStrings.signOut : AppStrings.signIn,
          icon: userProvider.user != null ? Icons.logout : Icons.login,
              iconColor: userProvider.user != null ? AppColors.error : AppColors.primary,
              backgroundColor: userProvider.user != null
                  ? (isDark 
                      ? AppColors.error.withValues(alpha: 0.15)
                      : AppColors.error.withValues(alpha: 0.1))
                  : (isDark 
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : AppColors.primary.withValues(alpha: 0.1)),
              borderColor: userProvider.user != null ? AppColors.error : AppColors.primary,
              textColor: textColor,
          onPressed: _isLoading ? null : () {
            if (userProvider.user != null) {
              _signOut();
            } else {
              // TODO: Navigate to sign in screen
            }
          },
          isLoading: _isLoading,
              isDark: isDark,
        ),
      ],
        );
      },
    );
  }

  Widget _buildModernButton({
    required String text,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required Color borderColor,
    required Color textColor,
    required VoidCallback? onPressed,
    bool isLoading = false,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      decoration: AppColors.getModernCardDecoration(isDark).copyWith(
        color: backgroundColor,
        border: Border.all(
          color: borderColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    text,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (isLoading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                    ),
                  )
                else
                  Icon(
                    Icons.chevron_right,
                    color: iconColor.withValues(alpha: 0.5),
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeSettingsSection() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.mysticalGradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.secondary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.palette,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tema Ayarları',
                    style: AppTextStyles.headingSmall.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Theme Mode Toggle
              _buildThemeToggle(themeProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeToggle(ThemeProvider themeProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: AppColors.textSecondary,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              themeProvider.isDarkMode ? 'Karanlık Tema' : 'Aydınlık Tema',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ],
        ),
        Switch(
          value: themeProvider.isDarkMode,
          onChanged: (value) {
            themeProvider.toggleTheme();
          },
          activeThumbColor: AppColors.primary,
        ),
      ],
    );
  }


  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays < 30) {
      return '${difference.inDays} ${AppStrings.daysAgo}';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${AppStrings.monthsAgo}';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${AppStrings.yearsAgo}';
    }
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    super.dispose();
  }
}
