import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object> get props => [];
}

class LoadProfile extends ProfileEvent {}

class UpdateProfileEvent extends ProfileEvent {
  final Map<String, dynamic> updates;

  const UpdateProfileEvent(this.updates);

  @override
  List<Object> get props => [updates];
}

class ResetDataEvent extends ProfileEvent {}
