import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:pwd_verification_app/core/api/api_client.dart';
import 'package:pwd_verification_app/core/encryption/security_utils.dart';
import 'package:pwd_verification_app/core/services/connectivity_service.dart';
import 'package:pwd_verification_app/core/services/mock_data_service.dart';
import 'package:pwd_verification_app/core/storage/secure_storage.dart';
import 'package:pwd_verification_app/data/repositories/auth_repository.dart';
import 'package:pwd_verification_app/data/repositories/scan_repository.dart';
// REMOVE: import 'package:pwd_verification_app/data/services/auth_service.dart'; // No longer needed for AuthRepository
import 'package:pwd_verification_app/data/services/qr_service.dart';
import 'package:pwd_verification_app/presentation/bloc/auth/auth_bloc.dart';
import 'package:pwd_verification_app/presentation/bloc/scan/scan_bloc.dart';
import 'package:pwd_verification_app/presentation/bloc/connectivity/connectivity_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

final GetIt getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // --- Supabase Client ---
  getIt.registerSingleton<SupabaseClient>(Supabase.instance.client);

  // Core services
  getIt.registerSingleton<FlutterSecureStorage>(const FlutterSecureStorage());
  getIt.registerSingleton<SecureStorage>(SecureStorage(getIt<FlutterSecureStorage>()));

  getIt.registerSingleton<SecurityUtils>(SecurityUtils(getIt<FlutterSecureStorage>()));
  await getIt<SecurityUtils>().initialize();

  // Dio / ApiClient (Keep if used for non-Supabase calls like ScanRepository might)
  getIt.registerSingleton<Dio>(Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10), receiveTimeout: const Duration(seconds: 10),
    headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
  )));
  getIt.registerSingleton<ApiClient>(ApiClient(getIt<Dio>(), getIt<SecureStorage>()));

  // Connectivity service
  getIt.registerSingleton<ConnectivityService>(ConnectivityService());

  // Mock data service
  getIt.registerSingleton<MockDataService>(MockDataService());

  // Services
  getIt.registerSingleton<QRService>(QRService(getIt<SecurityUtils>()));
  // REMOVED: AuthService registration

  // Repositories
  getIt.registerSingleton<ScanRepository>(
    ScanRepository(getIt<ApiClient>(), getIt<QRService>(), getIt<SecureStorage>()),
  );
  // CORRECTED AuthRepository registration
  getIt.registerSingleton<AuthRepository>(
    AuthRepository(
      getIt<SupabaseClient>(), // Inject SupabaseClient
      getIt<SecureStorage>(),
    ),
  );

  // BLoCs
  getIt.registerFactory<ScanBloc>(() => ScanBloc(getIt<ScanRepository>()));
  // Inject SupabaseClient also into AuthBloc if needed for listener
  getIt.registerFactory<AuthBloc>(() => AuthBloc(
        getIt<AuthRepository>(),
        getIt<SupabaseClient>(), // Inject SupabaseClient into BLoC
      ));
  getIt.registerFactory<ConnectivityBloc>(() => ConnectivityBloc(getIt<ConnectivityService>()));
}