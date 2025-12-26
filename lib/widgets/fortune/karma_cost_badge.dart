import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/pricing_constants.dart';

class KarmaCostBadge extends StatelessWidget {
  final String? fortuneType;
  final int? customCost; // Testler için özel maliyet

  const KarmaCostBadge({
    Key? key,
    this.fortuneType,
    this.customCost,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cost = customCost ?? (fortuneType == 'aura' 
        ? PricingConstants.auraMatchCost 
        : fortuneType == 'test'
        ? PricingConstants.testCost
        : PricingConstants.getFortuneCost(fortuneType ?? ''));
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: AppColors.karmaGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.karma.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.karma.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            '$cost',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'Karma',
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

