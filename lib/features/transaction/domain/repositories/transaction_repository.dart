import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/transaction_entity.dart';

abstract class TransactionRepository {
  Future<Either<Failure, void>> addTransaction(TransactionEntity transaction);
  Future<Either<Failure, List<TransactionEntity>>> getTransactions();

  Future<Either<Failure, List<TransactionEntity>>> getTransactionsFiltered({
    DateTime? startDate,
    DateTime? endDate,
    String? type,
    String? searchQuery,
    int limit = 20,
    int offset = 0,
  });

  Future<Either<Failure, void>> deleteTransaction(String transactionId);
  Future<Either<Failure, void>> updateTransaction(
    TransactionEntity transaction,
  );
}
