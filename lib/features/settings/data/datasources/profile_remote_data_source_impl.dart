import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/exceptions.dart';
import '../models/profile_model.dart';
import 'profile_remote_data_source.dart';

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final SupabaseClient supabaseClient;

  ProfileRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<ProfileModel> getProfile() async {
    try {
      final userId = supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        throw ServerException('User not authenticated');
      }

      final response = await supabaseClient
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      return ProfileModel.fromJson(response);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> updateProfile(Map<String, dynamic> updates) async {
    try {
      final userId = supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        throw ServerException('User not authenticated');
      }

      // Add updated_at timestamp
      final updatesWithTimestamp = {
        ...updates,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await supabaseClient
          .from('profiles')
          .update(updatesWithTimestamp)
          .eq('id', userId);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> resetAllData() async {
    try {
      final userId = supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        throw ServerException('User not authenticated');
      }

      // Delete all transactions
      await supabaseClient.from('transactions').delete().eq('user_id', userId);

      // Delete all wallets
      await supabaseClient.from('wallets').delete().eq('user_id', userId);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
