import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/financial_model.dart';
import '../repositories/onboarding_repository.dart';

class GetFinancialModels implements UseCase<List<FinancialModel>, NoParams> {
  final OnboardingRepository repository;

  GetFinancialModels(this.repository);

  @override
  Future<Either<Failure, List<FinancialModel>>> call(NoParams params) async {
    return await repository.getFinancialModels();
  }
}
