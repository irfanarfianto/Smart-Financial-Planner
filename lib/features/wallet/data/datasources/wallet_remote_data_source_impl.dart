import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/wallet.dart';
import '../models/wallet_model.dart';
import 'wallet_remote_data_source.dart';

class WalletRemoteDataSourceImpl implements WalletRemoteDataSource {
  final SupabaseClient supabaseClient;

  WalletRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<List<Wallet>> getWallets() async {
    try {
      final userId = supabaseClient.auth.currentUser!.id;
      final currentMonth = DateTime.now().toIso8601String().substring(
        0,
        7,
      ); // YYYY-MM

      final response = await supabaseClient
          .from('wallets')
          .select()
          .eq('user_id', userId)
          .eq('month_period', currentMonth);

      return (response as List)
          .map((json) => WalletModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
