import '../../domain/entities/transaction_entity.dart';

abstract class TransactionRemoteDataSource {
  Future<void> addTransaction(TransactionEntity transaction);
  Future<List<TransactionEntity>> getTransactions();
}
