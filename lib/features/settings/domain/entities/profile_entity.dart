import 'package:equatable/equatable.dart';

class ProfileEntity extends Equatable {
  final String id;
  final String? fullName;
  final String? username;
  final String? avatarUrl;
  final int fixedCostThreshold;
  final int activeModelId;
  final String dailyReminderTime;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProfileEntity({
    required this.id,
    this.fullName,
    this.username,
    this.avatarUrl,
    required this.fixedCostThreshold,
    required this.activeModelId,
    required this.dailyReminderTime,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    fullName,
    username,
    avatarUrl,
    fixedCostThreshold,
    activeModelId,
    dailyReminderTime,
    createdAt,
    updatedAt,
  ];
}
