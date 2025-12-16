import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../../settings/presentation/bloc/profile_bloc.dart';
import '../../../settings/presentation/bloc/profile_state.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        if (state is ProfileLoading) {
          return _buildLoadingState();
        }

        final user = Supabase.instance.client.auth.currentUser;
        String userName = user?.email?.split('@').first ?? 'User';
        String? avatarUrl;

        if (state is ProfileLoaded) {
          userName =
              state.profile.fullName ?? state.profile.username ?? userName;
          avatarUrl = state.profile.avatarUrl;
        }

        final userInitial = userName.isNotEmpty
            ? userName[0].toUpperCase()
            : 'U';
        final greeting = _getGreeting();

        return Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.blue.shade100,
              backgroundImage: avatarUrl != null
                  ? NetworkImage(avatarUrl)
                  : null,
              child: avatarUrl == null
                  ? Text(
                      userInitial,
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            // Greeting
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userName,
                    style: AppTextStyles.headlineSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Row(
      children: [
        const AppShimmer(width: 48, height: 48, borderRadius: 24),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            AppShimmer(width: 100, height: 14, borderRadius: 4),
            SizedBox(height: 8),
            AppShimmer(width: 150, height: 20, borderRadius: 4),
          ],
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Selamat Pagi';
    } else if (hour < 15) {
      return 'Selamat Siang';
    } else if (hour < 18) {
      return 'Selamat Sore';
    } else {
      return 'Selamat Malam';
    }
  }
}
