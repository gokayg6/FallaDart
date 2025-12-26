import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../core/providers/user_provider.dart';
import '../../core/widgets/mystical_loading.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/theme_provider.dart';
import 'login_screen.dart';
import '../main/main_screen.dart';
import '../premium/premium_onboarding_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Build tamamlandıktan sonra initialize et
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAuth();
    });
  }

  Future<void> _initializeAuth() async {
    try {
      // UserProvider artık otomatik olarak auth state değişikliklerini dinliyor
      // Sadece ilk yükleme için initialize et
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.initialize();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  Future<bool> _shouldShowPremiumOnboarding() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      // Premium kullanıcıysa gösterme
      // Debug modunda da göster (iptal butonu ile kapatılabilir)
      if (userProvider.user?.isPremium == true) {
        return false;
      }

      // Her zaman göster (premium kullanıcı değilse)
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isDark = themeProvider.isDarkMode;
        final textColor = AppColors.getTextPrimary(isDark);
        
        if (!_isInitialized) {
          return Scaffold(
            body: Container(
              decoration: BoxDecoration(gradient: themeProvider.backgroundGradient),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    MysticalLoading(
                      type: MysticalLoadingType.spinner,
                      size: 24,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AppStrings.loading,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            // Bağlantı durumu kontrol et
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                body: Container(
                  decoration: BoxDecoration(gradient: themeProvider.backgroundGradient),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        MysticalLoading(
                          type: MysticalLoadingType.spinner,
                          size: 24,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          AppStrings.verifyingIdentity,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            // Kullanıcı giriş yapmışsa premium onboarding kontrolü yap
            if (snapshot.hasData && snapshot.data != null) {
              return FutureBuilder<bool>(
                future: _shouldShowPremiumOnboarding(),
                builder: (context, onboardingSnapshot) {
                  if (onboardingSnapshot.connectionState == ConnectionState.waiting) {
                    return Scaffold(
                      body: Container(
                        decoration: BoxDecoration(gradient: themeProvider.backgroundGradient),
                        child: Center(
                          child: MysticalLoading(
                            type: MysticalLoadingType.spinner,
                            size: 24,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    );
                  }

                  // Premium onboarding gösterilmeli mi?
                  if (onboardingSnapshot.hasData && onboardingSnapshot.data == true) {
                    return const PremiumOnboardingScreen();
                  }

                  // Ana sayfaya git
                  return const MainScreen();
                },
              );
            }

            // Kullanıcı giriş yapmamışsa login ekranına yönlendir
            return const LoginScreen();
          },
        );
      },
    );
  }
}