import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_strings.dart';
import '../../core/providers/user_provider.dart';
import '../../providers/theme_provider.dart';

class FortuneUserInfoForm extends StatefulWidget {
  final Function(Map<String, dynamic>) onChanged;
  final Map<String, dynamic>? initialData;

  const FortuneUserInfoForm({
    Key? key,
    required this.onChanged,
    this.initialData,
  }) : super(key: key);

  @override
  State<FortuneUserInfoForm> createState() => _FortuneUserInfoFormState();
}

class _FortuneUserInfoFormState extends State<FortuneUserInfoForm>
    with SingleTickerProviderStateMixin {
  // Form Fields
  String? _topic1;
  String? _topic2;
  bool _isForSelf = true;
  final TextEditingController _nameController = TextEditingController();
  DateTime? _birthDate;
  String? _relationshipStatus;
  String? _jobStatus;
  late AnimationController _toggleController;
  late Animation<double> _toggleAnimation;

  // Data Lists (language-aware via AppStrings)
  List<String> get _topics => AppStrings.fortuneTopics;
  List<String> get _relationshipStatuses => AppStrings.relationshipStatusOptions;
  List<String> get _jobStatuses => AppStrings.jobStatusOptions;

  @override
  void initState() {
    super.initState();
    
    _toggleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _toggleAnimation = CurvedAnimation(
      parent: _toggleController,
      curve: Curves.easeInOut,
    );
    
    if (widget.initialData != null) {
      _topic1 = widget.initialData!['topic1'];
      _topic2 = widget.initialData!['topic2'];
      _isForSelf = widget.initialData!['isForSelf'] ?? true;
      _nameController.text = widget.initialData!['name'] ?? '';
      _birthDate = widget.initialData!['birthDate'];
      _relationshipStatus = widget.initialData!['relationshipStatus'];
      _jobStatus = widget.initialData!['jobStatus'];
    } else {
      // Defaults
      _topic1 = AppStrings.fortuneTopics.first; // 'Aşk' / 'Love'
      _topic2 = AppStrings.fortuneTopics[3]; // 'Kariyer' / 'Career'
    }
    
    if (_isForSelf) {
      _toggleController.value = 1.0;
    }
    
    if (widget.initialData == null && _isForSelf) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fillUserData();
      });
    }
    
    _nameController.addListener(_notifyChanges);
  }

  void _fillUserData() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;
    if (user != null) {
      setState(() {
        if (user.name.isNotEmpty) _nameController.text = user.name;
        if (user.birthDate != null) _birthDate = user.birthDate;
        if (user.relationshipStatus != null && _relationshipStatuses.contains(user.relationshipStatus)) {
          _relationshipStatus = user.relationshipStatus;
        }
        if (user.job != null && _jobStatuses.contains(user.job)) {
          _jobStatus = user.job;
        }
      });
      _notifyChanges();
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_notifyChanges);
    _nameController.dispose();
    _toggleController.dispose();
    super.dispose();
  }

  void _notifyChanges() {
    widget.onChanged({
      'topic1': _topic1,
      'topic2': _topic2,
      'isForSelf': _isForSelf,
      'name': _nameController.text,
      'birthDate': _birthDate,
      'relationshipStatus': _relationshipStatus,
      'jobStatus': _jobStatus,
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 20),
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: isDark 
            ? Theme.of(context).copyWith(
                colorScheme: ColorScheme.dark(
                  primary: AppColors.primary,
                  surface: AppColors.cardBackground,
                  onSurface: Colors.white,
                ), dialogTheme: DialogThemeData(backgroundColor: AppColors.background),
              )
            : Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: AppColors.primary,
                  surface: Colors.white,
                  onSurface: Colors.grey[900]!,
                ), dialogTheme: DialogThemeData(backgroundColor: Colors.grey[100]),
              ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _birthDate = picked;
      });
      _notifyChanges();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Topics
        _buildSectionLabel(AppStrings.fortuneTopicsTitle, Icons.auto_awesome, isDark),
        const SizedBox(height: 12),
        _buildTopicsSection(isDark),
        const SizedBox(height: 24),

        // 2. For Whom?
        _buildSectionLabel(AppStrings.forWhomTitle, Icons.person, isDark),
        const SizedBox(height: 12),
        _buildForWhomToggle(isDark),
        const SizedBox(height: 24),

        // 3. Name
        _buildSectionLabel(AppStrings.nameTitle, Icons.badge, isDark),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _nameController,
          hintText: AppStrings.nameHint,
          icon: Icons.person_outline,
          isDark: isDark,
        ),
        const SizedBox(height: 24),

        // 4. Birth Date
        _buildSectionLabel(AppStrings.birthDateTitle, Icons.cake, isDark),
        const SizedBox(height: 12),
        _buildDatePicker(isDark),
        const SizedBox(height: 24),

        // 5. Relationship Status
        _buildSectionLabel(AppStrings.relationshipStatusTitle, Icons.favorite, isDark),
        const SizedBox(height: 12),
        _buildDropdown(
          value: _relationshipStatus,
          items: _relationshipStatuses,
          hint: AppStrings.selectHint,
          icon: Icons.favorite_border,
          onChanged: (val) {
            setState(() => _relationshipStatus = val);
            _notifyChanges();
          },
          isDark: isDark,
        ),
        const SizedBox(height: 24),

        // 6. Job Status
        _buildSectionLabel(AppStrings.jobStatusTitle, Icons.work, isDark),
        const SizedBox(height: 12),
        _buildDropdown(
          value: _jobStatus,
          items: _jobStatuses,
          hint: AppStrings.selectHint,
          icon: Icons.business_center,
          onChanged: (val) {
            setState(() => _jobStatus = val);
            _notifyChanges();
          },
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String text, IconData icon, bool isDark) {
    final textColor = AppColors.getTextPrimary(isDark);
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.3),
                AppColors.secondary.withOpacity(0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: AppTextStyles.bodyLarge.copyWith(
            color: textColor,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTopicsSection(bool isDark) {
    final cardBg = isDark ? Colors.white.withOpacity(0.08) : Colors.grey.withOpacity(0.08);
    final borderColor = isDark ? Colors.white.withOpacity(0.15) : Colors.grey.withOpacity(0.2);
    final dividerColor = isDark ? Colors.white.withOpacity(0.2) : Colors.grey.withOpacity(0.3);
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cardBg,
            cardBg.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey).withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTopicRow(
              AppStrings.topic1Label, _topic1, Icons.star, (val) {
            setState(() => _topic1 = val);
            _notifyChanges();
          }, isDark),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  dividerColor,
                  Colors.transparent,
                ],
              ),
            ),
          ),
          _buildTopicRow(
              AppStrings.topic2Label, _topic2, Icons.star_border, (val) {
            setState(() => _topic2 = val);
            _notifyChanges();
          }, isDark),
        ],
      ),
    );
  }

  Widget _buildTopicRow(String label, String? value, IconData icon, ValueChanged<String?> onChanged, bool isDark) {
    final textColor = AppColors.getTextPrimary(isDark);
    final textSecondaryColor = AppColors.getTextSecondary(isDark);
    final hintColor = isDark ? Colors.white38 : Colors.grey;
    final dropdownBg = AppColors.getCardBackground(isDark);
    final fieldBg = isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1);
    final fieldBorder = isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary.withOpacity(0.7), size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: fieldBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: fieldBorder,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _topics.contains(value) ? value : null,
                  hint: Text(
                    AppStrings.selectHint,
                    style: TextStyle(color: hintColor, fontSize: 14),
                  ),
                  dropdownColor: dropdownBg,
                  isExpanded: true,
                  icon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
                  style: TextStyle(color: textColor, fontSize: 14),
                  items: _topics.map((t) {
                    return DropdownMenuItem(
                      value: t,
                      child: Text(t),
                    );
                  }).toList(),
                  onChanged: onChanged,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForWhomToggle(bool isDark) {
    final cardBg = isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.1);
    final borderColor = isDark ? Colors.white.withOpacity(0.2) : Colors.grey.withOpacity(0.25);
    final inactiveColor = isDark ? Colors.white60 : Colors.grey[600]!;
    
    return AnimatedBuilder(
      animation: _toggleAnimation,
      builder: (context, child) {
        return Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cardBg,
                cardBg.withOpacity(0.5),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : Colors.grey).withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Animated background
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                left: _isForSelf ? 8 : MediaQuery.of(context).size.width / 2 - 16 - 8,
                right: _isForSelf ? MediaQuery.of(context).size.width / 2 - 16 - 8 : 8,
                top: 8,
                bottom: 8,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.5),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _isForSelf = true);
                        _toggleController.forward();
                        _fillUserData();
                        _notifyChanges();
                      },
                      child: Container(
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person,
                              color: _isForSelf ? Colors.white : inactiveColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              AppStrings.forMyself,
                              style: AppTextStyles.buttonMedium.copyWith(
                                color: _isForSelf ? Colors.white : inactiveColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _isForSelf = false);
                        _toggleController.reverse();
                        _notifyChanges();
                      },
                      child: Container(
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people,
                              color: !_isForSelf ? Colors.white : inactiveColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              AppStrings.forSomeoneElse,
                              style: AppTextStyles.buttonMedium.copyWith(
                                color: !_isForSelf ? Colors.white : inactiveColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required bool isDark,
  }) {
    final inputTextColor = AppColors.getInputTextColor(isDark);
    final inputHintColor = AppColors.getInputHintColor(isDark);
    final inputBgColor = AppColors.getInputBackground(isDark);
    final inputBorderColor = AppColors.getInputBorderColor(isDark);
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            inputBgColor,
            inputBgColor.withOpacity(isDark ? 0.05 : 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: inputBorderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey[400]!).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        style: AppTextStyles.bodyLarge.copyWith(color: inputTextColor),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: inputHintColor),
          prefixIcon: Icon(icon, color: AppColors.primary.withOpacity(0.7)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDatePicker(bool isDark) {
    final textColor = AppColors.getTextPrimary(isDark);
    final hintColor = isDark ? Colors.white38 : Colors.grey;
    final cardBg = isDark ? Colors.white.withOpacity(0.08) : Colors.grey.withOpacity(0.08);
    final borderColor = isDark ? Colors.white.withOpacity(0.15) : Colors.grey.withOpacity(0.2);
    
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cardBg,
              cardBg.withOpacity(0.5),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black : Colors.grey).withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: AppColors.primary.withOpacity(0.7),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _birthDate == null
                    ? 'Gün / Ay / Yıl'
                    : DateFormat('dd/MM/yyyy').format(_birthDate!),
                style: AppTextStyles.bodyLarge.copyWith(
                  color: _birthDate == null ? hintColor : textColor,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: hintColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required String hint,
    required IconData icon,
    required ValueChanged<String?> onChanged,
    required bool isDark,
  }) {
    final textColor = AppColors.getTextPrimary(isDark);
    final hintColor = isDark ? Colors.white38 : Colors.grey;
    final cardBg = isDark ? Colors.white.withOpacity(0.08) : Colors.grey.withOpacity(0.08);
    final borderColor = isDark ? Colors.white.withOpacity(0.15) : Colors.grey.withOpacity(0.2);
    final dropdownBg = AppColors.getCardBackground(isDark);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cardBg,
            cardBg.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary.withOpacity(0.7), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: items.contains(value) ? value : null,
                hint: Text(
                  hint,
                  style: TextStyle(color: hintColor, fontSize: 14),
                ),
                dropdownColor: dropdownBg,
                isExpanded: true,
                icon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
                style: AppTextStyles.bodyLarge.copyWith(color: textColor),
                items: items.map((item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
