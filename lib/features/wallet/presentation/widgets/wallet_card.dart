import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/wallet.dart';
import 'package:intl/intl.dart';

class WalletCard extends StatelessWidget {
  final Wallet wallet;

  const WalletCard({super.key, required this.wallet});

  Color get _cardColor {
    switch (wallet.category) {
      case 'NEEDS':
        return Colors.blueGrey;
      case 'INVEST':
        return AppColors.growthGreen;
      case 'SAVING':
        return AppColors.regenerationOrange;
      default:
        return AppColors.ambitiousNavy;
    }
  }

  String get _categoryLabel {
    switch (wallet.category) {
      case 'NEEDS':
        return 'Kebutuhan';
      case 'INVEST':
        return 'Investasi';
      case 'SAVING':
        return 'Tabungan';
      default:
        return wallet.category;
    }
  }

  IconData get _icon {
    switch (wallet.category) {
      case 'NEEDS':
        return Icons.shopping_bag_outlined;
      case 'INVEST':
        return Icons.trending_up;
      case 'SAVING':
        return Icons.savings_outlined;
      default:
        return Icons.account_balance_wallet_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _cardColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(_icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                _categoryLabel,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            currencyFormatter.format(wallet.currentBalance),
            style: AppTextStyles.headlineMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Saldo tersedia',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
