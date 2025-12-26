import 'package:flutter/material.dart';

class AppColors {
  // Ana renkler
  static const Color primary   = Color(0xFFFF4DA6); // Falla Magenta
  static const Color secondary = Color(0xFF3EE3D5); // Aura Aqua
  static const Color accent    = Color(0xFF8A7BFF); // Mistik Mor
  static const Color background= Color(0xFF0F0F1A); // Masterpiece Dark
  static const Color surface   = Color(0xFF121735); // Derin Yüzey
  
  // Gradient renkler
  static const LinearGradient mysticalGradient = LinearGradient(
    colors: [Color(0xFF1D163C), Color(0xFF30206A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFD26AFF), Color(0xFF9B51E0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFF9B51E0), Color(0xFF6A4C93)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFE0C88F), Color(0xFFD4AF37)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF2B224F), Color(0xFF594099)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient premiumGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Background gradient (dark theme) - Masterpiece Glass Settings
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0F0F1A), Color(0xFF1A1A2E)],
  );
  
  // Background gradient (light theme) - Masterpiece Glass Settings 
  static const LinearGradient lightBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF0F4F8), Color(0xFFE6EAF0)],
  );
  
  // Karma gradient
  static const LinearGradient karmaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [karma, Color(0xFFF4E4BC)],
  );
  
  // Kart renkleri
  static const Color cardGlow = Color(0xFF6A4C93);
  static const Color cardShadow = Colors.black54;
  static const Color shadowColor = Colors.black;
  
  // Karma rengi
  static const Color karma = Color(0xFFE0C88F);
  
  // Test type colors
  static const Color love = Color(0xFFFF69B4);
  static const Color cardBackground = Color(0xFF2B224F);
  
  // Durum renkleri
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53E3E);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);
  
  // Metin renkleri
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color textTertiary = Colors.white54;
  static const Color textDisabled = Colors.white38;
  
  // Şeffaflık renkleri
  static Color whiteOpacity(double opacity) => Colors.white.withValues(alpha: opacity);
  static Color blackOpacity(double opacity) => Colors.black.withValues(alpha: opacity);
  
  // Başarı gradyanı
  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [success, Color(0xFF4CAF50)],
  );
  
  // Aşk gradyanı
  static const LinearGradient loveGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE91E63), Color(0xFFFF6B9D)],
  );
  
  // Kişilik gradyanı
  static const LinearGradient personalityGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF9C27B0), Color(0xFFBA68C8)],
  );
  
  // Burç gradyanı
  static const LinearGradient zodiacGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3F51B5), Color(0xFF7986CB)],
  );
  
  // Numeroloji gradyanı
  static const LinearGradient numerologyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00BCD4), Color(0xFF4DD0E1)],
  );
  
  // Yüzey rengi
  static const Color surfaceColor = Color(0xFF1A1A2E);
  
  // Rüya rengi
  static const Color dream = Color(0xFF6A5ACD);
  
  // Rüya gradyanı
  static const LinearGradient dreamGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6A5ACD), Color(0xFF9370DB)],
  );
  
  // Premium rengi
  static const Color premium = Color(0xFFFFD700);
  
  // Border rengi
  static const Color border = Color(0xFF2A2A2A);
  
  // Modern tasarım için glassmorphism efektleri
  static Color get glassBackground => Colors.white.withValues(alpha: 0.05);
  static Color get glassBorder => Colors.white.withValues(alpha: 0.1);
  
  // Modern card tasarımı için
  static BoxDecoration get modernCardDecoration => BoxDecoration(
    color: surface.withValues(alpha: 0.6),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(
      color: Colors.white.withValues(alpha: 0.08),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.2),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: primary.withValues(alpha: 0.05),
        blurRadius: 30,
        spreadRadius: -5,
      ),
    ],
  );
  
  // Glassmorphism card decoration
  static BoxDecoration get glassCardDecoration => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withValues(alpha: 0.08),
        Colors.white.withValues(alpha: 0.03),
      ],
    ),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(
      color: Colors.white.withValues(alpha: 0.1),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.15),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
    ],
  );
  
  // Minimal card decoration (panel tasarımı yerine)
  static BoxDecoration get minimalCardDecoration => BoxDecoration(
    color: surface.withValues(alpha: 0.4),
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.15),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ],
  );

  // ==================== LIGHT THEME COLORS ====================
  
  // Light theme base colors - Masterpiece Light
  static const Color lightBackground = Color(0xFFF0F4F8);
  static const Color lightSurface = Color(0xFFFFF5E6);
  static const Color lightCardBackground = Color(0xFFFFEED5);
  
  // Light theme text colors
  static Color get lightTextPrimary => Colors.grey[900]!;
  static Color get lightTextSecondary => Colors.grey[700]!;
  static Color get lightTextTertiary => Colors.grey[600]!;
  static Color get lightTextDisabled => Colors.grey[400]!;
  
  // Light theme card gradient - Cream tones
  static LinearGradient get lightCardGradient => LinearGradient(
    colors: [Color(0xFFFFEED5), Color(0xFFFFE8D0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Light theme mystical gradient (softer version) - Cream tones
  static LinearGradient get lightMysticalGradient => LinearGradient(
    colors: [Color(0xFFFFF0E0), Color(0xFFFFE8D0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Modern card decoration for light theme
  static BoxDecoration get modernCardDecorationLight => BoxDecoration(
    color: lightSurface,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(
      color: Colors.grey.withValues(alpha: 0.15),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: primary.withValues(alpha: 0.03),
        blurRadius: 30,
        spreadRadius: -5,
      ),
    ],
  );

  // ==================== MISSING COLORS RESTORED ====================
  // Restored to support LiquidGlassNavbar and ThemeProvider features
  
  static const Color champagneGold = Color(0xFFF7E7CE);
  static const Color textMuted = Colors.white60;
  
  // Mystic Purple colors (for Coffee Fortune Screen)
  static const Color mysticPurpleDark = Color(0xFF0D0714);
  static const Color mysticPurpleMid = Color(0xFF1A0F2E);
  static const Color premiumDarkBgEnd = Color(0xFF150B24);
  static const Color mysticPurpleAccent = Color(0xFF8B5CF6);
  static const Color warmIvory = Color(0xFFF3ECDC);
  static const Color premiumDarkBg = Color(0xFF0D0714);
  static const Color subtleBronze = Color(0xFFB8A46A);
  static const Color deepGold = Color(0xFFC4A962);
  
  // Premium Dark Gradient (Mystic Purple Theme)
  static const LinearGradient premiumDarkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      mysticPurpleDark,
      mysticPurpleMid,
      premiumDarkBgEnd,
    ],
    stops: [0.0, 0.5, 1.0],
  );
  
  // Champagne Gold Gradient
  static const LinearGradient champagneGoldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [warmIvory, champagneGold, deepGold],
  );
  
  // Premium Glassmorphism
  static Color get premiumGlassBackground => Colors.white.withValues(alpha: 0.10);
  static Color get premiumGlassBorder => Colors.white.withValues(alpha: 0.15);
  static Color get premiumGlassHighlight => Colors.white.withValues(alpha: 0.08);
  static Color get premiumGoldGlow => champagneGold.withValues(alpha: 0.30);
  
  static LinearGradient get premiumGlassGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white.withValues(alpha: 0.12),
      Colors.white.withValues(alpha: 0.05),
    ],
  );
  
  // Premium Card Decoration
  static BoxDecoration get premiumGlassCardDecoration => BoxDecoration(
    gradient: premiumGlassGradient,
    borderRadius: BorderRadius.circular(22),
    border: Border.all(
      color: premiumGlassBorder,
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.35),
        blurRadius: 30,
        offset: const Offset(0, 8),
      ),
    ],
  );
  
  // Premium Hero Card Decoration
  static BoxDecoration get premiumHeroCardDecoration => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        champagneGold.withValues(alpha: 0.25),
        subtleBronze.withValues(alpha: 0.15),
      ],
    ),
    borderRadius: BorderRadius.circular(28),
    border: Border.all(
      color: champagneGold.withValues(alpha: 0.40),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: subtleBronze.withValues(alpha: 0.25),
        blurRadius: 40,
        offset: const Offset(0, 12),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.30),
        blurRadius: 20,
        offset: const Offset(0, 4),
      ),
    ],
  );
  
  // Selected Card Decoration with Gold Glow
  static BoxDecoration get premiumSelectedCardDecoration => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        champagneGold.withValues(alpha: 0.20),
        deepGold.withValues(alpha: 0.12),
      ],
    ),
    borderRadius: BorderRadius.circular(22),
    border: Border.all(
      color: champagneGold.withValues(alpha: 0.60),
      width: 2,
    ),
    boxShadow: [
      BoxShadow(
        color: champagneGold.withValues(alpha: 0.30),
        blurRadius: 20,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.40),
        blurRadius: 30,
        offset: const Offset(0, 8),
      ),
    ],
  );
  
  // ==================== ULTRA-PREMIUM DESIGN TOKENS ====================
  // iOS 26 Glassmorphism + Liquid Glass Hybrid System
  
  // ===================== LIGHT MODE: PEARL GLASS SYSTEM =====================
  
  // Base: Soft Pearl / Porcelain Layers
  static const Color pearlWhite = Color(0xFFF8F9FC);        // Primary background
  static const Color porcelainMist = Color(0xFFF0F2F7);     // Secondary surface
  static const Color pearlGlassBase = Color(0xFFFCFDFE);    // Glass card base
  static const Color ivoryFrost = Color(0xFFF5F6F9);        // Frosted overlay
  
  // Light Glass Opacity Colors
  static Color get pearlGlassOpaque => Colors.white.withOpacity(0.85);
  static Color get pearlGlassSemi => Colors.white.withOpacity(0.75);
  static Color get pearlGlassMid => Colors.white.withOpacity(0.60);
  static Color get pearlGlassBorderLight => Colors.white.withOpacity(0.90);
  
  // Light Mode Text (Strong Contrast)
  static const Color slateText = Color(0xFF1E293B);         // Primary text (slate-800)
  static const Color slateTextMid = Color(0xFF475569);      // Secondary (slate-600)
  static const Color slateTextMuted = Color(0xFF64748B);    // Tertiary (slate-500)
  static const Color slateTextDisabled = Color(0xFF94A3B8); // Disabled (slate-400)
  
  // ===================== MOONLIGHT CYAN ACCENT SYSTEM =====================
  // Replaces yellow navbar hover with elegant icy blue
  
  static const Color moonlightCyan = Color(0xFF7DD3FC);     // Primary accent (sky-300)
  static const Color icyBlue = Color(0xFFBAE6FD);           // Hover state (sky-200)
  static const Color aquaIndigo = Color(0xFF818CF8);        // Active glow (indigo-400)
  static const Color deepAqua = Color(0xFF38BDF8);          // Pressed state (sky-400)
  static const Color frostCyan = Color(0xFFE0F2FE);         // Subtle bg (sky-100)
  
  // Moonlight Gradients
  static const LinearGradient moonlightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [moonlightCyan, aquaIndigo],
  );
  
  static const LinearGradient icyGlowGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [icyBlue, moonlightCyan],
  );
  
  // ===================== DARK MODE: RICH DEPTH SYSTEM =====================
  
  // Enhanced Dark Base (Deeper, Richer)
  static const Color abyssBlack = Color(0xFF08080F);        // Deepest black
  static const Color richSurface = Color(0xFF101018);       // Rich surface
  static const Color voidPurple = Color(0xFF0C0A15);        // Mystic void
  
  // Dark Glow Effects
  static Color get mysticGlow => mysticPurpleAccent.withOpacity(0.15);
  static Color get cyanGlow => moonlightCyan.withOpacity(0.20);
  static Color get goldGlow => champagneGold.withOpacity(0.25);
  
  // ===================== LIGHT MODE GLASS DECORATIONS =====================
  
  // Pearl Glass Card (Light Mode)
  static BoxDecoration get pearlGlassCardDecoration => BoxDecoration(
    color: pearlGlassOpaque,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withOpacity(0.95),
        pearlGlassSemi,
      ],
    ),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(
      color: Colors.white.withOpacity(0.6),
      width: 1.5,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: Colors.black.withOpacity(0.02),
        blurRadius: 40,
        spreadRadius: -10,
      ),
    ],
  );
  
  // Frosted Pearl Card (Light Mode with blur support)
  static BoxDecoration get frostedPearlDecoration => BoxDecoration(
    color: ivoryFrost.withOpacity(0.80),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: Colors.white.withOpacity(0.5),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.03),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ],
  );
  
  // Light Mode Navbar Glass
  static BoxDecoration get lightNavbarGlassDecoration => BoxDecoration(
    color: Colors.white.withOpacity(0.80),
    borderRadius: const BorderRadius.only(
      topLeft: Radius.circular(28),
      topRight: Radius.circular(28),
    ),
    border: Border(
      top: BorderSide(color: Colors.white.withOpacity(0.3), width: 1),
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 20,
        offset: const Offset(0, -4),
      ),
    ],
  );
  
  // ===================== DARK MODE GLASS DECORATIONS =====================
  
  // Enhanced Dark Glass Card
  static BoxDecoration get darkGlassCardDecoration => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withOpacity(0.12),
        Colors.white.withOpacity(0.04),
      ],
    ),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(
      color: Colors.white.withOpacity(0.12),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: mysticGlow,
        blurRadius: 30,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: Colors.black.withOpacity(0.40),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  );
  
  // Dark Mode Navbar Glass
  static BoxDecoration get darkNavbarGlassDecoration => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.white.withOpacity(0.08),
        Colors.white.withOpacity(0.03),
      ],
    ),
    borderRadius: const BorderRadius.only(
      topLeft: Radius.circular(28),
      topRight: Radius.circular(28),
    ),
    border: Border(
      top: BorderSide(color: Colors.white.withOpacity(0.10), width: 0.5),
    ),
  );
  
  // ===================== THEME-AWARE GLASS HELPERS =====================
  
  /// Get glass card decoration based on theme
  static BoxDecoration getGlassCardDecoration(bool isDark) =>
      isDark ? darkGlassCardDecoration : pearlGlassCardDecoration;
  
  /// Get navbar decoration based on theme
  static BoxDecoration getNavbarDecoration(bool isDark) =>
      isDark ? darkNavbarGlassDecoration : lightNavbarGlassDecoration;
  
  /// Get navbar active color (moonlight cyan for both themes)
  static Color getNavbarActiveColor(bool isDark) =>
      isDark ? moonlightCyan : aquaIndigo;
  
  /// Get navbar inactive color based on theme
  static Color getNavbarInactiveColor(bool isDark) =>
      isDark ? Colors.white.withOpacity(0.5) : slateTextMuted;
  
  /// Get navbar active glow based on theme
  static BoxShadow getNavbarActiveGlow(bool isDark) => BoxShadow(
    color: (isDark ? moonlightCyan : aquaIndigo).withOpacity(0.35),
    blurRadius: 20,
    spreadRadius: 4,
  );
  
  // ===================== LIGHT MODE BACKGROUND GRADIENTS =====================
  
  // Premium Pearl Background (replaces flat white)
  static const LinearGradient pearlBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      pearlWhite,
      porcelainMist,
      ivoryFrost,
    ],
    stops: [0.0, 0.5, 1.0],
  );
  
  // Soft ambient light gradient overlay
  static LinearGradient get ambientLightGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      moonlightCyan.withOpacity(0.03),
      Colors.transparent,
      aquaIndigo.withOpacity(0.02),
    ],
    stops: const [0.0, 0.5, 1.0],
  );
  
  // Legacy compatibility
  static const Color premiumLightBackground = pearlWhite;
  static const Color premiumLightSurface = porcelainMist;
  static const Color premiumLightTextPrimary = slateText;
  static const Color premiumLightTextSecondary = slateTextMid;
  static const Color premiumLightTextTertiary = slateTextMuted;
  static const Color premiumLightAccent = aquaIndigo;


  // ==================== THEME-AWARE HELPERS ====================
  
  /// Get text primary color based on theme
  static Color getTextPrimary(bool isDark) => isDark ? textPrimary : lightTextPrimary;
  
  /// Get text secondary color based on theme
  static Color getTextSecondary(bool isDark) => isDark ? textSecondary : lightTextSecondary;
  
  /// Get text tertiary color based on theme
  static Color getTextTertiary(bool isDark) => isDark ? textTertiary : lightTextTertiary;
  
  /// Get text disabled color based on theme
  static Color getTextDisabled(bool isDark) => isDark ? textDisabled : lightTextDisabled;
  
  /// Get card background color based on theme
  static Color getCardBackground(bool isDark) => isDark ? cardBackground : lightCardBackground;
  
  /// Get surface color based on theme
  static Color getSurface(bool isDark) => isDark ? surface : lightSurface;
  
  /// Get background color based on theme
  static Color getBackground(bool isDark) => isDark ? background : lightBackground;
  
  /// Get card gradient based on theme
  static LinearGradient getCardGradient(bool isDark) => isDark ? cardGradient : lightCardGradient;
  
  /// Get mystical gradient based on theme
  static LinearGradient getMysticalGradient(bool isDark) => isDark ? mysticalGradient : lightMysticalGradient;
  
  /// Get modern card decoration based on theme
  static BoxDecoration getModernCardDecoration(bool isDark) => 
      isDark ? modernCardDecoration : modernCardDecorationLight;
  
  /// Get border color based on theme
  static Color getBorderColor(bool isDark) => 
      isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.15);
  
  /// Get icon color based on theme
  static Color getIconColor(bool isDark) => isDark ? Colors.white : Colors.grey[800]!;
  
  /// Get secondary icon color based on theme
  static Color getSecondaryIconColor(bool isDark) => isDark ? Colors.white70 : Colors.grey[600]!;
  
  /// Get divider color based on theme
  static Color getDividerColor(bool isDark) => 
      isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.2);
  
  /// Get container background for cards/sections based on theme
  static Color getContainerBackground(bool isDark) => 
      isDark ? Colors.white.withValues(alpha: 0.1) : Color(0xFFFFEED5);
  
  /// Get container border color based on theme
  static Color getContainerBorder(bool isDark) => 
      isDark ? Colors.white.withValues(alpha: 0.2) : Colors.grey[400]!;
  
  /// Get input text color based on theme
  static Color getInputTextColor(bool isDark) => 
      isDark ? Colors.white : Colors.grey[900]!;
  
  /// Get input hint color based on theme
  static Color getInputHintColor(bool isDark) => 
      isDark ? Colors.white38 : Colors.grey[500]!;
  
  /// Get input background color based on theme
  static Color getInputBackground(bool isDark) => 
      isDark ? Colors.white.withValues(alpha: 0.08) : Color(0xFFFFE8D0);
  
  /// Get input border color based on theme
  static Color getInputBorderColor(bool isDark) => 
      isDark ? Colors.white.withValues(alpha: 0.15) : Colors.grey[300]!;
}