import 'package:equatable/equatable.dart';
import '../../../onboarding/domain/entities/financial_model.dart';

abstract class PortfolioState extends Equatable {
  const PortfolioState();
  @override
  List<Object> get props => [];
}

class PortfolioInitial extends PortfolioState {}

class PortfolioLoading extends PortfolioState {}

class PortfolioLoaded extends PortfolioState {
  final List<FinancialModel> models;
  const PortfolioLoaded(this.models);
  @override
  List<Object> get props => [models];
}

class PortfolioError extends PortfolioState {
  final String message;
  const PortfolioError(this.message);
  @override
  List<Object> get props => [message];
}

class PortfolioSelectionSuccess extends PortfolioState {}

class PortfolioSelectionLoading extends PortfolioState {}
