import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../onboarding/domain/entities/financial_model.dart';

class FinancialModelCard extends StatelessWidget {
  final FinancialModel model;
  final bool isSelected;
  final VoidCallback onTap;

  const FinancialModelCard({
    super.key,
    required this.model,
    required this.isSelected,
    required this.onTap,
  });

  Color get _primaryColor {
    if (model.name.contains('Growth')) return AppColors.growthGreen;
    if (model.name.contains('Ambisius')) return AppColors.ambitiousNavy;
    if (model.name.contains('Regenerasi')) return AppColors.regenerationOrange;
    return AppColors.ambitiousNavy;
  }

  String get _description {
    if (model.name.contains('Growth')) {
      return 'Seimbang. Cocok untuk pengembangan diri.';
    }
    if (model.name.contains('Ambisius')) {
      return 'Agresif. Hemat demi modal usaha besar.';
    }
    if (model.name.contains('Regenerasi')) {
      return 'Aman. Fokus bantu keluarga & investasi rendah resiko.';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _primaryColor : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? _primaryColor.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.pie_chart_rounded,
                    color: _primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        model.name,
                        style: AppTextStyles.titleLarge.copyWith(
                          color: _primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(_description, style: AppTextStyles.bodyMedium),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle_rounded, color: _primaryColor),
              ],
            ),
            const SizedBox(height: 16),
            _buildRatiosBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildRatiosBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 12,
        child: Row(
          children: [
            Expanded(
              flex: (model.ratioNeeds * 100).toInt(),
              child: Container(color: Colors.grey[400]),
            ),
            Expanded(
              flex: (model.ratioInvest * 100).toInt(),
              child: Container(color: _primaryColor),
            ),
            Expanded(
              flex: (model.ratioSavings * 100).toInt(),
              child: Container(color: Colors.amber),
            ),
          ],
        ),
      ),
    );
  }
}
