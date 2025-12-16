import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, void>> loginWithEmail(
    String email,
    String password,
  ) async {
    try {
      await remoteDataSource.loginWithEmail(email, password);
      return const Right(null);
    } on AuthenticationException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> registerWithEmail(
    String email,
    String password,
    String fullName,
  ) async {
    try {
      await remoteDataSource.registerWithEmail(email, password, fullName);
      return const Right(null);
    } on AuthenticationException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await remoteDataSource.logout();
      return const Right(null);
    } on AuthenticationException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthStatus>> checkAuthStatus() async {
    try {
      final userId = remoteDataSource.getCurrentUserId();
      if (userId == null) {
        return const Right(AuthStatus.unauthenticated);
      }

      final hasModel = await remoteDataSource.hasActiveModel(userId);
      if (hasModel) {
        return const Right(AuthStatus.authenticated);
      } else {
        return const Right(AuthStatus.onboardingRequired);
      }
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }
}
