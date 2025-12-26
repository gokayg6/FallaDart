import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/theme_provider.dart';
import 'coffee_upload_photos_screen.dart';

class CoffeeEntryScreen extends StatelessWidget {
  const CoffeeEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Kahve Falı Başlat', style: TextStyle(color: AppColors.getTextPrimary(isDark))),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.getTextPrimary(isDark),
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(gradient: themeProvider.backgroundGradient),
        child: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Modern Lottie veya animasyonlu icon:
              SizedBox(
                height: 120,
                child: Image.asset("assets/images/fallalogo.png"),
              ),
              const SizedBox(height: 32),
              Text(
                "Kahve fincanı ve tabağının en az 3, en fazla 5 fotoğrafını yükle.\nDevam etmek için başla!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.getTextSecondary(isDark),
                  fontSize: 16.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CoffeeUploadPhotosScreen()),
                  );
                },
                icon: const Icon(Icons.coffee),
                label: const Text("Kahve Falı Yükle"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD26AFF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
                ),
              ),
            ],
            ),
      ),
        ),
      ),
    );
  }
}
