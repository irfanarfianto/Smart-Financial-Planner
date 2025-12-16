import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/add_transaction.dart';
import '../../domain/usecases/get_transactions.dart';
import '../../domain/repositories/transaction_repository.dart';
import 'transaction_event.dart';
import 'transaction_state.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final AddTransaction addTransaction;
  final GetTransactions getTransactions;
  final TransactionRepository repository;

  // Store current filter for pagination
  DateTime? _currentStartDate;
  DateTime? _currentEndDate;
  String? _currentType;
  String? _currentSearchQuery;

  TransactionBloc({
    required this.addTransaction,
    required this.getTransactions,
    required this.repository,
  }) : super(TransactionInitial()) {
    on<CreateTransaction>(_onCreateTransaction);
    on<FetchTransactions>(_onFetchTransactions);
    on<FetchTransactionsWithFilter>(_onFetchTransactionsWithFilter);
    on<LoadMoreTransactions>(_onLoadMoreTransactions);
    on<DeleteTransaction>(_onDeleteTransaction);
    on<UpdateTransaction>(_onUpdateTransaction);
  }

  Future<void> _onCreateTransaction(
    CreateTransaction event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());
    final result = await addTransaction(
      AddTransactionParams(transaction: event.transaction),
    );
    result.fold(
      (failure) => emit(TransactionFailure(failure.message)),
      (_) => emit(TransactionSuccess()),
    );
  }

  Future<void> _onFetchTransactions(
    FetchTransactions event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());
    final result = await getTransactions(NoParams());
    result.fold(
      (failure) => emit(TransactionFailure(failure.message)),
      (transactions) => emit(
        TransactionLoaded(
          transactions: transactions,
          hasMore: false,
          currentPage: 1,
        ),
      ),
    );
  }

  Future<void> _onFetchTransactionsWithFilter(
    FetchTransactionsWithFilter event,
    Emitter<TransactionState> emit,
  ) async {
    // Store current filter for pagination
    _currentStartDate = event.startDate;
    _currentEndDate = event.endDate;
    _currentType = event.type;
    _currentSearchQuery = event.searchQuery;

    emit(TransactionLoading());

    // Use optimized database query instead of in-memory filtering
    final result = await repository.getTransactionsFiltered(
      startDate: event.startDate,
      endDate: event.endDate,
      type: event.type,
      searchQuery: event.searchQuery,
      limit: event.limit,
      offset: (event.page - 1) * event.limit,
    );

    result.fold((failure) => emit(TransactionFailure(failure.message)), (
      transactions,
    ) {
      // Check if there might be more data
      final hasMore = transactions.length >= event.limit;

      emit(
        TransactionLoaded(
          transactions: transactions,
          hasMore: hasMore,
          currentPage: event.page,
        ),
      );
    });
  }

  Future<void> _onLoadMoreTransactions(
    LoadMoreTransactions event,
    Emitter<TransactionState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TransactionLoaded || !currentState.hasMore) return;

    emit(TransactionLoadingMore(currentState.transactions));

    // Fetch next page with same filter
    final result = await repository.getTransactionsFiltered(
      startDate: _currentStartDate,
      endDate: _currentEndDate,
      type: _currentType,
      searchQuery: _currentSearchQuery,
      limit: 20,
      offset: currentState.currentPage * 20,
    );

    result.fold((failure) => emit(TransactionFailure(failure.message)), (
      newTransactions,
    ) {
      final allTransactions = [
        ...currentState.transactions,
        ...newTransactions,
      ];
      final hasMore = newTransactions.length >= 20;

      emit(
        TransactionLoaded(
          transactions: allTransactions,
          hasMore: hasMore,
          currentPage: currentState.currentPage + 1,
        ),
      );
    });
  }

  Future<void> _onDeleteTransaction(
    DeleteTransaction event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());

    final result = await repository.deleteTransaction(event.transactionId);

    result.fold((failure) => emit(TransactionFailure(failure.message)), (_) {
      emit(TransactionDeleted());
      // Refresh the list after delete
      add(
        FetchTransactionsWithFilter(
          startDate: _currentStartDate,
          endDate: _currentEndDate,
          type: _currentType,
          searchQuery: _currentSearchQuery,
        ),
      );
    });
  }

  Future<void> _onUpdateTransaction(
    UpdateTransaction event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());

    final result = await repository.updateTransaction(event.transaction);

    result.fold((failure) => emit(TransactionFailure(failure.message)), (_) {
      emit(TransactionUpdated());
      // Refresh the list after update
      add(
        FetchTransactionsWithFilter(
          startDate: _currentStartDate,
          endDate: _currentEndDate,
          type: _currentType,
          searchQuery: _currentSearchQuery,
        ),
      );
    });
  }
}
