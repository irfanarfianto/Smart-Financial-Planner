import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/profile_repository.dart';

class ResetAllData implements UseCase<void, NoParams> {
  final ProfileRepository repository;

  ResetAllData(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    return await repository.resetAllData();
  }
}
