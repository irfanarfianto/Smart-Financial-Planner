import 'package:equatable/equatable.dart';

class TransactionEntity extends Equatable {
  final String? id;
  final String? userId;
  final double amount;
  final String type; // INCOME, EXPENSE, TRANSFER
  final String? category; // NEEDS, INVEST, SAVING (Nullable for INCOME)
  final String? description;
  final String? receiptUrl;
  final DateTime? transactionDate;

  const TransactionEntity({
    this.id,
    this.userId,
    required this.amount,
    required this.type,
    this.category,
    this.description,
    this.receiptUrl,
    this.transactionDate,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    amount,
    type,
    category,
    description,
    receiptUrl,
    transactionDate,
  ];
}
