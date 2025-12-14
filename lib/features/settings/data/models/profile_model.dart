import '../../domain/entities/profile_entity.dart';

class ProfileModel extends ProfileEntity {
  const ProfileModel({
    required super.id,
    super.fullName,
    super.username,
    super.avatarUrl,
    required super.fixedCostThreshold,
    required super.activeModelId,
    required super.dailyReminderTime,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      username: json['username'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      fixedCostThreshold: (json['fixed_cost_threshold'] as num?)?.toInt() ?? 0,
      activeModelId: (json['active_model_id'] as num?)?.toInt() ?? 1,
      dailyReminderTime: json['daily_reminder_time'] as String? ?? '09:00:00',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'username': username,
      'avatar_url': avatarUrl,
      'fixed_cost_threshold': fixedCostThreshold,
      'active_model_id': activeModelId,
      'daily_reminder_time': dailyReminderTime,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
