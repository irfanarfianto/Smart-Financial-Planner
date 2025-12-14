import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_financial_planner/core/widgets/app_alert_dialog.dart';
import 'package:smart_financial_planner/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:smart_financial_planner/features/auth/presentation/bloc/auth_event.dart';
import 'package:smart_financial_planner/features/auth/presentation/bloc/auth_state.dart'
    as auth_state;

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/services/injection_container.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import 'edit_profile_page.dart';
import 'financial_settings_page.dart';
import 'notification_settings_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ProfileBloc>(
          create: (_) => sl<ProfileBloc>()..add(LoadProfile()),
        ),
        BlocProvider.value(value: sl<AuthBloc>()),
      ],
      child: const SettingsView(),
    );
  }
}

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirm = await AppAlertDialog.show(
      context,
      title: 'Konfirmasi Keluar',
      message: 'Apakah Anda yakin ingin keluar dari aplikasi?',
      positiveButtonText: 'Keluar',
      negativeButtonText: 'Batal',
      icon: Icons.logout,
      isDestructive: false,
    );

    if (confirm != true) return;
    if (!context.mounted) return;

    context.read<AuthBloc>().add(LogoutRequested());
  }

  Future<void> _resetData(BuildContext context) async {
    final confirm = await AppAlertDialog.show(
      context,
      title: '⚠️ Reset Semua Data',
      message:
          'PERINGATAN: Tindakan ini akan menghapus SEMUA data Anda termasuk:\n\n'
          '• Semua transaksi\n'
          '• Semua dompet\n'
          '• Riwayat keuangan\n\n'
          'Data yang dihapus TIDAK DAPAT dikembalikan!\n\n'
          'Apakah Anda yakin ingin melanjutkan?',
      positiveButtonText: 'Ya, Reset Semua',
      negativeButtonText: 'Batal',
      isDestructive: true,
      icon: Icons.delete_forever,
    );

    if (confirm != true) return;
    if (!context.mounted) return;

    context.read<ProfileBloc>().add(ResetDataEvent());
  }

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            BlocProvider.value(value: context.read<ProfileBloc>(), child: page),
      ),
    ).then((_) {
      if (!context.mounted) return;
      context.read<ProfileBloc>().add(LoadProfile());
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ProfileBloc, ProfileState>(
          listener: (context, state) {
            if (state is ProfileResetSuccess) {
              AppToast.success(context, 'Semua data berhasil dihapus!');
              context.go('/login');
            } else if (state is ProfileError) {
              AppToast.error(context, state.message);
            }
          },
        ),
        BlocListener<AuthBloc, auth_state.AuthState>(
          listener: (context, state) {
            if (state is auth_state.AuthInitial) {
              context.go('/login');
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: Colors.grey[50], // Light grey background
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Pengaturan',
            style: AppTextStyles.headlineMedium.copyWith(color: Colors.black),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Umum',
                style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),

              // Compaction: Grouped Container
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildSettingsTile(
                      icon: Icons.person_outline,
                      title: 'Profil Akun',
                      subtitle: 'Nama, Username',
                      onTap: () =>
                          _navigateTo(context, const EditProfilePage()),
                    ),
                    const Divider(height: 1, indent: 64, endIndent: 24),
                    _buildSettingsTile(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Keuangan',
                      subtitle: 'Model Keuangan, Safety Net',
                      onTap: () =>
                          _navigateTo(context, const FinancialSettingsPage()),
                    ),
                    const Divider(height: 1, indent: 64, endIndent: 24),
                    _buildSettingsTile(
                      icon: Icons.notifications_none,
                      title: 'Notifikasi',
                      subtitle: 'Jam Pengingat Harian',
                      onTap: () => _navigateTo(
                        context,
                        const NotificationSettingsPage(),
                      ),
                      isLast: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Actions Section - Cleaner Look
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout, size: 20),
                  label: const Text('Keluar dari Aplikasi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red,
                    elevation: 0,
                    side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Center(
                child: TextButton(
                  onPressed: () => _resetData(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.delete_forever, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Reset Semua Data',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.black87, size: 22),
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyLarge.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          subtitle,
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.grey[500],
            fontSize: 12,
          ),
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: Colors.grey,
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: isLast ? const Radius.circular(20) : Radius.zero,
          bottomRight: isLast ? const Radius.circular(20) : Radius.zero,
          topLeft: !isLast && title == 'Profil Akun'
              ? const Radius.circular(20)
              : Radius.zero, // Approximate First Item Check
          topRight: !isLast && title == 'Profil Akun'
              ? const Radius.circular(20)
              : Radius.zero,
        ),
      ),
    );
  }
}
