import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_financial_planner/features/dashboard/presentation/pages/financial_health_detail_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/transaction/presentation/pages/add_transaction_page.dart';
import '../../features/transaction/presentation/pages/edit_transaction_page.dart';
import '../../features/transaction/presentation/pages/transaction_history_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import 'package:smart_financial_planner/core/services/injection_container.dart'
    as di;
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import 'dart:async';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

class AppRouter {
  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation:
        '/dashboard', // Start at root loading, then redirect based on auth
    refreshListenable: _AuthStream(di.sl<AuthBloc>().stream),
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        path: '/add-transaction',
        builder: (context, state) => const AddTransactionPage(),
      ),
      GoRoute(
        path: '/edit-transaction',
        builder: (context, state) {
          final transaction = state.extra as Map<String, dynamic>;
          return EditTransactionPage(transaction: transaction['transaction']);
        },
      ),
      GoRoute(
        path: '/transaction-history',
        builder: (context, state) => const TransactionHistoryPage(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/financial-health-detail',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>;
          return FinancialHealthDetailPage(
            needsBalance: extras['needsBalance'],
            totalExpense: extras['totalExpense'],
            daysInMonth: extras['daysInMonth'],
          );
        },
      ),
    ],
    redirect: (context, state) {
      final authState = di.sl<AuthBloc>().state;
      final loggingIn = state.uri.toString() == '/login';
      final onboarding = state.uri.toString() == '/onboarding';

      // If initial/loading, show nothing or splash (redirect to login if taking too long?)
      // Actually, with refreshListenable, it re-evaluates when state changes.

      if (authState is AuthUnauthenticated || authState is AuthFailureState) {
        if (!loggingIn) return '/login';
      }

      if (authState is AuthOnboardingRequired) {
        if (!onboarding) return '/onboarding';
      }

      if (authState is AuthAuthenticated) {
        if (loggingIn || onboarding) return '/dashboard';

        // Ensure user lands on dashboard if they are at root '/' (which we removed but just in case)
        if (state.uri.toString() == '/') return '/dashboard';
      }

      // Handle uninitialized state (before check completes)
      // If we are mostly waiting, maybe stay on a simple loading screen or 'login' by default?
      // Since we fire CheckAuthStatus immediately, we likely get a state quickly.
      // But until then, state is AuthInitial.
      if (authState is AuthInitial) {
        // Maybe return null (let it be) or return '/login' as safe default?
        // Or creating a simple loading page route?
        // For now let's assume it stays on the requested page until state updates.
        // If requesting dashboard, stays dashboard (white screen?).
        // Ideally we have a '/splash' for loading state.
        // But user asked to "remove splash page file usage".
        // We can use a minimal internal widget or simply let it load.
        return null;
      }

      return null;
    },
  );
}

class _AuthStream extends ChangeNotifier {
  late final StreamSubscription<AuthState> _subscription;

  _AuthStream(Stream<AuthState> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
