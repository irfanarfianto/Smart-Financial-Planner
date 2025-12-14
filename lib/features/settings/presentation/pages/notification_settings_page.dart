import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_toast.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import '../widgets/reminder_time_picker.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);
  bool _isInitialized = false;

  void _initData(ProfileLoaded state) {
    if (!_isInitialized) {
      final timeParts = state.profile.dailyReminderTime.split(':');
      if (timeParts.length >= 2) {
        _reminderTime = TimeOfDay(
          hour: int.tryParse(timeParts[0]) ?? 20,
          minute: int.tryParse(timeParts[1]) ?? 0,
        );
      }
      _isInitialized = true;
    }
  }

  Future<void> _save() async {
    final Map<String, dynamic> updates = {};
    updates['daily_reminder_time'] =
        '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}:00';

    context.read<ProfileBloc>().add(UpdateProfileEvent(updates));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifikasi',
          style: AppTextStyles.headlineMedium.copyWith(
            fontSize: 20,
            color: Colors.black,
          ),
        ),
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileUpdateSuccess) {
            AppToast.success(context, 'Waktu pengingat diperbarui');
            Navigator.pop(context);
          } else if (state is ProfileError) {
            AppToast.error(context, state.message);
          }
        },
        builder: (context, state) {
          if (state is ProfileLoaded) {
            _initData(state);
          }

          final isLoading = state is ProfileLoading;

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pengingat Harian',
                  style: AppTextStyles.headlineMedium.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  'Atur waktu pengingat harian untuk mencatat transaksi',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                ReminderTimePicker(
                  reminderTime: _reminderTime,
                  onTimeChanged: (time) {
                    setState(() {
                      _reminderTime = time;
                    });
                  },
                ),
                const SizedBox(height: 40),
                AppButton(
                  text: 'Simpan Perubahan',
                  isLoading: isLoading,
                  onPressed: _save,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
