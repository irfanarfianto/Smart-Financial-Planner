import 'package:equatable/equatable.dart';

abstract class PortfolioEvent extends Equatable {
  const PortfolioEvent();
  @override
  List<Object> get props => [];
}

class FetchFinancialModels extends PortfolioEvent {}

class SelectModel extends PortfolioEvent {
  final int modelId;
  const SelectModel(this.modelId);
  @override
  List<Object> get props => [modelId];
}
