import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../constants/app_colors.dart';

class GlassPickerSheet {
  static Future<DateTime?> pickDate({
    required BuildContext context,
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    bool isDark = true,
  }) async {
    DateTime tempDate = initialDate ?? DateTime.now();
    
    return showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      isScrollControlled: true,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              height: 350,
              decoration: BoxDecoration(
                color: isDark ? AppColors.premiumDarkBg.withOpacity(0.85) : Colors.white.withOpacity(0.85),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
                    width: 0.5,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Toolbar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white60 : Colors.grey)),
                          onPressed: () => Navigator.pop(context),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: const Text('Done', style: TextStyle(color: AppColors.moonlightCyan, fontWeight: FontWeight.bold)),
                          onPressed: () => Navigator.pop(context, tempDate),
                        ),
                      ],
                    ),
                  ),
                  // Picker
                  Expanded(
                    child: CupertinoTheme(
                      data: CupertinoThemeData(
                        brightness: isDark ? Brightness.dark : Brightness.light,
                        textTheme: CupertinoTextThemeData(
                          dateTimePickerTextStyle: TextStyle(
                            color: isDark ? Colors.white : AppColors.slateText,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      child: CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.date,
                        initialDateTime: tempDate,
                        minimumDate: firstDate,
                        maximumDate: lastDate,
                        onDateTimeChanged: (date) => tempDate = date,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Future<String?> pickItem({
    required BuildContext context,
    required List<String> items,
    int initialIndex = 0,
    bool isDark = true,
  }) async {
    int tempIndex = initialIndex < 0 ? 0 : initialIndex;
    
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              height: 300,
              decoration: BoxDecoration(
                 color: isDark ? AppColors.premiumDarkBg.withOpacity(0.85) : Colors.white.withOpacity(0.85),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                   Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white60 : Colors.grey)),
                          onPressed: () => Navigator.pop(context),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: const Text('Done', style: TextStyle(color: AppColors.moonlightCyan, fontWeight: FontWeight.bold)),
                          onPressed: () => Navigator.pop(context, items[tempIndex]),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: CupertinoPicker(
                      scrollController: FixedExtentScrollController(initialItem: tempIndex),
                      itemExtent: 40,
                      onSelectedItemChanged: (index) => tempIndex = index,
                      children: items.map((item) => Center(
                        child: Text(
                          item,
                          style: TextStyle(
                            color: isDark ? Colors.white : AppColors.slateText,
                            fontSize: 18,
                          ),
                        ),
                      )).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
