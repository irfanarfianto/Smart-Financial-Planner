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

  @override
  Future<List<TransactionEntity>> getTransactionsFiltered({
    DateTime? startDate,
    DateTime? endDate,
    String? type,
    String? searchQuery,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final user = supabaseClient.auth.currentUser;
      if (user == null) {
        throw AuthenticationException('User not authenticated');
      }

      var query = supabaseClient
          .from('transactions')
          .select()
          .eq('user_id', user.id);

      // Apply date filters
      if (startDate != null) {
        query = query.gte('transaction_date', startDate.toIso8601String());
      }
      if (endDate != null) {
        // Add 1 day to include the end date
        final endDateInclusive = endDate.add(const Duration(days: 1));
        query = query.lt(
          'transaction_date',
          endDateInclusive.toIso8601String(),
        );
      }

      // Apply type filter
      if (type != null && type.isNotEmpty) {
        query = query.eq('type', type);
      }

      // Apply search filter (case-insensitive)
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.ilike('description', '%$searchQuery%');
      }

      // Apply ordering and pagination, then execute
      final response = await query
          .order('transaction_date', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => TransactionModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> deleteTransaction(String transactionId) async {
    try {
      final user = supabaseClient.auth.currentUser;
      if (user == null) {
        throw AuthenticationException('User not authenticated');
      }

      await supabaseClient
          .from('transactions')
          .delete()
          .eq('id', transactionId)
          .eq('user_id', user.id); // Security: only delete own transactions
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> updateTransaction(TransactionEntity transaction) async {
    try {
      final user = supabaseClient.auth.currentUser;
      if (user == null) {
        throw AuthenticationException('User not authenticated');
      }

      if (transaction.id == null) {
        throw ServerException('Transaction ID is required for update');
      }

      final model = TransactionModel.fromEntity(transaction);
      final data = model.toJson();

      // Remove fields that shouldn't be updated
      data.remove('id');
      data.remove('user_id');
      data.remove('created_at');

      await supabaseClient
          .from('transactions')
          .update(data)
          .eq('id', transaction.id!)
          .eq('user_id', user.id); // Security: only update own transactions
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
