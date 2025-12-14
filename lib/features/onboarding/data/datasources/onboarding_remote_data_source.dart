import '../../domain/entities/financial_model.dart';

abstract class OnboardingRemoteDataSource {
  Future<List<FinancialModel>> getFinancialModels();
  Future<void> selectFinancialModel(int modelId);
}
