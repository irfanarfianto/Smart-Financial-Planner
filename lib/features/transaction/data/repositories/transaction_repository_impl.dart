import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/entities/transaction_entity.dart';
import '../datasources/transaction_remote_data_source.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionRemoteDataSource remoteDataSource;

  TransactionRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, void>> addTransaction(
    TransactionEntity transaction,
  ) async {
    try {
      await remoteDataSource.addTransaction(transaction);
      // ignore: void_checks
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TransactionEntity>>> getTransactions() async {
    try {
      final transactions = await remoteDataSource.getTransactions();
      return Right(transactions);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TransactionEntity>>> getTransactionsFiltered({
    DateTime? startDate,
    DateTime? endDate,
    String? type,
    String? searchQuery,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final transactions = await remoteDataSource.getTransactionsFiltered(
        startDate: startDate,
        endDate: endDate,
        type: type,
        searchQuery: searchQuery,
        limit: limit,
        offset: offset,
      );
      return Right(transactions);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTransaction(String transactionId) async {
    try {
      await remoteDataSource.deleteTransaction(transactionId);
      // ignore: void_checks
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateTransaction(
    TransactionEntity transaction,
  ) async {
    try {
      await remoteDataSource.updateTransaction(transaction);
      // ignore: void_checks
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
