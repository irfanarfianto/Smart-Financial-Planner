import 'package:equatable/equatable.dart';
import '../../domain/entities/financial_model.dart';

abstract class OnboardingState extends Equatable {
  const OnboardingState();

  @override
  List<Object> get props => [];
}

class OnboardingInitial extends OnboardingState {}

class OnboardingLoading extends OnboardingState {}

class FinancialModelsLoaded extends OnboardingState {
  final List<FinancialModel> models;

  const FinancialModelsLoaded(this.models);

  @override
  List<Object> get props => [models];
}

class OnboardingSuccess extends OnboardingState {}

class OnboardingError extends OnboardingState {
  final String message;

  const OnboardingError(this.message);

  @override
  List<Object> get props => [message];
}
