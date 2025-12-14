import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/wallet.dart';
import '../repositories/wallet_repository.dart';

class GetWallets implements UseCase<List<Wallet>, NoParams> {
  final WalletRepository repository;

  GetWallets(this.repository);

  @override
  Future<Either<Failure, List<Wallet>>> call(NoParams params) async {
    return await repository.getWallets();
  }
}
