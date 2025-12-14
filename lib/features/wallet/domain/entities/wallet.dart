import 'package:equatable/equatable.dart';

class Wallet extends Equatable {
  final String id;
  final String userId;
  final String category;
  final double currentBalance;
  final String monthPeriod;

  const Wallet({
    required this.id,
    required this.userId,
    required this.category,
    required this.currentBalance,
    required this.monthPeriod,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    category,
    currentBalance,
    monthPeriod,
  ];
}
