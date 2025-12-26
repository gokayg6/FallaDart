import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/theme_provider.dart';
import 'coffee_user_info_screen.dart';

class CoffeeUploadPhotosScreen extends StatefulWidget {
  const CoffeeUploadPhotosScreen({super.key});

  @override
  State<CoffeeUploadPhotosScreen> createState() => _CoffeeUploadPhotosScreenState();
}

class _CoffeeUploadPhotosScreenState extends State<CoffeeUploadPhotosScreen> {
  final List<XFile> _photos = [];

  Future<void> _pickPhoto() async {
    if (_photos.length >= 5) return;
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _photos.add(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    bool canContinue = _photos.length >= 3;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Fotoğraf Yükle', style: TextStyle(color: AppColors.getTextPrimary(isDark))),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.getTextPrimary(isDark),
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: themeProvider.backgroundGradient),
        child: Column(
        children: [
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            children: List.generate(_photos.length + 1, (i) {
              if (i < _photos.length) {
                return Stack(
                  alignment: Alignment.topRight,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(
                        File(_photos[i].path),
                        width: 85,
                        height: 85,
                        fit: BoxFit.cover,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() => _photos.removeAt(i));
                      },
                      child: const CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.black54,
                        child: Icon(Icons.close, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                );
              } else if (_photos.length < 5) {
                return GestureDetector(
                  onTap: _pickPhoto,
                  child: Container(
                    width: 85,
                    height: 85,
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Center(
                      child: Icon(Icons.add_a_photo, color: Colors.white54, size: 30),
                    ),
                  ),
                );
              } else {
                return const SizedBox();
              }
            }),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: canContinue
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CoffeeUserInfoScreen(photos: _photos),
                      ),
                    );
                  }
                : null,
            icon: const Icon(Icons.arrow_forward_ios_rounded),
            label: const Text("Devam Et"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD26AFF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              disabledBackgroundColor: Colors.white12,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "En az 3, en fazla 5 fotoğraf yükleyiniz.",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.63),
              fontSize: 13.2,
            ),
          ),
        ],
        ),
      ),
    );
  }
}
