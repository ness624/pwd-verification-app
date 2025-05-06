import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:pwd_verification_app/core/storage/secure_storage.dart';
import 'package:pwd_verification_app/core/utils/logger.dart';
import 'package:pwd_verification_app/data/models/user.dart' as AppUser; // Use prefix

class AuthRepository {
  static const String _userKey = 'current_app_user';

  final SupabaseClient _supabaseClient;
  final SecureStorage _secureStorage;

  AuthRepository(this._supabaseClient, this._secureStorage);

  // Make client accessible to AuthBloc listener if needed (alternative to direct injection)
  // SupabaseClient get supabaseClient => _supabaseClient;

  Future<AppUser.User?> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) throw Exception('Email and password cannot be empty.');

    try {
      AppLogger.info('AuthRepository', 'Attempting Supabase login for email: $email');
      final AuthResponse res = await _supabaseClient.auth.signInWithPassword(
        email: email.trim(), password: password,
      );

      final supabaseUser = res.user;
      if (supabaseUser == null) throw Exception('Login completed but user data is missing from Supabase.');
      AppLogger.info('AuthRepository', 'Supabase login successful for user ID: ${supabaseUser.id}');

      final profileData = await _fetchUserProfile(supabaseUser.id);
      if (profileData == null) {
        await logout(); // Clean up inconsistent state
        throw Exception('Login successful, but failed to retrieve user profile.');
      }

      // --- Map profile data to AppUser.User ---
      // IMPORTANT: Ensure profileData keys ('username', 'full_name', 'role', etc.)
      // EXACTLY match your Supabase 'profiles' table column names.
      final appUser = AppUser.User(
        id: supabaseUser.id,
        email: supabaseUser.email, // Use nullable email from Supabase
        username: profileData['username'], // Get username from profile (make sure column exists)
        fullName: profileData['full_name'] ?? 'N/A', // Get full_name from profile
        role: AppUser.UserRole.values.firstWhere( // Parse role from profile
          (e) => e.name == profileData['role'],
          orElse: () => AppUser.UserRole.unknown
        ),
        establishmentId: profileData['establishment_id'] ?? '', // Get establishment_id
        establishmentName: profileData['establishment_name'] ?? '', // Get establishment_name
        lastLoginTime: supabaseUser.lastSignInAt != null // Use Supabase lastSignInAt
            ? DateTime.tryParse(supabaseUser.lastSignInAt!)
            : null,
        // Add other fields if necessary
      );

      await _secureStorage.write(_userKey, jsonEncode(appUser.toJson()));
      AppLogger.info('AuthRepository', 'App user profile saved to secure storage.');
      return appUser;

    } on AuthException catch (e) { /* Keep previous AuthException handling */
        AppLogger.error('AuthRepository', 'Supabase AuthException: ${e.statusCode} ${e.message}');
        if (e.message.toLowerCase().contains('invalid login credentials')) { throw Exception('Invalid email or password.'); }
        else if (e.message.toLowerCase().contains('email not confirmed')) { throw Exception('Please confirm your email address first.'); }
        throw Exception('Login failed: ${e.message}');
    } catch (e) { /* Keep previous generic error handling */
        AppLogger.error('AuthRepository', 'Generic login error: $e');
        if (e is Exception && e.toString().contains('failed to retrieve user profile')) { rethrow; }
        throw Exception('An unexpected error occurred during login.');
    }
  }

  Future<void> logout() async {
    try {
      AppLogger.info('AuthRepository', 'Attempting Supabase logout.');
      await _supabaseClient.auth.signOut();
    } on AuthException catch (e) {
      AppLogger.error('AuthRepository', 'Supabase AuthException during logout: ${e.message}');
      throw Exception('Logout failed: ${e.message}');
    } catch (e) {
      AppLogger.error('AuthRepository', 'Generic logout error: $e');
      throw Exception('An unexpected error occurred during logout.');
    } finally {
      await _secureStorage.delete(_userKey); // Always clear local data
      AppLogger.info('AuthRepository', 'Local app user data cleared after logout attempt.');
    }
  }

  Future<AppUser.User?> getCurrentUser() async {
    try {
      final currentSession = _supabaseClient.auth.currentSession;
      final supabaseUser = _supabaseClient.auth.currentUser;
      if (currentSession == null || supabaseUser == null) {
        await _secureStorage.delete(_userKey); return null;
      }

      final userJson = await _secureStorage.read(_userKey);
      if (userJson != null) {
        try {
          final storedUser = AppUser.User.fromJson(jsonDecode(userJson));
          if (storedUser.id == supabaseUser.id) return storedUser;
          else await _secureStorage.delete(_userKey);
        } catch (e) { await _secureStorage.delete(_userKey); }
      }

      AppLogger.info('AuthRepository', 'Fetching profile from Supabase for getCurrentUser...');
      final profileData = await _fetchUserProfile(supabaseUser.id);
      if (profileData == null) return null; // Cannot proceed without profile

      final appUser = AppUser.User(
         id: supabaseUser.id, email: supabaseUser.email,
         username: profileData['username'],
         fullName: profileData['full_name'] ?? 'N/A',
         role: AppUser.UserRole.values.firstWhere((e) => e.name == profileData['role'], orElse: () => AppUser.UserRole.unknown),
         establishmentId: profileData['establishment_id'] ?? '',
         establishmentName: profileData['establishment_name'] ?? '',
         lastLoginTime: supabaseUser.lastSignInAt != null ? DateTime.tryParse(supabaseUser.lastSignInAt!) : null,
       );
       await _secureStorage.write(_userKey, jsonEncode(appUser.toJson()));
       return appUser;

    } catch (e) {
      AppLogger.error('AuthRepository', 'Error in getCurrentUser: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _fetchUserProfile(String userId) async {
     try {
        // Try removing the explicit type first. If it still fails, there might be a deeper issue.
        final profileResponse = await _supabaseClient
            .from('profiles') // YOUR PROFILES TABLE NAME
            .select() // REMOVED <Map<String, dynamic>> temporarily
            .eq('id', userId)
            .single();
         // Ensure the response is actually a Map before returning
         if (profileResponse is Map<String, dynamic>) {
             return profileResponse;
         } else {
             AppLogger.error('AuthRepository', 'Profile fetch response was not a Map: $profileResponse');
             return null;
         }
      } on PostgrestException catch (e) { /* Keep previous handling */
         AppLogger.error('AuthRepository', 'PostgrestException fetching profile for $userId: ${e.message} (Code: ${e.code})'); return null;
      } catch (e) { /* Keep previous handling */
         AppLogger.error('AuthRepository', 'Unexpected error fetching profile for $userId: $e'); return null;
      }
  }
}