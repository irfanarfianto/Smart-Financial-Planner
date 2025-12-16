import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../bloc/transaction_bloc.dart';
import '../bloc/transaction_event.dart';
import '../bloc/transaction_state.dart';
import '../../domain/entities/transaction_entity.dart';
import '../widgets/transaction_list_item.dart';
import '../widgets/transaction_detail_sheet.dart';
import '../widgets/transaction_filter_dialog.dart';
import '../widgets/transaction_search_bar.dart';

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedType;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Initial fetch
    context.read<TransactionBloc>().add(const FetchTransactionsWithFilter());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<TransactionBloc>().add(LoadMoreTransactions());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  void _applyFilters() {
    context.read<TransactionBloc>().add(
      FetchTransactionsWithFilter(
        startDate: _startDate,
        endDate: _endDate,
        type: _selectedType,
        searchQuery: _searchController.text.isEmpty
            ? null
            : _searchController.text,
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => TransactionFilterDialog(
        initialStartDate: _startDate,
        initialEndDate: _endDate,
        initialType: _selectedType,
        onApply: (startDate, endDate, type) {
          setState(() {
            _startDate = startDate;
            _endDate = endDate;
            _selectedType = type;
          });
          _applyFilters();
        },
      ),
    );
  }

  void _showTransactionDetail(TransactionEntity transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransactionDetailSheet(transaction: transaction),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter',
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          TransactionSearchBar(
            controller: _searchController,
            onClear: () {
              _searchController.clear();
              _applyFilters();
            },
            onChanged: (value) {
              // Debounce search
              Future.delayed(const Duration(milliseconds: 500), () {
                if (_searchController.text == value) {
                  _applyFilters();
                }
              });
            },
          ),

          // Active Filters Chips
          if (_startDate != null || _endDate != null || _selectedType != null)
            _buildActiveFiltersChips(),

          // Transaction List
          Expanded(
            child: BlocBuilder<TransactionBloc, TransactionState>(
              builder: (context, state) {
                if (state is TransactionLoading) {
                  return _buildLoadingList();
                }

                if (state is TransactionLoaded ||
                    state is TransactionLoadingMore) {
                  final transactions = state is TransactionLoaded
                      ? state.transactions
                      : (state as TransactionLoadingMore).currentTransactions;

                  if (transactions.isEmpty) {
                    return _buildEmptyState();
                  }

                  return _buildTransactionList(transactions, state);
                }

                if (state is TransactionFailure) {
                  return _buildErrorState(state.message);
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFiltersChips() {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          if (_startDate != null || _endDate != null)
            Chip(
              label: Text(
                '${_startDate != null ? "${_startDate!.day}/${_startDate!.month}" : "..."} - ${_endDate != null ? "${_endDate!.day}/${_endDate!.month}" : "..."}',
                style: AppTextStyles.bodySmall,
              ),
              onDeleted: () {
                setState(() {
                  _startDate = null;
                  _endDate = null;
                });
                _applyFilters();
              },
            ),
          if (_selectedType != null)
            Chip(
              label: Text(
                _selectedType == 'INCOME' ? 'Pemasukan' : 'Pengeluaran',
                style: AppTextStyles.bodySmall,
              ),
              backgroundColor: _selectedType == 'INCOME'
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.red.withValues(alpha: 0.1),
              onDeleted: () {
                setState(() => _selectedType = null);
                _applyFilters();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingList() {
    return ListView.builder(
      itemCount: 10,
      padding: const EdgeInsets.only(top: 8),
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: AppShimmer(
          width: double.infinity,
          height: 80,
          child: Container(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Belum ada transaksi',
            style: AppTextStyles.headlineSmall.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Transaksi Anda akan muncul di sini',
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text('Terjadi Kesalahan', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 8),
          Text(
            message,
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(
    List<TransactionEntity> transactions,
    TransactionState state,
  ) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      itemCount:
          transactions.length +
          (state is TransactionLoaded && state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= transactions.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final transaction = transactions[index];
        return TransactionListItem(
          transaction: transaction,
          onTap: () => _showTransactionDetail(transaction),
        );
      },
    );
  }
}
