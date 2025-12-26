import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_strings.dart';
import '../../core/providers/user_provider.dart';
import '../../core/widgets/mystical_button.dart';
import '../../providers/theme_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _auraCtrl = TextEditingController();
  final TextEditingController _birthPlaceCtrl = TextEditingController();
  DateTime? _selectedBirthDate;
  String? _selectedZodiacSign;
  String? _selectedGender;
  String? _selectedJob;
  bool _saving = false;

  List<String> get _zodiacSigns {
    return [
      AppStrings.aries, AppStrings.taurus, AppStrings.gemini, 
      AppStrings.cancer, AppStrings.leo, AppStrings.virgo,
      AppStrings.libra, AppStrings.scorpio, AppStrings.sagittarius, 
      AppStrings.capricorn, AppStrings.aquarius, AppStrings.pisces
    ];
  }

  List<String> get _genderOptions {
    return [
      AppStrings.female,
      AppStrings.male,
      AppStrings.lgbt,
    ];
  }

  List<String> get _jobOptions {
    return AppStrings.jobStatusOptions;
  }

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserProvider>(context, listen: false).user;
    _nameCtrl.text = user?.name ?? '';
    _auraCtrl.text = user?.preferences['auraColor']?.toString() ?? 'Belirlenmedi';
    _selectedBirthDate = user?.birthDate;
    // Normalize zodiac sign to current language
    _selectedZodiacSign = AppStrings.normalizeZodiacSign(user?.zodiacSign);
    _selectedGender = user?.gender;
    _selectedJob = user?.job;
    _birthPlaceCtrl.text = user?.birthPlace ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _auraCtrl.dispose();
    _birthPlaceCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
        final isDark = themeProvider.isDarkMode;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: isDark ? AppColors.surface : Colors.white,
              onSurface: AppColors.getTextPrimary(isDark),
            ),
          ),
          child: child!,
        );
      },
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

  Future<void> _save() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    setState(() => _saving = true);
    try {
      await userProvider.updateProfile(
        name: _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : null,
        birthDate: _selectedBirthDate,
        zodiacSign: AppStrings.zodiacSignToTurkish(_selectedZodiacSign),
        gender: _selectedGender,
        job: _selectedJob,
        birthPlace: _birthPlaceCtrl.text.trim().isNotEmpty ? _birthPlaceCtrl.text.trim() : null,
      );
      
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.profileUpdated), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppStrings.error}: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(AppStrings.editProfile, style: TextStyle(color: AppColors.getTextPrimary(isDark))),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.getTextPrimary(isDark),
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: themeProvider.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // Avatar / Profile Icon Placeholder
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 40),
                
                // Name Input
                _buildInputGroup(
                  label: AppStrings.fullName,
                  controller: _nameCtrl,
                  hint: AppStrings.fullName,
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 24),
                
                // Birth Date Input
                _buildBirthDateField(),
                const SizedBox(height: 24),
                
                // Zodiac Sign Input
                _buildZodiacField(),
                const SizedBox(height: 24),
                
                // Gender Input
                _buildGenderField(),
                const SizedBox(height: 24),
                
                // Job Input
                _buildJobField(),
                const SizedBox(height: 24),
                
                // Birth Place Input
                _buildInputGroup(
                  label: AppStrings.birthPlace,
                  controller: _birthPlaceCtrl,
                  hint: AppStrings.birthPlace,
                  icon: Icons.location_on_outlined,
                ),
                const SizedBox(height: 24),
                
                // Aura Color Input (Read Only)
                _buildInputGroup(
                  label: AppStrings.auraColorLabel,
                  controller: _auraCtrl,
                  hint: AppStrings.auraColorLabel,
                  icon: Icons.auto_fix_high,
                  readOnly: true,
                  helperText: AppStrings.auraColorHint,
                ),
                
                const SizedBox(height: 60),
                
                MysticalButton.primary(
                  text: AppStrings.saveChanges,
                  icon: Icons.check_circle_outline,
                  onPressed: _saving ? null : _save,
                  isLoading: _saving,
                  width: double.infinity,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputGroup({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool readOnly = false,
    String? helperText,
  }) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        final inputTextColor = AppColors.getInputTextColor(isDark);
        final inputHintColor = AppColors.getInputHintColor(isDark);
        final inputBgColor = AppColors.getInputBackground(isDark);
        final inputBorderColor = AppColors.getInputBorderColor(isDark);
        final labelColor = AppColors.getTextSecondary(isDark);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: labelColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: readOnly 
                    ? (isDark ? Colors.black.withOpacity(0.2) : Colors.grey[300]) 
                    : inputBgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: readOnly 
                      ? (isDark ? Colors.white10 : Colors.grey[400]!) 
                      : inputBorderColor,
                  width: 1,
                ),
                boxShadow: readOnly ? [] : [
                  BoxShadow(
                    color: (isDark ? Colors.black : Colors.grey[400]!).withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: controller,
                readOnly: readOnly,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: readOnly 
                      ? (isDark ? Colors.white54 : Colors.grey[600]!) 
                      : inputTextColor,
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(color: inputHintColor),
                  prefixIcon: Icon(icon, color: readOnly 
                      ? (isDark ? Colors.white30 : Colors.grey[500]!) 
                      : AppColors.secondary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ),
            if (helperText != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: inputHintColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      helperText,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: inputHintColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildBirthDateField() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        final inputBg = AppColors.getInputBackground(isDark);
        final textColor = AppColors.getTextPrimary(isDark);
        final hintColor = AppColors.getTextSecondary(isDark);
        final inputBorderColor = AppColors.getInputBorderColor(isDark);
        final labelColor = AppColors.getTextSecondary(isDark);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.birthDate,
              style: AppTextStyles.bodyMedium.copyWith(
                color: labelColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _selectBirthDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: inputBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: inputBorderColor,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? Colors.black : Colors.grey[400]!).withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: AppColors.secondary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedBirthDate != null
                            ? '${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year}'
                            : AppStrings.selectBirthDate,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: _selectedBirthDate != null 
                              ? textColor 
                              : hintColor,
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, color: AppColors.secondary),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildZodiacField() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        final inputBg = AppColors.getInputBackground(isDark);
        final inputTextColor = AppColors.getInputTextColor(isDark);
        final inputHintColor = AppColors.getInputHintColor(isDark);
        final dropdownBg = AppColors.getCardBackground(isDark);
        final labelColor = AppColors.getTextSecondary(isDark);
        
        // Normalize selected zodiac sign and ensure it exists in the list
        final normalizedZodiac = AppStrings.normalizeZodiacSign(_selectedZodiacSign);
        final validZodiac = normalizedZodiac != null && _zodiacSigns.contains(normalizedZodiac) 
            ? normalizedZodiac 
            : null;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.zodiac,
              style: AppTextStyles.bodyMedium.copyWith(
                color: labelColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: inputBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.getInputBorderColor(isDark),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? Colors.black : Colors.grey[400]!).withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: DropdownButtonFormField<String>(
                initialValue: validZodiac,
                isExpanded: true,
                style: AppTextStyles.bodyLarge.copyWith(color: inputTextColor),
                dropdownColor: dropdownBg,
                decoration: InputDecoration(
                  hintText: AppStrings.pleaseSelectZodiac,
                  hintStyle: TextStyle(color: inputHintColor),
                  prefixIcon: Icon(Icons.star, color: AppColors.secondary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                items: _zodiacSigns.map((String zodiac) {
                  return DropdownMenuItem<String>(
                    value: zodiac,
                    child: Text(
                      zodiac,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                selectedItemBuilder: (BuildContext context) {
                  return _zodiacSigns.map((String zodiac) {
                    return Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        zodiac,
                        style: AppTextStyles.bodyLarge.copyWith(color: inputTextColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList();
                },
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedZodiacSign = newValue;
                  });
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGenderField() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        final inputBg = AppColors.getInputBackground(isDark);
        final inputTextColor = AppColors.getInputTextColor(isDark);
        final inputHintColor = AppColors.getInputHintColor(isDark);
        final dropdownBg = AppColors.getCardBackground(isDark);
        final labelColor = AppColors.getTextSecondary(isDark);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.gender,
              style: AppTextStyles.bodyMedium.copyWith(
                color: labelColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: inputBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.getInputBorderColor(isDark),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? Colors.black : Colors.grey[400]!).withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: DropdownButtonFormField<String>(
                initialValue: _selectedGender,
                style: AppTextStyles.bodyLarge.copyWith(color: inputTextColor),
                dropdownColor: dropdownBg,
                decoration: InputDecoration(
                  hintText: AppStrings.selectHint,
                  hintStyle: TextStyle(color: inputHintColor),
                  prefixIcon: Icon(Icons.person_outline, color: AppColors.secondary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                items: [
                  DropdownMenuItem<String>(
                    value: null,
                    child: Text(
                      AppStrings.selectHint,
                      style: TextStyle(color: inputHintColor),
                    ),
                  ),
                  ..._genderOptions.map((String gender) {
                    return DropdownMenuItem<String>(
                      value: gender,
                      child: Text(gender),
                    );
                  }),
                ],
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedGender = newValue;
                  });
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildJobField() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        final inputBg = AppColors.getInputBackground(isDark);
        final inputTextColor = AppColors.getInputTextColor(isDark);
        final inputHintColor = AppColors.getInputHintColor(isDark);
        final dropdownBg = AppColors.getCardBackground(isDark);
        final labelColor = AppColors.getTextSecondary(isDark);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.job,
              style: AppTextStyles.bodyMedium.copyWith(
                color: labelColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: inputBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.getInputBorderColor(isDark),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? Colors.black : Colors.grey[400]!).withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: DropdownButtonFormField<String>(
                initialValue: _selectedJob,
                style: AppTextStyles.bodyLarge.copyWith(color: inputTextColor),
                dropdownColor: dropdownBg,
                decoration: InputDecoration(
                  hintText: AppStrings.selectHint,
                  hintStyle: TextStyle(color: inputHintColor),
                  prefixIcon: Icon(Icons.work_outline, color: AppColors.secondary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                items: [
                  DropdownMenuItem<String>(
                    value: null,
                    child: Text(
                      AppStrings.selectHint,
                      style: TextStyle(color: inputHintColor),
                    ),
                  ),
                  ..._jobOptions.map((String job) {
                    return DropdownMenuItem<String>(
                      value: job,
                      child: Text(job),
                    );
                  }),
                ],
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedJob = newValue;
                  });
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
