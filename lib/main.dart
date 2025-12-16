import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/constants/supabase_constants.dart';
import 'core/services/injection_container.dart' as di;

import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/services/notification_service.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/utils/app_bloc_observer.dart';

import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/settings/presentation/bloc/profile_bloc.dart';
import 'features/settings/presentation/bloc/profile_event.dart';
import 'features/transaction/presentation/bloc/transaction_bloc.dart';
import 'features/transaction/presentation/bloc/transaction_event.dart';
import 'features/wallet/presentation/bloc/wallet_bloc.dart';
import 'features/wallet/presentation/bloc/wallet_event.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force Status Bar to be transparent with Dark Icons (black icons)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark, // Android: Dark icons
      statusBarBrightness: Brightness.dark, // iOS: Dark icons
    ),
  );

  await initializeDateFormatting('id_ID', null);
  Bloc.observer = AppBlocObserver();

  await Supabase.initialize(
    url: SupabaseConstants.url,
    anonKey: SupabaseConstants.anonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
    realtimeClientOptions: const RealtimeClientOptions(eventsPerSecond: 2),
  );

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await di.init();

  // Initialize Notifications
  await di.sl<NotificationService>().initialize();

  // Register Background Handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Trigger initial auth check
  di.sl<AuthBloc>().add(CheckAuthStatus());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: di.sl<AuthBloc>()),
        BlocProvider(create: (_) => di.sl<ProfileBloc>()..add(LoadProfile())),
        BlocProvider(create: (_) => di.sl<WalletBloc>()..add(FetchWallets())),
        BlocProvider(
          create: (_) => di.sl<TransactionBloc>()..add(FetchTransactions()),
        ),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'Smart Financial Planner',
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
