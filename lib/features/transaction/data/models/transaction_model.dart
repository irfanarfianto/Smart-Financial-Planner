import '../../domain/entities/transaction_entity.dart';

class TransactionModel extends TransactionEntity {
  const TransactionModel({
    super.id,
    super.userId,
    required super.amount,
    required super.type,
    super.category,
    super.description,
    super.receiptUrl,
    super.transactionDate,
  });

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      'amount': amount,
      'type': type,
      if (category != null) 'category': category,
      if (description != null) 'description': description,
      if (receiptUrl != null) 'receipt_url': receiptUrl,
      if (transactionDate != null)
        'transaction_date': transactionDate!.toIso8601String(),
    };
  }

  factory TransactionModel.fromEntity(TransactionEntity entity) {
    return TransactionModel(
      amount: entity.amount,
      type: entity.type,
      category: entity.category,
      description: entity.description,
      receiptUrl: entity.receiptUrl,
      transactionDate: entity.transactionDate ?? DateTime.now(),
    );
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      userId: json['user_id'],
      amount: (json['amount'] as num).toDouble(),
      type: json['type'],
      category: json['category'],
      description: json['description'],
      receiptUrl: json['receipt_url'],
      transactionDate: json['transaction_date'] != null
          ? DateTime.parse(json['transaction_date'])
          : null,
    );
  }
}
