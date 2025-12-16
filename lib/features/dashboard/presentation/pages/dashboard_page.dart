import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_financial_planner/core/theme/app_colors.dart';
import 'package:smart_financial_planner/features/wallet/presentation/bloc/wallet_event.dart';
import 'package:smart_financial_planner/features/wallet/presentation/bloc/wallet_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../../wallet/presentation/bloc/wallet_bloc.dart';
import '../../../wallet/presentation/widgets/wallet_card.dart';
import '../../../transaction/domain/entities/transaction_entity.dart';
import '../../../wallet/domain/entities/wallet.dart';
import '../widgets/monthly_summary_card.dart';
import '../widgets/wallet_distribution_chart.dart';
import '../widgets/insights_section.dart';
import '../widgets/financial_health_widget.dart';
import '../widgets/dashboard_shimmer.dart';
import '../../../settings/presentation/bloc/profile_bloc.dart';
import '../../../settings/presentation/bloc/profile_event.dart';
import '../../../settings/presentation/bloc/profile_state.dart';
import '../../../transaction/presentation/bloc/transaction_bloc.dart';
import '../../../transaction/presentation/bloc/transaction_event.dart';
import '../../../transaction/presentation/bloc/transaction_state.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, transactionState) {
        // Determine loading state from BLoC
        final bool isTransactionLoading =
            transactionState is TransactionLoading;
        final bool isTransactionLoaded = transactionState is TransactionLoaded;

        List<TransactionEntity> transactions = [];
        if (isTransactionLoaded) {
          transactions = transactionState.transactions;
        }

        // Show shimmer if transactions are loading initially (and empty)
        if (isTransactionLoading && transactions.isEmpty) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: DashboardShimmer(),
          );
        }

        // Calculate totals
        final double totalIncome = transactions
            .where((t) => t.type == 'INCOME')
            .fold(0.0, (sum, t) => sum + t.amount);

        final double totalExpense = transactions
            .where((t) => t.type == 'EXPENSE')
            .fold(0.0, (sum, t) => sum + t.amount);

        return Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              final result = await context.push('/add-transaction');
              if (context.mounted && result == true) {
                context.read<WalletBloc>().add(FetchWallets());
                context.read<TransactionBloc>().add(FetchTransactions());
              }
            },
            backgroundColor: Colors.black,
            child: const Icon(Icons.add, color: Colors.white),
          ),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                'Dashboard',
                style: AppTextStyles.headlineMedium.copyWith(
                  color: Colors.black,
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  icon: const Icon(Icons.settings, color: Colors.black),
                  onPressed: () async {
                    await context.push('/settings');
                    if (context.mounted) {
                      context.read<ProfileBloc>().add(LoadProfile());
                    }
                  },
                ),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              context.read<WalletBloc>().add(FetchWallets());
              context.read<TransactionBloc>().add(FetchTransactions());
              context.read<ProfileBloc>().add(LoadProfile());
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              // Padding handled by children for full-bleed effects
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildGreeting(),
                  ),
                  const SizedBox(height: 24),

                  // Monthly Summary Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: MonthlySummaryCard(
                      totalIncome: totalIncome,
                      totalExpense: totalExpense,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Wallets Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Dompet Saya',
                      style: AppTextStyles.headlineMedium,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildWalletList(),
                  const SizedBox(height: 24),

                  // Wallet Distribution Chart
                  BlocBuilder<WalletBloc, WalletState>(
                    builder: (context, walletState) {
                      if (walletState is WalletLoaded &&
                          walletState.wallets.isNotEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              WalletDistributionChart(
                                wallets: walletState.wallets,
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  // Insights Section
                  BlocBuilder<WalletBloc, WalletState>(
                    builder: (context, walletState) {
                      if (walletState is WalletLoaded && isTransactionLoaded) {
                        return InsightsSection(
                          totalIncome: totalIncome,
                          totalExpense: totalExpense,
                          wallets: walletState.wallets,
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: 24),

                  // Financial Health Widget
                  BlocBuilder<WalletBloc, WalletState>(
                    builder: (context, walletState) {
                      if (walletState is WalletLoaded &&
                          isTransactionLoaded &&
                          walletState.wallets.isNotEmpty) {
                        Wallet needsWallet;
                        try {
                          needsWallet = walletState.wallets.firstWhere(
                            (w) => w.category == 'NEEDS',
                          );
                        } catch (e) {
                          needsWallet = walletState.wallets.first;
                        }
                        final daysInMonth = DateTime.now().day;

                        return FinancialHealthWidget(
                          needsBalance: needsWallet.currentBalance,
                          totalExpense: totalExpense,
                          daysInMonth: daysInMonth,
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: 80), // Bottom padding for FAB
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGreeting() {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        if (state is ProfileLoading) {
          return Row(
            children: [
              const AppShimmer(width: 48, height: 48, borderRadius: 24),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  AppShimmer(width: 100, height: 14, borderRadius: 4),
                  SizedBox(height: 8),
                  AppShimmer(width: 150, height: 20, borderRadius: 4),
                ],
              ),
            ],
          );
        }

        final user = Supabase.instance.client.auth.currentUser;
        String userName = user?.email?.split('@').first ?? 'User';
        String? avatarUrl;
        int? activeModelId;

        if (state is ProfileLoaded) {
          userName =
              state.profile.fullName ?? state.profile.username ?? userName;
          avatarUrl = state.profile.avatarUrl;
          activeModelId = state.profile.activeModelId;
        }

        final userInitial = userName.isNotEmpty
            ? userName[0].toUpperCase()
            : 'U';
        final hour = DateTime.now().hour;
        String greeting;
        if (hour < 12) {
          greeting = 'Selamat Pagi';
        } else if (hour < 15) {
          greeting = 'Selamat Siang';
        } else if (hour < 18) {
          greeting = 'Selamat Sore';
        } else {
          greeting = 'Selamat Malam';
        }

        return Column(
          children: [
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24, // Slightly smaller than before for compactness
                  backgroundColor: Colors.black,
                  child: avatarUrl != null
                      ? ClipOval(
                          child: Image.network(
                            avatarUrl,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Text(
                                userInitial,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        )
                      : Text(
                          userInitial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        userName,
                        style: AppTextStyles.headlineSmall.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (activeModelId != null) ...[
              const SizedBox(height: 16),
              _buildModelBadge(activeModelId),
            ],
          ],
        );
      },
    );
  }

  Widget _buildModelBadge(int modelId) {
    final modelNames = {
      1: 'Growth Mode',
      2: 'Ambisius Builder',
      3: 'Regenerasi Finansial',
    };
    final modelColors = {
      1: AppColors.growthGreen,
      2: AppColors.ambitiousNavy,
      3: AppColors.regenerationOrange,
    };

    final modelName = modelNames[modelId] ?? 'Unknown';
    final modelColor = modelColors[modelId] ?? Colors.grey;

    return Container(
      width: double.infinity, // Full width for cleaner look
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: modelColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: modelColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_graph, color: modelColor, size: 20),
          const SizedBox(width: 8),
          Text(
            modelName,
            style: AppTextStyles.bodyMedium.copyWith(
              color: modelColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.check_circle, color: modelColor, size: 16),
        ],
      ),
    );
  }

  Widget _buildWalletList() {
    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, state) {
        if (state is WalletLoading) {
          // Horizontal Shimmer
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
        } else if (state is WalletLoaded) {
          if (state.wallets.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildEmptyState(),
            );
          }
          // Horizontal List
          return SizedBox(
            height: 170, // Sufficient height for wallet card
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: state.wallets.length,
              separatorBuilder: (_, _) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                return SizedBox(
                  width: 320, // Slightly wider for better content fit
                  child: WalletCard(wallet: state.wallets[index]),
                );
              },
            ),
          );
        } else if (state is WalletError) {
          return Center(child: Text(state.message));
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text('Belum Ada Dompet', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Catat pemasukan pertama untuk memulai',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
