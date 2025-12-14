import 'package:equatable/equatable.dart';

class FinancialModel extends Equatable {
  final int id;
  final String name;
  final double ratioNeeds;
  final double ratioInvest;
  final double ratioSavings;

  const FinancialModel({
    required this.id,
    required this.name,
    required this.ratioNeeds,
    required this.ratioInvest,
    required this.ratioSavings,
  });

  @override
  List<Object?> get props => [id, name, ratioNeeds, ratioInvest, ratioSavings];
}
