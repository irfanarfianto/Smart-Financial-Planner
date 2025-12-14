import 'package:flutter/material.dart';
import '../../../../core/widgets/app_shimmer.dart';

class DashboardShimmer extends StatelessWidget {
  const DashboardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (Welcome + Avatar)
          const SizedBox(height: 30), // Safe area approx
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  AppShimmer(width: 120, height: 16),
                  SizedBox(height: 8),
                  AppShimmer(width: 180, height: 28),
                ],
              ),
              const Spacer(),
              const AppShimmer.circular(width: 48, height: 48),
            ],
          ),
          const SizedBox(height: 16),
          const AppShimmer(
            width: 100,
            height: 24,
            borderRadius: 20,
          ), // Model Badge

          const SizedBox(height: 32),

          // Monthly Summary Card
          const AppShimmer(
            width: double.infinity,
            height: 180,
            borderRadius: 24,
          ),

          const SizedBox(height: 32),

          // Wallet List Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              AppShimmer(width: 120, height: 24),
              AppShimmer(width: 80, height: 24), // See all
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(
                child: AppShimmer(
                  width: double.infinity,
                  height: 160,
                  borderRadius: 20,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: AppShimmer(
                  width: double.infinity,
                  height: 160,
                  borderRadius: 20,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Financial Health Section
          const AppShimmer(width: 150, height: 24),
          const SizedBox(height: 16),
          const AppShimmer(
            width: double.infinity,
            height: 100,
            borderRadius: 16,
          ),

          const SizedBox(height: 32),

          // Chart Section (Pie)
          const AppShimmer(width: 180, height: 24),
          const SizedBox(height: 16),
          Center(child: const AppShimmer.circular(width: 250, height: 250)),
        ],
      ),
    );
  }
}
