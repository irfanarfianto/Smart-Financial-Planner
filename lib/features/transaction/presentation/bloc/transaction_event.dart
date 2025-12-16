import 'package:equatable/equatable.dart';
import '../../domain/entities/transaction_entity.dart';

abstract class TransactionEvent extends Equatable {
  const TransactionEvent();
  @override
  List<Object?> get props => [];
}

class CreateTransaction extends TransactionEvent {
  final TransactionEntity transaction;
  const CreateTransaction(this.transaction);
  @override
  List<Object> get props => [transaction];
}

class FetchTransactions extends TransactionEvent {}

class FetchTransactionsWithFilter extends TransactionEvent {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? type; // 'income' or 'expense'
  final String? searchQuery;
  final int page;
  final int limit;

  const FetchTransactionsWithFilter({
    this.startDate,
    this.endDate,
    this.type,
    this.searchQuery,
    this.page = 1,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [
    startDate,
    endDate,
    type,
    searchQuery,
    page,
    limit,
  ];
}

class LoadMoreTransactions extends TransactionEvent {}

class DeleteTransaction extends TransactionEvent {
  final String transactionId;
  const DeleteTransaction(this.transactionId);
  @override
  List<Object> get props => [transactionId];
}

class UpdateTransaction extends TransactionEvent {
  final TransactionEntity transaction;
  const UpdateTransaction(this.transaction);
  @override
  List<Object> get props => [transaction];
}
