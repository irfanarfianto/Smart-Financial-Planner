import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/get_profile.dart';
import '../../domain/usecases/reset_all_data.dart';
import '../../domain/usecases/update_profile.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetProfile getProfile;
  final UpdateProfile updateProfile;
  final ResetAllData resetAllData;

  ProfileBloc({
    required this.getProfile,
    required this.updateProfile,
    required this.resetAllData,
  }) : super(ProfileInitial()) {
    on<LoadProfile>(_onLoadProfile);
    on<UpdateProfileEvent>(_onUpdateProfile);
    on<ResetDataEvent>(_onResetData);
  }

  Future<void> _onLoadProfile(
    LoadProfile event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    final result = await getProfile(NoParams());
    result.fold(
      (failure) => emit(ProfileError(failure.message)),
      (profile) => emit(ProfileLoaded(profile)),
    );
  }

  Future<void> _onUpdateProfile(
    UpdateProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    final result = await updateProfile(
      UpdateProfileParams(updates: event.updates),
    );
    result.fold((failure) => emit(ProfileError(failure.message)), (_) {
      emit(ProfileUpdateSuccess());
      // Reload profile after update
      add(LoadProfile());
    });
  }

  Future<void> _onResetData(
    ResetDataEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    final result = await resetAllData(NoParams());
    result.fold(
      (failure) => emit(ProfileError(failure.message)),
      (_) => emit(ProfileResetSuccess()),
    );
  }
}
