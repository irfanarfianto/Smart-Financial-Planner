import '../../domain/entities/wallet.dart';

class WalletModel extends Wallet {
  const WalletModel({
    required super.id,
    required super.userId,
    required super.category,
    required super.currentBalance,
    required super.monthPeriod,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      id: json['id'],
      userId: json['user_id'],
      category: json['category'],
      currentBalance: (json['current_balance'] as num).toDouble(),
      monthPeriod: json['month_period'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'category': category,
      'current_balance': currentBalance,
      'month_period': monthPeriod,
    };
  }
}
