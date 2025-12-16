import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_formatters.dart';

class FinancialHealthWidget extends StatelessWidget {
  final double needsBalance;
  final double totalExpense;
  final int daysInMonth;

  const FinancialHealthWidget({
    super.key,
    required this.needsBalance,
    required this.totalExpense,
    required this.daysInMonth,
  });

  @override
  Widget build(BuildContext context) {
    final double burnRate = daysInMonth > 0
        ? (totalExpense / daysInMonth).toDouble()
        : 0.0;
    final daysRemaining = burnRate > 0
        ? (needsBalance / burnRate).floor()
        : 999;
    final bufferPercentage = needsBalance > 0
        ? (needsBalance / (needsBalance + totalExpense)) * 100
        : 0;

    void navigateToDetail() {
      context.push(
        '/financial-health-detail',
        extra: {
          'needsBalance': needsBalance,
          'totalExpense': totalExpense,
          'daysInMonth': daysInMonth,
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: InkWell(
            onTap: navigateToDetail,
            borderRadius: BorderRadius.circular(12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Kesehatan Keuangan',
                  style: AppTextStyles.headlineMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 170, // Fixed height for carousel
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              // Burn Rate Card
              _buildCompactMetricCard(
                icon: Icons.local_fire_department,
                iconColor: AppColors.regenerationOrange,
                title: 'Burn Rate',
                value: AppFormatters.formatCurrency(burnRate),
                subtitle: 'per hari',
                onTap: navigateToDetail,
              ),
              const SizedBox(width: 16),

              // Days Remaining Card
              _buildCompactMetricCard(
                icon: Icons.timer,
                iconColor: daysRemaining < 7
                    ? AppColors.error
                    : AppColors.growthGreen,
                title: 'Estimasi Bertahan',
                value: daysRemaining > 90 ? '90+ hari' : '$daysRemaining hari',
                subtitle: 'saldo Needs saat ini',
                onTap: navigateToDetail,
              ),
              const SizedBox(width: 16),

              // Buffer Percentage Card
              _buildCompactMetricCard(
                icon: Icons.shield,
                iconColor: bufferPercentage < 10
                    ? AppColors.error
                    : AppColors.ambitiousNavy,
                title: 'Buffer Keamanan',
                value: '${bufferPercentage.toStringAsFixed(1)}%',
                subtitle: 'dari Total Expense',
                onTap: navigateToDetail,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactMetricCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1), // Subtle background
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: iconColor.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.grey[700],
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTextStyles.headlineSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.grey[600],
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Helper method to check if user can afford a purchase
  static bool canAffordPurchase(double needsBalance, double purchaseAmount) {
    final remainingBalance = needsBalance - purchaseAmount;
    final bufferPercentage = (remainingBalance / needsBalance) * 100;
    return bufferPercentage >= 10; // Minimum 10% buffer
  }

  /// Helper method to get warning message for purchase
  static String? getPurchaseWarning(
    double needsBalance,
    double purchaseAmount,
  ) {
    final remainingBalance = needsBalance - purchaseAmount;

    // Case 1: Deficit (Overspending)
    if (remainingBalance < 0) {
      final deficit = remainingBalance.abs();
      return '⚠️ Saldo Tidak Cukup!\n\nPengeluaran ini melebihi anggaran "Needs" kamu. Kamu akan tekor sebesar ${AppFormatters.formatCurrency(deficit)}.\n\nYakin tetap mau lanjut?';
    }

    // Case 2: Dangerous Buffer (< 10%)
    final bufferPercentage = (remainingBalance / needsBalance) * 100;
    if (bufferPercentage < 10) {
      return '⚠️ Warning: Napas Keuangan Menipis\n\nSetelah transaksi ini, sisa dana daruratmu hanya tinggal ${bufferPercentage.toStringAsFixed(1)}%. Sangat berisiko!\n\nPertimbangkan untuk menunda pembelian ini.';
    }

    return null;
  }
}
