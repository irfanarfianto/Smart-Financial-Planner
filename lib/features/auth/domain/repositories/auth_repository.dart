import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';

abstract class AuthRepository {
  Future<Either<Failure, void>> loginWithEmail(String email, String password);
  Future<Either<Failure, void>> registerWithEmail(
    String email,
    String password,
    String fullName,
  );
  Future<Either<Failure, void>> logout();
}
