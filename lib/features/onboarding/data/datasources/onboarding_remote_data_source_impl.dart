import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/financial_model.dart';
import '../models/financial_model_model.dart';
import 'onboarding_remote_data_source.dart';

class OnboardingRemoteDataSourceImpl implements OnboardingRemoteDataSource {
  final SupabaseClient supabaseClient;

  OnboardingRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<List<FinancialModel>> getFinancialModels() async {
    try {
      final response = await supabaseClient.from('financial_models').select();

      return (response as List)
          .map((json) => FinancialModelModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> selectFinancialModel(int modelId) async {
    try {
      final user = supabaseClient.auth.currentUser;
      if (user == null) {
        throw AuthenticationException('User not authenticated');
      }

      await supabaseClient.from('profiles').upsert({
        'id': user.id,
        'active_model_id': modelId,
      });
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
