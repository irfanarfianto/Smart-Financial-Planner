import 'package:equatable/equatable.dart';
import '../../domain/entities/transaction_entity.dart';

abstract class TransactionEvent extends Equatable {
  const TransactionEvent();
  @override
  List<Object> get props => [];
}

class CreateTransaction extends TransactionEvent {
  final TransactionEntity transaction;
  const CreateTransaction(this.transaction);
  @override
  List<Object> get props => [transaction];
}

class FetchTransactions extends TransactionEvent {}
