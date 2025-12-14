import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/financial_model.dart';

abstract class OnboardingRepository {
  Future<Either<Failure, List<FinancialModel>>> getFinancialModels();
  Future<Either<Failure, void>> selectFinancialModel(int modelId);
}
