import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_formatters.dart';

class FinancialHealthDetailPage extends StatelessWidget {
  final double needsBalance;
  final double totalExpense;
  final int daysInMonth;

  const FinancialHealthDetailPage({
    super.key,
    required this.needsBalance,
    required this.totalExpense,
    required this.daysInMonth,
  });

  @override
  Widget build(BuildContext context) {
    // Re-calculate metrics
    final double burnRate = daysInMonth > 0
        ? (totalExpense / daysInMonth).toDouble()
        : 0.0;
    final daysRemaining = burnRate > 0
        ? (needsBalance / burnRate).floor()
        : 999;
    final bufferPercentage = needsBalance > 0
        ? (needsBalance / (needsBalance + totalExpense)) * 100
        : 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Detail Kesehatan Keuangan'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Score (Summary)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.ambitiousNavy,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.health_and_safety,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    bufferPercentage > 20 ? 'Kondisi Aman' : 'Perlu Perhatian',
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    bufferPercentage > 20
                        ? 'Gaya hidupmu saat ini sehat. Pertahankan!'
                        : 'Hati-hati, pengeluaranmu hampir menyentuh batas aman.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 1. Burn Rate Explanation
            _buildExplanationCard(
              title: 'Burn Rate (Kecepatan Boros)',
              value: '${AppFormatters.formatCurrency(burnRate)} / hari',
              description:
                  'Angka ini menunjukkan rata-rata uang yang kamu habiskan setiap harinya untuk kebutuhan hidup.\n\nTips: Semakin kecil angka ini, semakin hemat kamu dan semakin banyak uang yang bisa ditabung.',
              icon: Icons.local_fire_department,
              color: AppColors.regenerationOrange,
            ),
            const SizedBox(height: 24),

            // 2. Days Remaining Explanation
            _buildExplanationCard(
              title: 'Estimasi Bertahan',
              value: daysRemaining > 90
                  ? 'Lebih dari 3 bulan'
                  : '$daysRemaining hari lagi',
              description:
                  'Jika mulai besok kamu tidak mendapat pemasukan sama sekali, selama inilah kamu bisa bertahan hidup dengan saldo "Needs" saat ini.\n\nTips: Usahakan angka ini minimal 30 hari (1 bulan) agar aman.',
              icon: Icons.timer,
              color: daysRemaining < 7
                  ? AppColors.error
                  : AppColors.growthGreen,
            ),
            const SizedBox(height: 24),

            // 3. Buffer Explanation
            _buildExplanationCard(
              title: 'Buffer Keamanan',
              value: '${bufferPercentage.toStringAsFixed(1)}%',
              description:
                  'Ini adalah sisa "napas" keuanganmu. Persentase uang yang belum terpakai dibanding total pengeluaran.\n\nTips: Jaga agar selalu di atas 20%. Jika di bawah 10%, kamu dalam bahaya defisit (gali lobang tutup lobang).',
              icon: Icons.shield,
              color: bufferPercentage < 10
                  ? AppColors.error
                  : AppColors.ambitiousNavy,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExplanationCard({
    required String title,
    required String value,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
