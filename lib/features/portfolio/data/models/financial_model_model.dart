import 'package:smart_financial_planner/features/onboarding/domain/entities/financial_model.dart';

class FinancialModelModel extends FinancialModel {
  const FinancialModelModel({
    required super.id,
    required super.name,
    required super.ratioNeeds,
    required super.ratioInvest,
    required super.ratioSavings,
  });

  factory FinancialModelModel.fromJson(Map<String, dynamic> json) {
    return FinancialModelModel(
      id: json['id'],
      name: json['name'],
      ratioNeeds: (json['ratio_needs'] as num).toDouble(),
      ratioInvest: (json['ratio_invest'] as num).toDouble(),
      ratioSavings: (json['ratio_savings'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ratio_needs': ratioNeeds,
      'ratio_invest': ratioInvest,
      'ratio_savings': ratioSavings,
    };
  }
}
