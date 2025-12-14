import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/profile_repository.dart';

class UpdateProfile implements UseCase<void, UpdateProfileParams> {
  final ProfileRepository repository;

  UpdateProfile(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateProfileParams params) async {
    return await repository.updateProfile(params.updates);
  }
}

class UpdateProfileParams extends Equatable {
  final Map<String, dynamic> updates;

  const UpdateProfileParams({required this.updates});

  @override
  List<Object> get props => [updates];
}
