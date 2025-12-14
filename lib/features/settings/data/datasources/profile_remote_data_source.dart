import '../models/profile_model.dart';

abstract class ProfileRemoteDataSource {
  Future<ProfileModel> getProfile();
  Future<void> updateProfile(Map<String, dynamic> updates);
  Future<void> resetAllData();
}
