import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';

class FinancialModelSelector extends StatelessWidget {
  final int? selectedModelId;
  final ValueChanged<int> onModelSelected;
  final List<Map<String, dynamic>> models;

  const FinancialModelSelector({
    super.key,
    required this.selectedModelId,
    required this.onModelSelected,
    required this.models,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: models.map((model) {
        final isSelected = selectedModelId == model['id'];
        return GestureDetector(
          onTap: () => onModelSelected(model['id']),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? model['color'] : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: model['color'].withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? model['color'] : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? model['color'] : Colors.grey[400]!,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        model['name'],
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected ? model['color'] : Colors.black,
                        ),
                      ),
                      if (model['description'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          model['description'],
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.auto_graph, color: model['color'], size: 24),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
