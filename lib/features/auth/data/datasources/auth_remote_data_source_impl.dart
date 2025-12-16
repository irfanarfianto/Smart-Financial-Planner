import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../../core/error/exceptions.dart';
import 'auth_remote_data_source.dart';

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final sb.SupabaseClient supabaseClient;

  AuthRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<void> loginWithEmail(String email, String password) async {
    try {
      await supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw AuthenticationException(e.toString());
    }
  }

  @override
  Future<void> registerWithEmail(
    String email,
    String password,
    String fullName,
  ) async {
    try {
      final response = await supabaseClient.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );
      if (response.user == null) {
        throw AuthenticationException('Registration failed: No user returned');
      }
    } catch (e) {
      throw AuthenticationException(e.toString());
    }
  }

  @override
  Future<void> logout() async {
    try {
      await supabaseClient.auth.signOut();
    } catch (e) {
      throw AuthenticationException(e.toString());
    }
  }

  @override
  Future<bool> hasActiveModel(String userId) async {
    try {
      final response = await supabaseClient
          .from('profiles')
          .select('active_model_id')
          .eq('id', userId)
          .maybeSingle();

      return response != null && response['active_model_id'] != null;
    } catch (e) {
      throw AuthenticationException(e.toString());
    }
  }

  @override
  String? getCurrentUserId() {
    final session = supabaseClient.auth.currentSession;
    return session?.user.id;
  }
}
