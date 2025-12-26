import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_colors.dart';

/// Tema state yönetimi
/// Dark/Light theme ve mystical theme yönetimi
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _mysticalModeKey = 'mystical_mode';
  static const String _particleModeKey = 'particle_mode';
  static const String _glowModeKey = 'glow_mode';

  // Theme modes
  ThemeMode _themeMode = ThemeMode.dark; // Default to Dark Theme
  bool _isMysticalMode = true; // Default to Mystical Mode enabled
  bool _isParticleMode = true;
  bool _isGlowMode = true;
  bool _isPremiumTheme = false;

  // Getters
  ThemeMode get themeMode => _themeMode;
  bool get isMysticalMode => _isMysticalMode;
  bool get isParticleMode => _isParticleMode;
  bool get isGlowMode => _isGlowMode;
  bool get isPremiumTheme => _isPremiumTheme;
  // isDarkMode returns true if dark theme is selected OR if mystical mode is on (which uses dark background)
  // Use this for UI colors (text, backgrounds, etc.)
  bool get isDarkMode => _themeMode == ThemeMode.dark || _isMysticalMode;
  bool get isLightMode => _themeMode == ThemeMode.light && !_isMysticalMode;
  // isDarkThemeSelected returns true only if dark theme is explicitly selected (ignores mystical mode)
  // Use this for theme toggle switch
  bool get isDarkThemeSelected => _themeMode == ThemeMode.dark;

  // Initialize theme provider
  Future<void> initialize() async {
    await _loadThemeSettings();
    notifyListeners();
  }

  // Load theme settings from SharedPreferences
  Future<void> _loadThemeSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // If no saved theme, default to light mode
      final themeIndex = prefs.getInt(_themeKey);
      if (themeIndex != null) {
        _themeMode = ThemeMode.values[themeIndex];
      } else {
        _themeMode = ThemeMode.dark; // Default to Dark Theme
        _isMysticalMode = true; // Enable Mystical Mode by default
      }
      
      _isMysticalMode = prefs.getBool(_mysticalModeKey) ?? true; // Default true
      _isParticleMode = prefs.getBool(_particleModeKey) ?? true;
      _isGlowMode = prefs.getBool(_glowModeKey) ?? true;
    } catch (e) {
      debugPrint('Error loading theme settings: $e');
    }
  }

  // Save theme settings to SharedPreferences
  Future<void> _saveThemeSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setInt(_themeKey, _themeMode.index);
      await prefs.setBool(_mysticalModeKey, _isMysticalMode);
      await prefs.setBool(_particleModeKey, _isParticleMode);
      await prefs.setBool(_glowModeKey, _isGlowMode);
    } catch (e) {
      debugPrint('Error saving theme settings: $e');
    }
  }

  // Set theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _saveThemeSettings();
    notifyListeners();
  }

  // Toggle between dark and light mode
  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    // When switching to light theme, disable mystical mode since it uses dark background
    if (_themeMode == ThemeMode.light && _isMysticalMode) {
      _isMysticalMode = false;
    }
    await _saveThemeSettings();
    notifyListeners();
  }

  // Set mystical mode
  Future<void> setMysticalMode(bool enabled) async {
    _isMysticalMode = enabled;
    await _saveThemeSettings();
    notifyListeners();
  }

  // Toggle mystical mode
  Future<void> toggleMysticalMode() async {
    _isMysticalMode = !_isMysticalMode;
    await _saveThemeSettings();
    notifyListeners();
  }

  // Set particle mode
  Future<void> setParticleMode(bool enabled) async {
    _isParticleMode = enabled;
    await _saveThemeSettings();
    notifyListeners();
  }

  // Toggle particle mode
  Future<void> toggleParticleMode() async {
    _isParticleMode = !_isParticleMode;
    await _saveThemeSettings();
    notifyListeners();
  }

  // Set glow mode
  Future<void> setGlowMode(bool enabled) async {
    _isGlowMode = enabled;
    await _saveThemeSettings();
    notifyListeners();
  }

  // Toggle glow mode
  Future<void> toggleGlowMode() async {
    _isGlowMode = !_isGlowMode;
    await _saveThemeSettings();
    notifyListeners();
  }

  // Set premium theme
  Future<void> setPremiumTheme(bool enabled) async {
    _isPremiumTheme = enabled;
    notifyListeners();
  }

  // Get theme data based on current settings
  ThemeData getThemeData() {
    final isDark = _themeMode == ThemeMode.dark;
    final baseTheme = isDark ? ThemeData.dark() : ThemeData.light();
    
    // Light theme colors - Premium iOS 26 System
    final lightBackground = AppColors.premiumLightBackground;
    final lightSurface = AppColors.premiumLightSurface;
    final lightTextPrimary = AppColors.premiumLightTextPrimary; 
    final lightTextSecondary = AppColors.premiumLightTextSecondary;
    final lightBorder = Color(0xFFD6CDB8); // Warm subtle border
    
    // Dark theme colors
    final darkBackground = AppColors.background;
    final darkSurface = AppColors.surface;
    final darkTextPrimary = AppColors.textPrimary;
    final darkTextSecondary = AppColors.textSecondary;
    
    // Choose colors based on theme mode
    final backgroundColor = _isMysticalMode 
        ? (isDark ? darkBackground : lightBackground)
        : (isDark ? darkBackground : lightBackground);
    final surfaceColor = isDark ? darkSurface : lightSurface;
    final textPrimaryColor = isDark ? darkTextPrimary : lightTextPrimary; 
    final textSecondaryColor = isDark ? darkTextSecondary : lightTextSecondary;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.08) : lightBorder;
    
    return baseTheme.copyWith(
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: _isPremiumTheme ? AppColors.premium : AppColors.primary,
        secondary: AppColors.secondary,
        surface: surfaceColor,
        onSurface: textPrimaryColor,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _isMysticalMode ? Colors.transparent : (isDark ? Colors.transparent : AppColors.lightSurface),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimaryColor, // Açık temada koyu yazı
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: textPrimaryColor), // Açık temada koyu icon
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: _isGlowMode ? (isDark ? 8 : 0) : 0, // Light mode uses custom shadows in decoration, not elevation
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24), // iOS 26 Radius
          side: _isGlowMode 
            ? BorderSide(
                color: isDark 
                  ? AppColors.secondary.withValues(alpha: 0.3)
                  : Color(0xFFD6CDB8), // Warm border for light mode
                width: isDark ? 1 : 1.0,
              )
            : BorderSide.none,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? surfaceColor.withValues(alpha: 0.8) : Colors.white, // Input is WHITE on Light Mode
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _isPremiumTheme ? AppColors.premium : AppColors.premiumLightAccent),
        ),
        labelStyle: TextStyle(color: textSecondaryColor, fontWeight: FontWeight.w500), 
        hintStyle: TextStyle(color: isDark ? Colors.white38 : AppColors.premiumLightTextTertiary),
        prefixIconColor: textSecondaryColor,
        suffixIconColor: textSecondaryColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _isPremiumTheme ? AppColors.premium : AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: _isGlowMode ? 8 : 4,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _isPremiumTheme ? AppColors.premium : AppColors.primary,
        ),
      ),
      iconTheme: IconThemeData(
        color: textPrimaryColor, // Açık temada koyu icon
        size: 24,
      ),
      textTheme: baseTheme.textTheme.copyWith(
        displayLarge: TextStyle(
          color: textPrimaryColor,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          color: textPrimaryColor,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: TextStyle(
          color: textPrimaryColor,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        headlineLarge: TextStyle(
          color: textPrimaryColor,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: TextStyle(
          color: textPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: textPrimaryColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: textPrimaryColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        titleMedium: TextStyle(
          color: textPrimaryColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: TextStyle(
          color: textPrimaryColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: textPrimaryColor,
          fontSize: 16,
          fontWeight: FontWeight.normal,
        ),
        bodyMedium: TextStyle(
          color: textPrimaryColor,
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
        bodySmall: TextStyle(
          color: textSecondaryColor,
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
      ),
    );
  }

  // Get mystical theme data
  ThemeData getMysticalThemeData() {
    if (!_isMysticalMode) return getThemeData();
    
    final baseTheme = getThemeData();
    
    // Mystical mode always uses dark colors for mystical effect
    return baseTheme.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: _isPremiumTheme ? AppColors.premium : AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: _isGlowMode ? 12 : 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: _isGlowMode 
            ? BorderSide(color: AppColors.secondary.withValues(alpha: 0.5), width: 2)
            : BorderSide.none,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _isPremiumTheme ? AppColors.premium : AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: _isGlowMode ? 12 : 6,
          shadowColor: _isGlowMode ? AppColors.primary.withValues(alpha: 0.3) : null,
        ),
      ),
    );
  }

  // Get premium theme data
  ThemeData getPremiumThemeData() {
    return getMysticalThemeData().copyWith(
      colorScheme: getMysticalThemeData().colorScheme.copyWith(
        primary: AppColors.premium,
        secondary: AppColors.premium,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: AppColors.premium.withValues(alpha: 0.6), width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.premium,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 16,
          shadowColor: AppColors.premium.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  // Get current theme data
  ThemeData getCurrentThemeData() {
    if (_isPremiumTheme) {
      return getPremiumThemeData();
    } else if (_isMysticalMode) {
      return getMysticalThemeData();
    } else {
      return getThemeData();
    }
  }

  // Reset to default theme
  Future<void> resetToDefault() async {
    _themeMode = ThemeMode.dark; // Default Dark
    _isMysticalMode = true; // Default Mystical
    _isParticleMode = true;
    _isGlowMode = true;
    _isPremiumTheme = false;
    await _saveThemeSettings();
    notifyListeners();
  }

  // Get theme settings as map
  Map<String, dynamic> getThemeSettings() {
    return {
      'themeMode': _themeMode.index,
      'isMysticalMode': _isMysticalMode,
      'isParticleMode': _isParticleMode,
      'isGlowMode': _isGlowMode,
      'isPremiumTheme': _isPremiumTheme,
    };
  }

  // Apply theme settings from map
  Future<void> applyThemeSettings(Map<String, dynamic> settings) async {
    _themeMode = ThemeMode.values[settings['themeMode'] ?? 0];
    _isMysticalMode = settings['isMysticalMode'] ?? true;
    _isParticleMode = settings['isParticleMode'] ?? true;
    _isGlowMode = settings['isGlowMode'] ?? true;
    _isPremiumTheme = settings['isPremiumTheme'] ?? false;
    await _saveThemeSettings();
    notifyListeners();
  }

  // Check if theme is mystical
  bool get isMysticalTheme => _isMysticalMode;

  // Check if theme has particles
  bool get hasParticles => _isParticleMode;

  // Check if theme has glow effects
  bool get hasGlowEffects => _isGlowMode;

  // Check if theme is premium
  bool get isPremium => _isPremiumTheme;

  // Get theme name
  String get themeName {
    if (_isPremiumTheme) return 'Premium Mystical';
    if (_isMysticalMode) return 'Mystical';
    if (_themeMode == ThemeMode.dark) return 'Dark';
    return 'Light';
  }

  // Get theme description
  String get themeDescription {
    if (_isPremiumTheme) return 'Premium mystical theme with golden effects';
    if (_isMysticalMode) return 'Mystical theme with cosmic effects';
    if (_themeMode == ThemeMode.dark) return 'Dark theme for comfortable viewing';
    return 'Light theme for bright environments';
  }

  // Get theme icon
  IconData get themeIcon {
    if (_isPremiumTheme) return Icons.star;
    if (_isMysticalMode) return Icons.auto_awesome;
    if (_themeMode == ThemeMode.dark) return Icons.dark_mode;
    return Icons.light_mode;
  }

  // Get theme color
  Color get themeColor {
    if (_isPremiumTheme) return AppColors.premium;
    if (_isMysticalMode) return AppColors.primary;
    if (_themeMode == ThemeMode.dark) return Colors.grey[800]!;
    return Colors.grey[300]!;
  }

  // Get background gradient based on theme
  LinearGradient get backgroundGradient {
    if (_isMysticalMode) return AppColors.backgroundGradient;
    if (_themeMode == ThemeMode.dark) return AppColors.backgroundGradient;
    return AppColors.pearlBackgroundGradient; // Ultra-premium pearl glass
  }
}
