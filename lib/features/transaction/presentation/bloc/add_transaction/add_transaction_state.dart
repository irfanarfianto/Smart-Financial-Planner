import 'dart:io';
import 'package:equatable/equatable.dart';

enum AddTransactionStatus {
  initial,
  scanning,
  uploading,
  submitting,
  success,
  failure,
}

class AddTransactionState extends Equatable {
  final String amount;
  final String description;
  final String type; // 'INCOME' or 'EXPENSE'
  final String? category;
  final DateTime date;
  final File? receiptImage;
  final AddTransactionStatus status;
  final String? errorMessage;
  final String? warningMessage; // If set, UI should show dialog

  const AddTransactionState({
    this.amount = '',
    this.description = '',
    this.type = 'INCOME',
    this.category,
    required this.date,
    this.receiptImage,
    this.status = AddTransactionStatus.initial,
    this.errorMessage,
    this.warningMessage,
  });

  AddTransactionState copyWith({
    String? amount,
    String? description,
    String? type,
    String? category,
    DateTime? date,
    File? receiptImage,
    AddTransactionStatus? status,
    String? errorMessage,
    String? warningMessage,
    bool clearCategory = false,
    bool clearWarning = false,
  }) {
    return AddTransactionState(
      amount: amount ?? this.amount,
      description: description ?? this.description,
      type: type ?? this.type,
      category: clearCategory ? null : (category ?? this.category),
      date: date ?? this.date,
      receiptImage: receiptImage ?? this.receiptImage,
      status: status ?? this.status,
      errorMessage: errorMessage, // Always replace error message
      warningMessage: clearWarning
          ? null
          : (warningMessage ?? this.warningMessage),
    );
  }

  @override
  List<Object?> get props => [
    amount,
    description,
    type,
    category,
    date,
    receiptImage,
    status,
    errorMessage,
    warningMessage,
  ];
}
