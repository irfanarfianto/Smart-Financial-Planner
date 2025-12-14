import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository repository;

  AuthBloc(this.repository) : super(AuthInitial()) {
    on<LoginRequested>(_onLogin);
    on<RegisterRequested>(_onRegister);
    on<LogoutRequested>(_onLogout);
  }

  Future<void> _onLogin(LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await repository.loginWithEmail(event.email, event.password);
    result.fold(
      (failure) => emit(AuthFailureState(failure.message)),
      (_) => emit(const AuthSuccess(message: 'Login Successful')),
    );
  }

  Future<void> _onRegister(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await repository.registerWithEmail(
      event.email,
      event.password,
      event.fullName,
    );
    result.fold(
      (failure) => emit(AuthFailureState(failure.message)),
      (_) => emit(const AuthSuccess(message: 'Registration Successful')),
    );
  }

  Future<void> _onLogout(LogoutRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await repository.logout();
    result.fold(
      (failure) => emit(AuthFailureState(failure.message)),
      (_) => emit(AuthInitial()),
    );
  }
}
