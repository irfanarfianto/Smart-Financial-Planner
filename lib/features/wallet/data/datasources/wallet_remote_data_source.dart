import '../../domain/entities/wallet.dart';

abstract class WalletRemoteDataSource {
  Future<List<Wallet>> getWallets();
}
