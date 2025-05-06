import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:pwd_verification_app/core/utils/logger.dart';
import 'package:pwd_verification_app/data/repositories/auth_repository.dart';
import 'package:pwd_verification_app/presentation/bloc/auth/auth_event.dart';
import 'package:pwd_verification_app/presentation/bloc/auth/auth_state.dart' as local_auth_state; // Use prefix to avoid conflict
import 'package:pwd_verification_app/data/models/user.dart' as AppUser;

class AuthBloc extends Bloc<AuthEvent, local_auth_state.AuthState> {
  final AuthRepository _authRepository;
  final SupabaseClient _supabaseClient;
  // Explicitly type the stream data type, ensuring AuthState is imported
  StreamSubscription<AuthState>? _authStateSubscription; // Changed type to Supabase's AuthStateChange

  AuthBloc(this._authRepository, this._supabaseClient) : super(local_auth_state.AuthInitial()) {
    on<LoginEvent>(_onLogin);
    on<LogoutEvent>(_onLogout);
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<AuthServerEventOccurred>(_onAuthServerEventOccurred);

    _listenToSupabaseAuth();
  }

  void _listenToSupabaseAuth() {
    _authStateSubscription?.cancel();
    _authStateSubscription = _supabaseClient.auth.onAuthStateChange.listen(
      (data) { // data here is of type AuthStateChange
          final AuthChangeEvent event = data.event;
          AppLogger.info('AuthBloc', 'Supabase AuthStateChange received: $event');
          // Use the specific Supabase event type here
          add(AuthServerEventOccurred(event));
      },
      onError: (error) { AppLogger.error('AuthBloc', 'Error listening to Supabase auth state: $error'); }
    );
  }

  Future<void> _onAuthServerEventOccurred( AuthServerEventOccurred serverEvent, Emitter<local_auth_state.AuthState> emit ) async {
      AppLogger.info('AuthBloc', 'Handling AuthServerEventOccurred: ${serverEvent.event}');
      add(CheckAuthStatusEvent());
  }

  Future<void> _onLogin( LoginEvent event, Emitter<local_auth_state.AuthState> emit ) async {
    try { emit(local_auth_state.AuthLoading()); final AppUser.User? user = await _authRepository.login( event.username, event.password, ); if (user != null) { emit(local_auth_state.AuthAuthenticated(user)); AppLogger.info('AuthBloc', 'Login successful, user authenticated.'); } else { AppLogger.warning('AuthBloc', 'Repository login returned null unexpectedly.'); emit(const local_auth_state.AuthFailure('Login failed. Please try again.')); } } on AuthException catch (e) { AppLogger.error('AuthBloc', 'AuthException during login: ${e.message}'); emit(local_auth_state.AuthFailure('Login failed: ${e.message}')); } catch (e) { AppLogger.error('AuthBloc', 'Caught generic exception during login: $e'); final message = e.toString().startsWith("Exception: ") ? e.toString().substring(11) : e.toString(); emit(local_auth_state.AuthFailure(message)); }
  }

  Future<void> _onLogout( LogoutEvent event, Emitter<local_auth_state.AuthState> emit ) async {
     try { emit(local_auth_state.AuthLoading()); await _authRepository.logout(); AppLogger.info('AuthBloc', 'Logout action dispatched successfully.'); } catch (e) { AppLogger.error('AuthBloc', 'Caught exception during logout: $e'); final message = e.toString().startsWith("Exception: ") ? e.toString().substring(11) : e.toString(); emit(local_auth_state.AuthFailure('Logout failed: $message')); add(CheckAuthStatusEvent()); }
  }

  Future<void> _onCheckAuthStatus( CheckAuthStatusEvent event, Emitter<local_auth_state.AuthState> emit ) async {
    emit(local_auth_state.AuthLoading()); try { final AppUser.User? user = await _authRepository.getCurrentUser(); if (user != null) { if (state is! local_auth_state.AuthAuthenticated || (state as local_auth_state.AuthAuthenticated).user != user) { emit(local_auth_state.AuthAuthenticated(user)); AppLogger.info('AuthBloc', 'CheckAuthStatus: User is authenticated.'); } else { AppLogger.info('AuthBloc', 'CheckAuthStatus: User is authenticated (no state change).'); } } else { if (state is! local_auth_state.AuthUnauthenticated) { emit(local_auth_state.AuthUnauthenticated()); AppLogger.info('AuthBloc', 'CheckAuthStatus: User is not authenticated.'); } else { AppLogger.info('AuthBloc', 'CheckAuthStatus: User is not authenticated (no state change).'); } } } catch (e) { AppLogger.error('AuthBloc', 'Error during CheckAuthStatusEvent: $e'); if (state is! local_auth_state.AuthUnauthenticated) { emit(local_auth_state.AuthUnauthenticated()); } }
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    AppLogger.info('AuthBloc', 'Auth stream listener cancelled.');
    return super.close();
  }
}