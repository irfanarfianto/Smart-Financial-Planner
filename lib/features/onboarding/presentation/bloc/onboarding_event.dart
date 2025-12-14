import 'package:equatable/equatable.dart';

abstract class OnboardingEvent extends Equatable {
  const OnboardingEvent();

  @override
  List<Object> get props => [];
}

class FetchFinancialModelsEvent extends OnboardingEvent {}

class SelectModelEvent extends OnboardingEvent {
  final int modelId;

  const SelectModelEvent(this.modelId);

  @override
  List<Object> get props => [modelId];
}
