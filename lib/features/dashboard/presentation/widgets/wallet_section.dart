import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../../wallet/presentation/bloc/wallet_bloc.dart';
import '../../../wallet/presentation/bloc/wallet_state.dart';
import '../../../wallet/presentation/widgets/wallet_card.dart';

class WalletSection extends StatelessWidget {
  const WalletSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text('Dompet Saya', style: AppTextStyles.headlineMedium),
        ),
        const SizedBox(height: 16),
        _buildWalletList(),
      ],
    );
  }

  Widget _buildWalletList() {
    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, state) {
        if (state is WalletLoading) {
          return _buildLoadingState();
        } else if (state is WalletLoaded) {
          if (state.wallets.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildEmptyState(),
            );
          }
          return _buildWalletListView(state);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(width: 16),
        itemBuilder: (_, _) =>
            const AppShimmer(width: 300, height: 160, borderRadius: 20),
      ),
    );
  }

  Widget _buildWalletListView(WalletLoaded state) {
    return SizedBox(
      height: 170,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: state.wallets.length,
        separatorBuilder: (_, _) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final wallet = state.wallets[index];
          return SizedBox(width: 300, child: WalletCard(wallet: wallet));
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada dompet',
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Dompet Anda akan muncul di sini',
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
