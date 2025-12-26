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
import '../../core/widgets/glass_picker_sheet.dart';
import '../../widgets/animations/mystical_particles.dart';
import '../../widgets/animations/glow_effect.dart';
import '../../core/widgets/terms_of_service_dialog.dart';
import '../../core/widgets/mystical_dialog.dart';
import '../main/main_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _pass2Ctrl = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscurePassword2 = true;
  DateTime? _selectedBirthDate;
  String? _selectedZodiacSign;
  String? _selectedGender;

  List<String> get _zodiacSigns {
    return [
      AppStrings.aries, AppStrings.taurus, AppStrings.gemini, 
      AppStrings.cancer, AppStrings.leo, AppStrings.virgo,
      AppStrings.libra, AppStrings.scorpio, AppStrings.sagittarius, 
      AppStrings.capricorn, AppStrings.aquarius, AppStrings.pisces
    ];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _pass2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBirthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.pleaseSelectBirthDate)),
      );
      return;
    }
    if (_selectedZodiacSign == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.pleaseSelectZodiac)),
      );
      return;
    }
    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.pleaseSelectGender)),
      );
      return;
    }

    // Show terms of service dialog first
    final accepted = await TermsOfServiceDialog.show(context);
    
    if (accepted != true) {
      // User rejected terms
      await MysticalDialog.showInfo(
        context: context,
        title: AppStrings.termsNotAccepted,
        message: AppStrings.termsMustBeAccepted,
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.registerWithEmailAndPassword(
      _emailCtrl.text.trim(),
      _passCtrl.text,
      _nameCtrl.text.trim(),
      _selectedBirthDate!,
      AppStrings.zodiacSignToTurkish(_selectedZodiacSign) ?? _selectedZodiacSign!,
      _selectedGender!,
    );

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } else if (mounted) {
      _showErrorDialog(authProvider.errorMessage ?? AppStrings.registrationFailed);
    }
  }

  void _showErrorDialog(String message) {
    MysticalDialog.showError(
      context: context,
      title: AppStrings.registrationError,
      message: message,
    );
  }

  Future<void> _selectBirthDate() async {
    final picked = await GlassPickerSheet.pickDate(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      isDark: Provider.of<ThemeProvider>(context, listen: false).isDarkMode,
    );
    
    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
        _selectedZodiacSign = _calculateZodiacSign(picked);
      });
    }
  }

  String _calculateZodiacSign(DateTime birthDate) {
    final month = birthDate.month;
    final day = birthDate.day;
    
    if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) return AppStrings.aries;
    if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) return AppStrings.taurus;
    if ((month == 5 && day >= 21) || (month == 6 && day <= 20)) return AppStrings.gemini;
    if ((month == 6 && day >= 21) || (month == 7 && day <= 22)) return AppStrings.cancer;
    if ((month == 7 && day >= 23) || (month == 8 && day <= 22)) return AppStrings.leo;
    if ((month == 8 && day >= 23) || (month == 9 && day <= 22)) return AppStrings.virgo;
    if ((month == 9 && day >= 23) || (month == 10 && day <= 22)) return AppStrings.libra;
    if ((month == 10 && day >= 23) || (month == 11 && day <= 21)) return AppStrings.scorpio;
    if ((month == 11 && day >= 22) || (month == 12 && day <= 21)) return AppStrings.sagittarius;
    if ((month == 12 && day >= 22) || (month == 1 && day <= 19)) return AppStrings.capricorn;
    if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) return AppStrings.aquarius;
    return AppStrings.pisces;
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
              type: ParticleType.swirling,
              particleCount: 15,
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
                            // Header
                            _buildHeader(),
                            const SizedBox(height: 32),
                            
                            // Name field
                            _buildNameField(),
                            const SizedBox(height: 16),
                            
                            // Email field
                            _buildEmailField(),
                            const SizedBox(height: 16),
                            
                            // Password field
                            _buildPasswordField(),
                            const SizedBox(height: 16),
                            
                            // Confirm password field
                            _buildConfirmPasswordField(),
                            const SizedBox(height: 16),
                            
                            // Birth date field
                            _buildBirthDateField(),
                            const SizedBox(height: 16),
                            
                            // Zodiac sign field
                            _buildZodiacField(),
                            const SizedBox(height: 16),
                            
                            // Gender field
                            _buildGenderField(),
                            const SizedBox(height: 24),
                            
                            // Register button
                            _buildRegisterButton(),
                            const SizedBox(height: 16),
                            
                            // Login link
                            _buildLoginLink(),
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
            gradient: AppColors.secondaryGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withValues(alpha: 0.3),
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
              Icons.person_add,
              size: 40,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          AppStrings.register,
          style: AppTextStyles.headingLarge.copyWith(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.joinMysticalWorld,
          style: TextStyle(
            color: textSecondaryColor,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return GlassTextField(
      controller: _nameCtrl,
      label: AppStrings.fullName,
      hint: "John Doe",
      prefixIcon: Icons.person_outline,
      validator: Validators.name,
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

  Widget _buildConfirmPasswordField() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final iconColor = isDark ? Colors.white70 : AppColors.slateTextMuted;

    return GlassTextField(
      controller: _pass2Ctrl,
      label: AppStrings.confirmPassword,
      hint: "********",
      prefixIcon: Icons.lock_outline,
      obscureText: _obscurePassword2,
      validator: (v) => Validators.confirmPassword(v, _passCtrl.text),
      suffixIcon: IconButton(
        icon: Icon(
          _obscurePassword2 ? Icons.visibility : Icons.visibility_off, 
          color: iconColor,
        ),
        onPressed: () => setState(() => _obscurePassword2 = !_obscurePassword2),
      ),
    );
  }

  Widget _buildBirthDateField() {
    return GlassTextField(
      controller: TextEditingController(
        text: _selectedBirthDate != null
            ? '${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year}'
            : '',
      ),
      label: AppStrings.birthDate,
      hint: AppStrings.selectBirthDate,
      prefixIcon: Icons.calendar_today,
      readOnly: true,
      onTap: _selectBirthDate,
      suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
    );
  }

  Future<void> _selectZodiac() async {
    final picked = await GlassPickerSheet.pickItem(
      context: context,
      items: _zodiacSigns,
      initialIndex: _selectedZodiacSign != null ? _zodiacSigns.indexOf(_selectedZodiacSign!) : 0,
      isDark: Provider.of<ThemeProvider>(context, listen: false).isDarkMode,
    );
    if (picked != null) {
      setState(() {
        _selectedZodiacSign = picked;
      });
    }
  }

  Widget _buildZodiacField() {
    return GlassTextField(
      controller: TextEditingController(text: _selectedZodiacSign ?? ''),
      label: AppStrings.zodiac,
      hint: AppStrings.selectZodiac,
      prefixIcon: Icons.star_border,
      readOnly: true,
      onTap: _selectZodiac,
      suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
    );
  }

  Future<void> _selectGender() async {
    final genderOptions = [
      AppStrings.isEnglish ? 'Male' : 'Erkek',
      AppStrings.isEnglish ? 'Female' : 'Kadın',
      AppStrings.isEnglish ? 'Other' : 'Diğer',
    ];
    
    final picked = await GlassPickerSheet.pickItem(
      context: context,
      items: genderOptions,
      initialIndex: _selectedGender != null ? genderOptions.indexOf(_selectedGender!) : 0,
      isDark: Provider.of<ThemeProvider>(context, listen: false).isDarkMode,
    );
     if (picked != null) {
      setState(() {
        _selectedGender = picked;
      });
    }
  }

  Widget _buildGenderField() {
    return GlassTextField(
      controller: TextEditingController(text: _selectedGender ?? ''),
      label: AppStrings.gender,
      hint: AppStrings.selectGender,
      prefixIcon: Icons.people_outline,
      readOnly: true,
      onTap: _selectGender,
      suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
    );
  }

  Widget _buildRegisterButton() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return GlassButton(
          text: AppStrings.register,
          onPressed: authProvider.isLoading ? null : _register,
          isLoading: authProvider.isLoading,
          icon: Icons.person_add,
          useMoonlight: true,
        );
      },
    );
  }

  Widget _buildLoginLink() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final textSecondaryColor = AppColors.getTextSecondary(isDark);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          AppStrings.alreadyHaveAccount,
          style: TextStyle(color: textSecondaryColor),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            AppStrings.login,
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}