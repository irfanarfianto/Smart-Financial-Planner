import 'package:equatable/equatable.dart';
import '../../domain/entities/transaction_entity.dart';

abstract class TransactionState extends Equatable {
  const TransactionState();
  @override
  List<Object> get props => [];
}

class TransactionInitial extends TransactionState {}

class TransactionLoading extends TransactionState {}

class TransactionSuccess extends TransactionState {}

class TransactionLoaded extends TransactionState {
  final List<TransactionEntity> transactions;
  final bool hasMore;
  final int currentPage;

  const TransactionLoaded({
    required this.transactions,
    this.hasMore = false,
    this.currentPage = 1,
  });

  @override
  List<Object> get props => [transactions, hasMore, currentPage];

  TransactionLoaded copyWith({
    List<TransactionEntity>? transactions,
    bool? hasMore,
    int? currentPage,
  }) {
    return TransactionLoaded(
      transactions: transactions ?? this.transactions,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class TransactionLoadingMore extends TransactionState {
  final List<TransactionEntity> currentTransactions;

  const TransactionLoadingMore(this.currentTransactions);

  @override
  List<Object> get props => [currentTransactions];
}

class TransactionFailure extends TransactionState {
  final String message;
  const TransactionFailure(this.message);
  @override
  List<Object> get props => [message];
}

class TransactionDeleted extends TransactionState {}

class TransactionUpdated extends TransactionState {}
