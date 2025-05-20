import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:pwd_verification_app/core/storage/secure_storage.dart';
import 'package:pwd_verification_app/core/utils/logger.dart';
import 'package:pwd_verification_app/data/models/user.dart' as AppUser;

class AuthRepository {
  static const String _userKey = 'current_app_user';

  final SupabaseClient _supabaseClient;
  final SecureStorage _secureStorage;

  AuthRepository(this._supabaseClient, this._secureStorage);

  // Make client accessible to AuthBloc listener
  SupabaseClient get supabaseClient => _supabaseClient;

  Future<void> register({
    required String email,
    required String password,
    required String fullName, 
    required String phoneNumber,
    required String organizationName,
    required String organizationType,
  }) async {
    // Validate email and password
    if (email.isEmpty) {
      throw Exception('Email cannot be empty.');
    }
    
    if (password.isEmpty) {
      throw Exception('Password cannot be empty.');
    }
    
    // Validate email format
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      throw Exception('Please enter a valid email address.');
    }

    // Validate password requirements
    if (password.length < 10) {
      throw Exception('Password must be at least 10 characters.');
    }
    
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      throw Exception('Password must contain at least one uppercase letter.');
    }
    
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      throw Exception('Password must contain at least one number.');
    }
    
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      throw Exception('Password must contain at least one symbol.');
    }
    
    // Validate phone number
    if (!RegExp(r'^\+?[0-9]{10,15}$').hasMatch(phoneNumber)) {
      throw Exception('Please enter a valid phone number (10-15 digits).');
    }
    
    try {
      AppLogger.info('AuthRepository', 'Attempting to register user with email: $email');
      
      // 1. Create auth user
      final AuthResponse res = await _supabaseClient.auth.signUp(
        email: email.trim(),
        password: password,
      );
      
      final supabaseAuthUser = res.user;
      if (supabaseAuthUser == null) {
        throw Exception('Registration completed but Supabase auth user data is missing.');
      }
      
      AppLogger.info('AuthRepository', 'Supabase auth user created successfully for ID: ${supabaseAuthUser.id}');
      
      // 2. Create mobile_user profile
      try {
        final mobileUserResponse = await _supabaseClient.from('mobile_users').insert({
          'auth_id': supabaseAuthUser.id,
          'full_name': fullName,
          'email': email.trim(),
          'phone_number': phoneNumber,
          'status': 'active', // default status
          'organization_name': organizationName,
          'organization_type': organizationType,
        }).select();
        
        AppLogger.info('AuthRepository', 'Mobile user profile created: $mobileUserResponse');
      } catch (e) {
        // If profile creation fails, clean up by deleting the auth user
        await _supabaseClient.auth.admin.deleteUser(supabaseAuthUser.id);
        AppLogger.error('AuthRepository', 'Failed to create mobile user profile, auth user deleted: $e');
        throw Exception('Failed to create user profile. Please try again.');
      }
      
      // Sign out after registration since user needs to confirm email
      await _supabaseClient.auth.signOut();
      AppLogger.info('AuthRepository', 'User signed out after registration. Email confirmation required.');
      
    } on AuthException catch (e) {
      AppLogger.error('AuthRepository', 'Supabase AuthException during registration: ${e.message}');
      if (e.message.toLowerCase().contains('email taken')) {
        throw Exception('This email is already registered. Please use a different email or try logging in.');
      }
      throw Exception('Registration failed: ${e.message}');
    } catch (e) {
      if (e is Exception && e.toString().contains('Failed to create user profile')) {
        rethrow; // Re-throw specific known errors
      }
      AppLogger.error('AuthRepository', 'Generic registration error: $e');
      throw Exception('An unexpected error occurred during registration.');
    }
  }

  Future<AppUser.User?> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) throw Exception('Email and password cannot be empty.');

    try {
      AppLogger.info('AuthRepository', 'Attempting Supabase login for email: $email');
      final AuthResponse res = await _supabaseClient.auth.signInWithPassword(
        email: email.trim(), password: password,
      );

      final supabaseAuthUser = res.user;
      if (supabaseAuthUser == null) throw Exception('Login completed but Supabase auth user data is missing.');
      AppLogger.info('AuthRepository', 'Supabase login successful for auth user ID: ${supabaseAuthUser.id}');

      final mobileUserProfileData = await _fetchMobileUserProfile(supabaseAuthUser.id);
      if (mobileUserProfileData == null) {
        await _supabaseClient.auth.signOut(); // Sign out if profile is missing to prevent partial login
        throw Exception('Login successful, but failed to retrieve mobile user profile. Please ensure a profile exists for this user.');
      }

      final appUser = AppUser.User(
        id: supabaseAuthUser.id, // This is the auth.users.id (User UID from Supabase Auth)
        email: supabaseAuthUser.email,
        username: null, // Not available in mobile_users table as per current schema
        fullName: mobileUserProfileData['full_name'] ?? 'N/A',
        role: AppUser.UserRole.unknown, // Not available in mobile_users table as per current schema
        establishmentId: mobileUserProfileData['id'], // This is mobile_users.id (PK of mobile_users table)
        establishmentName: mobileUserProfileData['organization_name'] ?? 'Default Establishment',
        lastLoginTime: mobileUserProfileData['last_login_at'] != null
            ? DateTime.tryParse(mobileUserProfileData['last_login_at'])
            : (supabaseAuthUser.lastSignInAt != null ? DateTime.tryParse(supabaseAuthUser.lastSignInAt!) : null),
      );

      await _secureStorage.write(_userKey, jsonEncode(appUser.toJson()));
      AppLogger.info('AuthRepository', 'App user profile saved to secure storage.');
      return appUser;

    } on AuthException catch (e) {
        AppLogger.error('AuthRepository', 'Supabase AuthException: ${e.statusCode} ${e.message}');
        if (e.message.toLowerCase().contains('invalid login credentials')) { throw Exception('Invalid email or password.'); }
        else if (e.message.toLowerCase().contains('email not confirmed')) { throw Exception('Please confirm your email address first.'); }
        throw Exception('Login failed: ${e.message}');
    } catch (e) {
        AppLogger.error('AuthRepository', 'Generic login error: $e');
        if (e is Exception && (e.toString().contains('failed to retrieve mobile user profile') || e.toString().contains('Invalid email or password'))) {
          rethrow; // Re-throw specific known errors
        }
        throw Exception('An unexpected error occurred during login.');
    }
  }

  Future<void> logout() async {
    try {
      AppLogger.info('AuthRepository', 'Attempting Supabase logout.');
      await _supabaseClient.auth.signOut();
    } on AuthException catch (e) {
      AppLogger.error('AuthRepository', 'Supabase AuthException during logout: ${e.message}');
      // Still proceed to clear local data even if Supabase logout fails
    } catch (e) {
      AppLogger.error('AuthRepository', 'Generic logout error: $e');
      // Still proceed to clear local data
    } finally {
      await _secureStorage.delete(_userKey);
      AppLogger.info('AuthRepository', 'Local app user data cleared after logout attempt.');
    }
  }

  Future<AppUser.User?> getCurrentUser() async {
    try {
      final currentSession = _supabaseClient.auth.currentSession;
      final supabaseAuthUser = _supabaseClient.auth.currentUser;
      if (currentSession == null || supabaseAuthUser == null) {
        await _secureStorage.delete(_userKey); return null;
      }

      final userJson = await _secureStorage.read(_userKey);
      if (userJson != null) {
        try {
          final storedUser = AppUser.User.fromJson(jsonDecode(userJson));
          if (storedUser.id == supabaseAuthUser.id) return storedUser;
          else await _secureStorage.delete(_userKey);
        } catch (e) { await _secureStorage.delete(_userKey); }
      }

      AppLogger.info('AuthRepository', 'Fetching mobile user profile from Supabase for getCurrentUser...');
      final mobileUserProfileData = await _fetchMobileUserProfile(supabaseAuthUser.id);
      if (mobileUserProfileData == null) return null;

      final appUser = AppUser.User(
         id: supabaseAuthUser.id,
         email: supabaseAuthUser.email,
         username: null,
         fullName: mobileUserProfileData['full_name'] ?? 'N/A',
         role: AppUser.UserRole.unknown,
         establishmentId: mobileUserProfileData['id'],
         establishmentName: mobileUserProfileData['organization_name'] ?? '',
         lastLoginTime: mobileUserProfileData['last_login_at'] != null
            ? DateTime.tryParse(mobileUserProfileData['last_login_at'])
            : (supabaseAuthUser.lastSignInAt != null ? DateTime.tryParse(supabaseAuthUser.lastSignInAt!) : null),
       );
       await _secureStorage.write(_userKey, jsonEncode(appUser.toJson()));
       return appUser;

    } catch (e) {
      AppLogger.error('AuthRepository', 'Error in getCurrentUser: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _fetchMobileUserProfile(String authUserIdFromSupabase) async {
     try {
        AppLogger.info('AuthRepository', 'Fetching mobile_user profile for auth_id: $authUserIdFromSupabase');
        final List<Map<String, dynamic>> profileResponse = await _supabaseClient
            .from('mobile_users')
            .select() // Select all columns
            .eq('auth_id', authUserIdFromSupabase); // Query by the auth_id foreign key

         if (profileResponse.isNotEmpty) {
             AppLogger.info('AuthRepository', 'Mobile user profile found: ${profileResponse.first}');
             return profileResponse.first; // Return the first match
         } else {
             AppLogger.warning('AuthRepository', 'No mobile_user profile found for auth_id: $authUserIdFromSupabase');
             return null;
         }
      } on PostgrestException catch (e) {
         AppLogger.error('AuthRepository', 'PostgrestException fetching mobile_user profile for auth_id $authUserIdFromSupabase: ${e.message} (Code: ${e.code})');
         return null;
      } catch (e) {
         AppLogger.error('AuthRepository', 'Unexpected error fetching mobile_user profile for auth_id $authUserIdFromSupabase: $e');
         return null;
      }
  }
}