import 'package:flutter/material.dart';
import '../../domain/entities/financial_model.dart';
import '../../../../core/theme/app_text_styles.dart';

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

  Color _getThemeColor(String name) {
    if (name.contains('Growth')) return Colors.green;
    if (name.contains('Ambisius')) return const Color(0xFF001F3F); // Navy
    if (name.contains('Regenerasi')) return Colors.deepOrange;
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _getThemeColor(model.name);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? themeColor.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? themeColor : Colors.grey.shade300,
            width: 2,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: themeColor.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              model.name,
              style: AppTextStyles.headlineMedium.copyWith(
                color: themeColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildRatioRow('Needs', model.ratioNeeds, themeColor),
            _buildRatioRow('Invest', model.ratioInvest, themeColor),
            _buildRatioRow('Savings', model.ratioSavings, themeColor),
          ],
        ),
      ),
    );
  }

  Widget _buildRatioRow(String label, double ratio, Color color) {
    final percentage = (ratio * 100).round();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$percentage%',
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
          SizedBox(
            width: 100,
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
