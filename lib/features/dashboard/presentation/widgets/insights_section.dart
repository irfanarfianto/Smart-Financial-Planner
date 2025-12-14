import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class InsightCard extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color color;

  const InsightCard({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    this.color = AppColors.growthGreen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2), // Softer bg
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20), // Smaller icon
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Compact
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12, // Smaller font for dense info
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class InsightsSection extends StatelessWidget {
  final double totalIncome;
  final double totalExpense;
  final List<dynamic> wallets;

  const InsightsSection({
    super.key,
    required this.totalIncome,
    required this.totalExpense,
    required this.wallets,
  });

  List<Widget> _generateInsights() {
    List<Widget> insights = [];

    // Insight 1: Spending vs Income
    if (totalIncome > 0) {
      final spendingRatio = (totalExpense / totalIncome) * 100;
      if (spendingRatio > 80) {
        insights.add(
          const InsightCard(
            title: 'Pengeluaran Tinggi!',
            message:
                'Pengeluaran mencapai 80% dari pemasukan. Kurangi belanja non-prioritas.',
            icon: Icons.warning_amber_rounded,
            color: AppColors.error,
          ),
        );
      } else if (spendingRatio < 50) {
        insights.add(
          const InsightCard(
            title: 'Keuangan Sehat!',
            message:
                'Pengeluaran di bawah 50%. Pertahankan kebiasaan baik ini!',
            icon: Icons.check_circle,
            color: AppColors.growthGreen,
          ),
        );
      }
    }

    // Insight 2: Savings Check
    final savingsWallet = wallets
        .where((w) => w.category == 'SAVING')
        .firstOrNull;
    if (savingsWallet != null && savingsWallet.currentBalance < 1000000) {
      insights.add(
        const InsightCard(
          title: 'Perlu Dana Darurat',
          message: 'Dana darurat minim. Targetkan Rp 1 Juta untuk keamanan.',
          icon: Icons.savings,
          color: AppColors.regenerationOrange,
        ),
      );
    }

    // Insight 3: Investment Encouragement
    final investWallet = wallets
        .where((w) => w.category == 'INVEST')
        .firstOrNull;
    if (investWallet != null && investWallet.currentBalance > 5000000) {
      insights.add(
        const InsightCard(
          title: 'Siap Berinvestasi',
          message: 'Dana investasi cukup. Mulai pelajari instrumen investasi.',
          icon: Icons.trending_up,
          color: AppColors.growthGreen,
        ),
      );
    }

    return insights;
  }

  @override
  Widget build(BuildContext context) {
    final insights = _generateInsights();

    if (insights.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Insight & Rekomendasi',
            style: AppTextStyles.headlineMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 130, // Compact height
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: insights.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return SizedBox(
                width: 280, // Compact width
                child: insights[index],
              );
            },
          ),
        ),
      ],
    );
  }
}
