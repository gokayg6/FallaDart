import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/firebase_service.dart';
import '../../core/utils/helpers.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../providers/theme_provider.dart';
import '../../core/providers/user_provider.dart';
import 'dart:io';

class LoveCandidateFormScreen extends StatefulWidget {
  const LoveCandidateFormScreen({super.key});

  @override
  State<LoveCandidateFormScreen> createState() => _LoveCandidateFormScreenState();
}

class _LoveCandidateFormScreenState extends State<LoveCandidateFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _firebaseService = FirebaseService();
  final _picker = ImagePicker();
  
  DateTime? _birthDate;
  String? _zodiacSign;
  String? _relationshipType;
  File? _avatarFile;
  String? _avatarUrl;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _avatarFile = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Resim seçilemedi: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _onBirthDateChanged(DateTime? date) {
    if (date != null) {
      setState(() {
        _birthDate = date;
        _zodiacSign = Helpers.calculateZodiacSign(date);
      });
    }
  }

  Future<void> _saveCandidate() async {
    if (!_formKey.currentState!.validate()) return;
    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Lütfen doğum tarihi seçin'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.user?.id;
      if (userId == null) {
        throw Exception('Kullanıcı giriş yapmamış');
      }

      // Upload avatar if selected
      String? finalAvatarUrl = _avatarUrl;
      if (_avatarFile != null) {
        try {
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final imagePath = 'love_candidates/$userId/$timestamp.jpg';
          final imageBytes = await _avatarFile!.readAsBytes();
          finalAvatarUrl = await _firebaseService.uploadImage(imagePath, imageBytes);
          if (finalAvatarUrl == null) {
            throw Exception('Resim yüklenemedi');
          }
        } catch (e) {
          if (mounted) {
            setState(() => _saving = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Resim yükleme hatası: $e'),
                backgroundColor: AppColors.error,
                duration: const Duration(seconds: 5),
              ),
            );
          }
          return;
        }
      }

      // Create candidate
      final candidateData = {
        'userId': userId,
        'name': _nameController.text.trim(),
        'avatarUrl': finalAvatarUrl,
        'birthDate': Timestamp.fromDate(_birthDate!),
        'zodiacSign': _zodiacSign!,
        'relationshipType': _relationshipType,
      };

      await _firebaseService.createLoveCandidate(userId, candidateData);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: AppColors.error,
          ),
        );
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
            title: const Text('Aday Ekle'),
            backgroundColor: isDark ? AppColors.surface : AppColors.lightSurface,
            foregroundColor: textColor,
            elevation: 0,
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: themeProvider.backgroundGradient,
            ),
            child: SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Avatar selection
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                              backgroundImage: _avatarFile != null
                                  ? FileImage(_avatarFile!)
                                  : (_avatarUrl != null ? NetworkImage(_avatarUrl!) : null) as ImageProvider?,
                              child: _avatarFile == null && _avatarUrl == null
                                  ? Icon(
                                      Icons.person,
                                      size: 50,
                                      color: AppColors.primary,
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Name field
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'İsim / Takma Ad',
                        hintText: 'Adayın adını girin',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: cardBg,
                      ),
                      style: AppTextStyles.bodyMedium.copyWith(color: textColor),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'İsim gereklidir';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Birth date picker
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        _onBirthDateChanged(date);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: AppColors.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Doğum Tarihi',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: textSecondaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _birthDate != null
                                        ? '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}'
                                        : 'Gün/Ay/Yıl seçin',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: _birthDate != null ? textColor : textSecondaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_zodiacSign != null) ...[
                              Text(
                                Helpers.getZodiacEmoji(_zodiacSign!),
                                style: const TextStyle(fontSize: 24),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _zodiacSign!,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Relationship type
                    Text(
                      'Yakınlık (Opsiyonel)',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildRelationshipChip('crush', 'Hoşlandığım kişi', isDark, textColor),
                        _buildRelationshipChip('partner', 'Sevgilim', isDark, textColor),
                        _buildRelationshipChip('ex', 'Eski sevgilim', isDark, textColor),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _saveCandidate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Adayı Kaydet ve Uyum Hesapla',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRelationshipChip(String value, String label, bool isDark, Color textColor) {
    final isSelected = _relationshipType == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _relationshipType = selected ? value : null;
        });
      },
      selectedColor: AppColors.primary,
      backgroundColor: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : textColor,
      ),
    );
  }
}

