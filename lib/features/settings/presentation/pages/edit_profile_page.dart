import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_toast.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _isInitialized = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _initData(ProfileLoaded state) {
    if (!_isInitialized) {
      _fullNameController.text = state.profile.fullName ?? '';
      _usernameController.text = state.profile.username ?? '';
      _isInitialized = true;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final Map<String, dynamic> updates = {};
    if (_fullNameController.text.trim().isNotEmpty) {
      updates['full_name'] = _fullNameController.text.trim();
    }
    if (_usernameController.text.trim().isNotEmpty) {
      updates['username'] = _usernameController.text.trim();
    }

    if (updates.isEmpty) {
      Navigator.pop(context);
      return;
    }

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
          'Edit Profil',
          style: AppTextStyles.headlineMedium.copyWith(
            fontSize: 20,
            color: Colors.black,
          ),
        ),
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileUpdateSuccess) {
            AppToast.success(context, 'Profil berhasil diperbarui');
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  AppTextField(
                    controller: _fullNameController,
                    label: 'Nama Lengkap',
                    prefixIcon: const Icon(Icons.person),
                    hintText: 'Masukkan nama lengkap',
                    validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 24),
                  AppTextField(
                    controller: _usernameController,
                    label: 'Username',
                    prefixIcon: const Icon(Icons.alternate_email),
                    hintText: 'Masukkan username',
                    validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 40),
                  AppButton(
                    text: 'Simpan Perubahan',
                    isLoading: isLoading,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
