import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../wallet/domain/entities/wallet.dart';

abstract class AddTransactionEvent extends Equatable {
  const AddTransactionEvent();

  @override
  List<Object?> get props => [];
}

class TransactionTypeChanged extends AddTransactionEvent {
  final String type;
  const TransactionTypeChanged(this.type);

  @override
  List<Object> get props => [type];
}

class TransactionAmountChanged extends AddTransactionEvent {
  final String amount;
  const TransactionAmountChanged(this.amount);

  @override
  List<Object> get props => [amount];
}

class TransactionCategoryChanged extends AddTransactionEvent {
  final String? category;
  const TransactionCategoryChanged(this.category);

  @override
  List<Object?> get props => [category];
}

class TransactionDescriptionChanged extends AddTransactionEvent {
  final String description;
  const TransactionDescriptionChanged(this.description);

  @override
  List<Object> get props => [description];
}

class TransactionDateChanged extends AddTransactionEvent {
  final DateTime date;
  const TransactionDateChanged(this.date);

  @override
  List<Object> get props => [date];
}

class ScanReceiptRequested extends AddTransactionEvent {
  final ImageSource source;
  const ScanReceiptRequested(this.source);

  @override
  List<Object> get props => [source];
}

class WarningDismissed extends AddTransactionEvent {}

class SubmitTransactionRequested extends AddTransactionEvent {
  final List<Wallet> wallets;
  final bool ignoreWarning;

  const SubmitTransactionRequested({
    required this.wallets,
    this.ignoreWarning = false,
  });

  @override
  List<Object> get props => [wallets, ignoreWarning];
}
