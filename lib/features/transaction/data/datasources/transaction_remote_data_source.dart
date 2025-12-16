import '../../domain/entities/transaction_entity.dart';

abstract class TransactionRemoteDataSource {
  Future<void> addTransaction(TransactionEntity transaction);
  Future<List<TransactionEntity>> getTransactions();

  /// Get transactions with filters and pagination
  Future<List<TransactionEntity>> getTransactionsFiltered({
    DateTime? startDate,
    DateTime? endDate,
    String? type,
    String? searchQuery,
    int limit = 20,
    int offset = 0,
  });

  /// Delete a transaction by ID
  Future<void> deleteTransaction(String transactionId);

  /// Update an existing transaction
  Future<void> updateTransaction(TransactionEntity transaction);
}
