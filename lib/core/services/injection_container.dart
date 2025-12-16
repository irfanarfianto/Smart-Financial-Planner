import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_financial_planner/core/services/notification_service.dart';
import 'package:smart_financial_planner/core/services/ocr_service.dart';
import 'package:smart_financial_planner/core/services/storage_service.dart';

import '../../features/portfolio/presentation/bloc/portfolio_bloc.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/datasources/auth_remote_data_source_impl.dart';
import '../../features/wallet/presentation/bloc/wallet_bloc.dart';
import '../../features/wallet/domain/repositories/wallet_repository.dart';
import '../../features/wallet/data/repositories/wallet_repository_impl.dart';
import '../../features/wallet/data/datasources/wallet_remote_data_source.dart';
import '../../features/wallet/data/datasources/wallet_remote_data_source_impl.dart';
import '../../features/wallet/domain/usecases/get_wallets.dart';
import '../../features/transaction/presentation/bloc/transaction_bloc.dart';
import '../../features/transaction/domain/repositories/transaction_repository.dart';
import '../../features/transaction/data/repositories/transaction_repository_impl.dart';
import '../../features/transaction/data/datasources/transaction_remote_data_source.dart';
import '../../features/transaction/data/datasources/transaction_remote_data_source_impl.dart';
import '../../features/transaction/domain/usecases/add_transaction.dart';
import '../../features/transaction/domain/usecases/get_transactions.dart';
import '../../features/transaction/presentation/bloc/add_transaction/add_transaction_bloc.dart';

import '../../features/onboarding/data/repositories/onboarding_repository_impl.dart';
import '../../features/onboarding/domain/repositories/onboarding_repository.dart';
import '../../features/onboarding/data/datasources/onboarding_remote_data_source.dart';
import '../../features/onboarding/data/datasources/onboarding_remote_data_source_impl.dart';
import '../../features/onboarding/domain/usecases/get_financial_models.dart';
import '../../features/onboarding/domain/usecases/select_financial_model.dart';
import '../../features/onboarding/presentation/bloc/onboarding_bloc.dart';

import '../../features/settings/presentation/bloc/profile_bloc.dart';
import '../../features/settings/domain/repositories/profile_repository.dart';
import '../../features/settings/data/repositories/profile_repository_impl.dart';
import '../../features/settings/data/datasources/profile_remote_data_source.dart';
import '../../features/settings/data/datasources/profile_remote_data_source_impl.dart';
import '../../features/settings/domain/usecases/get_profile.dart';
import '../../features/settings/domain/usecases/update_profile.dart';
import '../../features/settings/domain/usecases/reset_all_data.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ! External
  final client = Supabase.instance.client;
  sl.registerLazySingleton(() => client);

  // ! Core
  sl.registerLazySingleton(() => NotificationService());
  sl.registerLazySingleton(() => OcrService());
  sl.registerLazySingleton(() => StorageService());

  // ! Features - Portfolio
  // Bloc
  sl.registerFactory(
    () => PortfolioBloc(getFinancialModels: sl(), selectFinancialModel: sl()),
  );

  // ! Features - Onboarding
  // Bloc
  sl.registerFactory(
    () => OnboardingBloc(getFinancialModels: sl(), selectFinancialModel: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetFinancialModels(sl()));
  sl.registerLazySingleton(() => SelectFinancialModel(sl()));

  // Repository
  sl.registerLazySingleton<OnboardingRepository>(
    () => OnboardingRepositoryImpl(sl()),
  );

  // Data sources
  sl.registerLazySingleton<OnboardingRemoteDataSource>(
    () => OnboardingRemoteDataSourceImpl(sl()),
  );

  // ! Features - Profile (Settings)
  // Bloc
  sl.registerFactory(
    () =>
        ProfileBloc(getProfile: sl(), updateProfile: sl(), resetAllData: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetProfile(sl()));
  sl.registerLazySingleton(() => UpdateProfile(sl()));
  sl.registerLazySingleton(() => ResetAllData(sl()));

  // Repository
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(remoteDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(supabaseClient: sl()),
  );

  // ! Features - Auth
  // Bloc
  // Bloc
  sl.registerLazySingleton(() => AuthBloc(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl<AuthRemoteDataSource>()),
  );

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(supabaseClient: sl()),
  );
  // ... (imports)

  // ... (init function)

  // ! Features - Auth
  // ...

  // ! Features - Wallet
  // Bloc
  sl.registerFactory(() => WalletBloc(getWallets: sl()));

  // Use cases
  sl.registerLazySingleton(() => GetWallets(sl()));

  // Repository
  sl.registerLazySingleton<WalletRepository>(() => WalletRepositoryImpl(sl()));

  // Data sources
  sl.registerLazySingleton<WalletRemoteDataSource>(
    () => WalletRemoteDataSourceImpl(sl()),
  );
  // ! Features - Transaction
  // Bloc
  sl.registerFactory(
    () => TransactionBloc(
      addTransaction: sl(),
      getTransactions: sl(),
      repository: sl(),
    ),
  );
  sl.registerFactory(
    () => AddTransactionBloc(
      addTransaction: sl(),
      ocrService: sl(),
      storageService: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => AddTransaction(sl()));
  sl.registerLazySingleton(() => GetTransactions(sl()));

  // Repository
  sl.registerLazySingleton<TransactionRepository>(
    () => TransactionRepositoryImpl(sl()),
  );

  // Data sources
  sl.registerLazySingleton<TransactionRemoteDataSource>(
    () => TransactionRemoteDataSourceImpl(sl()),
  );
}
