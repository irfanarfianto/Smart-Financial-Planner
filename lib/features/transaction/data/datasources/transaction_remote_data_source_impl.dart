import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/transaction_entity.dart';
import '../models/transaction_model.dart';
import 'transaction_remote_data_source.dart';

class TransactionRemoteDataSourceImpl implements TransactionRemoteDataSource {
  final SupabaseClient supabaseClient;

  TransactionRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<void> addTransaction(TransactionEntity transaction) async {
    try {
      final user = supabaseClient.auth.currentUser;
      if (user == null) {
        throw AuthenticationException('User not authenticated');
      }

      final model = TransactionModel.fromEntity(transaction);
      final data = model.toJson();
      data['user_id'] = user.id; // Ensure user_id is set from auth

      await supabaseClient.from('transactions').insert(data);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<TransactionEntity>> getTransactions() async {
    try {
      final user = supabaseClient.auth.currentUser;
      if (user == null) {
        throw AuthenticationException('User not authenticated');
      }

      final currentMonth = DateTime.now().toIso8601String().substring(
        0,
        7,
      ); // YYYY-MM

      final response = await supabaseClient
          .from('transactions')
          .select()
          .eq('user_id', user.id)
          .gte('transaction_date', '$currentMonth-01T00:00:00')
          .order('transaction_date', ascending: false);

      return (response as List)
          .map((json) => TransactionModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
