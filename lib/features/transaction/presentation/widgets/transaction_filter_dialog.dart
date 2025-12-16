import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class TransactionFilterDialog extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final String? initialType;
  final Function(DateTime?, DateTime?, String?) onApply;

  const TransactionFilterDialog({
    super.key,
    this.initialStartDate,
    this.initialEndDate,
    this.initialType,
    required this.onApply,
  });

  @override
  State<TransactionFilterDialog> createState() =>
      _TransactionFilterDialogState();
}

class _TransactionFilterDialogState extends State<TransactionFilterDialog> {
  late DateTime? _startDate;
  late DateTime? _endDate;
  late String? _selectedType;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
    _selectedType = widget.initialType;
  }

  void _resetFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _selectedType = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Reset button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter Transaksi',
                  style: AppTextStyles.headlineMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: _resetFilters,
                  child: Text(
                    'Reset',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.ambitiousNavy,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Date Range
            Text('Rentang Tanggal', style: AppTextStyles.labelLarge),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildDateButton('Dari', _startDate, true)),
                const SizedBox(width: 12),
                Expanded(child: _buildDateButton('Sampai', _endDate, false)),
              ],
            ),
            const SizedBox(height: 24),

            // Type Filter
            Text('Tipe Transaksi', style: AppTextStyles.labelLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTypeChip('Semua', null),
                _buildTypeChip('Pemasukan', 'INCOME'),
                _buildTypeChip('Pengeluaran', 'EXPENSE'),
              ],
            ),
            const SizedBox(height: 32),

            // Apply Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onApply(_startDate, _endDate, _selectedType);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ambitiousNavy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Terapkan',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateButton(String label, DateTime? date, bool isStart) {
    return OutlinedButton.icon(
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: isStart ? DateTime(2020) : (_startDate ?? DateTime(2020)),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          setState(() {
            if (isStart) {
              _startDate = picked;
            } else {
              _endDate = picked;
            }
          });
        }
      },
      icon: Icon(
        Icons.calendar_today,
        size: 18,
        color: date != null ? AppColors.ambitiousNavy : Colors.grey.shade600,
      ),
      label: Text(
        date == null ? label : DateFormat('dd/MM/yy').format(date),
        style: AppTextStyles.bodyMedium.copyWith(
          color: date != null ? Colors.black87 : Colors.grey.shade600,
          fontWeight: date != null ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        side: BorderSide(
          color: date != null ? AppColors.ambitiousNavy : Colors.grey.shade300,
          width: date != null ? 1.5 : 1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildTypeChip(String label, String? type) {
    final isSelected = _selectedType == type;
    Color? selectedColor;

    if (isSelected && type == 'INCOME') {
      selectedColor = AppColors.growthGreen;
    } else if (isSelected && type == 'EXPENSE') {
      selectedColor = AppColors.error;
    } else if (isSelected) {
      selectedColor = AppColors.ambitiousNavy;
    }

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedType = selected ? type : null);
      },
      selectedColor: selectedColor?.withValues(alpha: 0.15),
      checkmarkColor: selectedColor,
      labelStyle: TextStyle(
        color: isSelected ? selectedColor : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? selectedColor! : Colors.grey.shade300,
        width: isSelected ? 1.5 : 1,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}
