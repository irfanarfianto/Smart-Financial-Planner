import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/add_transaction.dart';
import '../../domain/usecases/get_transactions.dart';
import 'transaction_event.dart';
import 'transaction_state.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final AddTransaction addTransaction;
  final GetTransactions getTransactions;

  TransactionBloc({required this.addTransaction, required this.getTransactions})
    : super(TransactionInitial()) {
    on<CreateTransaction>(_onCreateTransaction);
    on<FetchTransactions>(_onFetchTransactions);
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
      (transactions) => emit(TransactionLoaded(transactions)),
    );
  }
}
