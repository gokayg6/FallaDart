import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../core/widgets/glassmorphism_components.dart';
import '../../core/widgets/glass_text_field.dart';
import '../../widgets/animations/mystical_particles.dart';
import '../../widgets/animations/glow_effect.dart';
import '../../core/widgets/mystical_dialog.dart';
import 'register_screen.dart';
import '../main/main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signInWithEmailAndPassword(
      _emailCtrl.text.trim(),
      _passCtrl.text,
    );

    if (success && mounted) {
      // Başarılı giriş sonrası ana sayfaya yönlendir
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } else if (mounted) {
      _showErrorDialog(authProvider.errorMessage ?? AppStrings.loginFailed);
    }
  }

  Future<void> _guest() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signInAnonymously();

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } else if (mounted) {
      _showErrorDialog(authProvider.errorMessage ?? AppStrings.guestLoginFailed);
    }
  }

  void _showErrorDialog(String message) {
    MysticalDialog.showError(
      context: context,
      title: AppStrings.loginError,
      message: message,
    );
  }

  Future<void> _resetPassword() async {
    if (_emailCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.pleaseEnterEmail)),
      );
      return;
    }

    print('🔄 Şifre sıfırlama isteği: ${_emailCtrl.text.trim()}');
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.resetPassword(_emailCtrl.text.trim());

    if (success && mounted) {
      print('✅ Şifre sıfırlama başarılı');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.passwordResetEmailSent),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );
    } else if (mounted) {
      print('❌ Şifre sıfırlama başarısız: ${authProvider.errorMessage}');
      _showErrorDialog(authProvider.errorMessage ?? AppStrings.passwordResetFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      body: Stack(
        children: [
          // Background with particles
          Container(
            decoration: BoxDecoration(gradient: themeProvider.backgroundGradient),
            child: const MysticalParticles(
              type: ParticleType.floating,
              particleCount: 20, // Increased for liquid feel
              isActive: true,
            ),
          ),
          
          // Main content
          Builder(
            builder: (context) {
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: GlassCard(
                      isHero: true,
                      borderRadius: 32,
                      padding: const EdgeInsets.all(32),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Logo and title
                            _buildHeader(),
                            const SizedBox(height: 32),
                            
                            // Email field
                            _buildEmailField(),
                            const SizedBox(height: 16),
                            
                            // Password field
                            _buildPasswordField(),
                            const SizedBox(height: 8),
                            
                            // Forgot password
                            _buildForgotPassword(),
                            const SizedBox(height: 24),
                            
                            // Login button
                            _buildLoginButton(),
                            const SizedBox(height: 16),
                            
                            // Register link
                            _buildRegisterLink(),
                            const SizedBox(height: 24),
                            
                            // Divider
                            _buildDivider(),
                            const SizedBox(height: 24),
                            
                            // Social Sign-In
                            _buildSocialSignIn(),
                            const SizedBox(height: 16),
                            
                            // Guest button
                            _buildGuestButton(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final textColor = AppColors.getTextPrimary(isDark);
    final textSecondaryColor = AppColors.getTextSecondary(isDark);
    
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Image.asset(
            'assets/icons/fallalogo.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
            Icons.auto_awesome,
            size: 40,
            color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Falla',
          style: AppTextStyles.headingLarge.copyWith(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.welcomeToMysticalWorld,
          style: TextStyle(
            color: textSecondaryColor,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return GlassTextField(
      controller: _emailCtrl,
      label: AppStrings.email,
      hint: "example@email.com",
      prefixIcon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      validator: Validators.email,
    );
  }

  Widget _buildPasswordField() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final iconColor = isDark ? Colors.white70 : AppColors.slateTextMuted;

    return GlassTextField(
      controller: _passCtrl,
      label: AppStrings.password,
      hint: "********",
      prefixIcon: Icons.lock_outline,
      obscureText: _obscurePassword,
      validator: Validators.password,
      suffixIcon: IconButton(
        icon: Icon(
          _obscurePassword ? Icons.visibility : Icons.visibility_off, 
          color: iconColor,
        ),
        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
      ),
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: _resetPassword,
        child: Text(
          AppStrings.forgotPassword,
          style: TextStyle(color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return GlassButton(
          text: AppStrings.login,
          onPressed: authProvider.isLoading ? null : _login,
          isLoading: authProvider.isLoading,
          icon: Icons.login,
          useMoonlight: true,
        );
      },
    );
  }

  Widget _buildRegisterLink() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final textSecondaryColor = AppColors.getTextSecondary(isDark);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          AppStrings.dontHaveAccount,
          style: TextStyle(color: textSecondaryColor),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RegisterScreen()),
            );
          },
          child: Text(
            AppStrings.register,
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final dividerColor = AppColors.getDividerColor(isDark);
    final textSecondaryColor = AppColors.getTextSecondary(isDark);
    
    return Row(
      children: [
        Expanded(child: Divider(color: dividerColor)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            AppStrings.or,
            style: TextStyle(
              color: textSecondaryColor,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(child: Divider(color: dividerColor)),
      ],
    );
  }

Widget _buildGuestButton() {
  return Consumer<AuthProvider>(
    builder: (context, authProvider, child) {
      return GlassButton(
        text: AppStrings.continueAsGuest,
        onPressed: authProvider.isLoading ? null : _guest,
        isLoading: authProvider.isLoading,
        icon: Icons.person_outline,
        useMoonlight: false, // Secondary style
      );
    },
  );
}

  Widget _buildSocialSignIn() {
    return Column(
      children: [
        // Google Sign-In
        _buildSocialButton(
          icon: 'assets/icons/google.png',
          fallbackIcon: Icons.g_mobiledata,
          text: 'Google ile Giriş Yap',
          onPressed: _signInWithGoogle,
          backgroundColor: Colors.white,
          textColor: const Color(0xFF1F1F1F),
        ),
        const SizedBox(height: 12),
        // Apple Sign-In
        _buildSocialButton(
          icon: 'assets/icons/apple.png',
          fallbackIcon: Icons.apple,
          text: 'Apple ile Giriş Yap',
          onPressed: _signInWithApple,
          backgroundColor: Colors.black,
          textColor: Colors.white,
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required String icon,
    required IconData fallbackIcon,
    required String text,
    required VoidCallback onPressed,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Colors.grey.withOpacity(0.3),
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              icon,
              width: 24,
              height: 24,
              errorBuilder: (_, __, ___) => Icon(
                fallbackIcon,
                size: 24,
                color: textColor,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    // TODO: Implement Google Sign-In
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Google Sign-In yakında eklenecek'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _signInWithApple() async {
    // TODO: Implement Apple Sign-In
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Apple Sign-In yakında eklenecek'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
