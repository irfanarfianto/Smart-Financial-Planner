import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../wallet/domain/entities/wallet.dart';

class WalletDistributionChart extends StatelessWidget {
  final List<Wallet> wallets;

  const WalletDistributionChart({super.key, required this.wallets});

  @override
  Widget build(BuildContext context) {
    if (wallets.isEmpty) {
      return const SizedBox.shrink();
    }

    final total = wallets.fold<double>(
      0,
      (sum, wallet) => sum + wallet.currentBalance,
    );

    if (total <= 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Distribusi Dompet',
            style: AppTextStyles.headlineMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 50,
                sections: _buildSections(total),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ..._buildLegend(),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildSections(double total) {
    final colors = {
      'NEEDS': AppColors.ambitiousNavy,
      'INVEST': AppColors.growthGreen,
      'SAVING': AppColors.regenerationOrange,
    };

    return wallets.map((wallet) {
      final percentage = (wallet.currentBalance / total) * 100;
      return PieChartSectionData(
        color: colors[wallet.category] ?? Colors.grey,
        value: wallet.currentBalance,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 60,
        titleStyle: AppTextStyles.bodyMedium.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      );
    }).toList();
  }

  List<Widget> _buildLegend() {
    final labels = {
      'NEEDS': 'Kebutuhan',
      'INVEST': 'Investasi',
      'SAVING': 'Tabungan',
    };

    final colors = {
      'NEEDS': AppColors.ambitiousNavy,
      'INVEST': AppColors.growthGreen,
      'SAVING': AppColors.regenerationOrange,
    };

    return wallets.map((wallet) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: colors[wallet.category],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                labels[wallet.category] ?? wallet.category,
                style: AppTextStyles.bodyMedium,
              ),
            ),
            Text(
              AppFormatters.formatCurrency(wallet.currentBalance),
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
