import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../wallet/presentation/bloc/wallet_bloc.dart';
import '../../../wallet/presentation/bloc/wallet_event.dart';
import '../../../wallet/presentation/bloc/wallet_state.dart';
import '../../../transaction/presentation/bloc/transaction_bloc.dart';
import '../../../transaction/presentation/bloc/transaction_event.dart';
import '../../../transaction/presentation/bloc/transaction_state.dart';
import '../../../transaction/domain/entities/transaction_entity.dart';
import '../../../settings/presentation/bloc/profile_bloc.dart';
import '../../../settings/presentation/bloc/profile_event.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/wallet_section.dart';
import '../widgets/monthly_summary_card.dart';
import '../widgets/wallet_distribution_chart.dart';
import '../widgets/insights_section.dart';
import '../widgets/financial_health_widget.dart';
import '../widgets/recent_transactions_section.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, transactionState) {
        final isTransactionLoading = transactionState is TransactionLoading;
        final isTransactionLoaded = transactionState is TransactionLoaded;

        final transactions = isTransactionLoaded
            ? transactionState.transactions
            : <TransactionEntity>[];

        // Calculate totals
        final totalIncome = transactions
            .where((t) => t.type == 'INCOME')
            .fold(0.0, (sum, t) => sum + t.amount);

        final totalExpense = transactions
            .where((t) => t.type == 'EXPENSE')
            .fold(0.0, (sum, t) => sum + t.amount);

        return Scaffold(
          floatingActionButton: FloatingActionButton(
            heroTag: Object(),
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
            centerTitle: false,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // Header/Greeting
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: DashboardHeader(),
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
                  // Recent Transactions Section
                  RecentTransactionsSection(
                    transactions: transactions,
                    isLoading: isTransactionLoading,
                  ),

                  const SizedBox(height: 24),
                  // Wallets Section
                  const WalletSection(),
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
                          walletState.wallets.isNotEmpty) {
                        // Find NEEDS wallet or use first wallet
                        final needsWallet =
                            walletState.wallets
                                .where((w) => w.category == 'NEEDS')
                                .firstOrNull ??
                            walletState.wallets.first;

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
}
