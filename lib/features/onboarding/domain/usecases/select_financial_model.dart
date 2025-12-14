import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/onboarding_repository.dart';
import 'package:equatable/equatable.dart';

class SelectFinancialModel
    implements UseCase<void, SelectFinancialModelParams> {
  final OnboardingRepository repository;

  SelectFinancialModel(this.repository);

  @override
  Future<Either<Failure, void>> call(SelectFinancialModelParams params) async {
    return await repository.selectFinancialModel(params.modelId);
  }
}

class SelectFinancialModelParams extends Equatable {
  final int modelId;

  const SelectFinancialModelParams({required this.modelId});

  @override
  List<Object?> get props => [modelId];
}
