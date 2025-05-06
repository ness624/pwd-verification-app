// auth_service.dart
import 'package:dio/dio.dart';
import 'package:pwd_verification_app/core/api/api_client.dart';
import 'package:pwd_verification_app/core/storage/secure_storage.dart';
import 'package:pwd_verification_app/core/utils/logger.dart';

class AuthService {
  final ApiClient _apiClient;
  final SecureStorage _secureStorage;
  
  AuthService(this._apiClient, this._secureStorage);
  
  Future<Map<String, dynamic>?> login(String username, String password) async {
    try {
      final response = await _apiClient.post(
        '/auth/login',
        data: {
          'username': username,
          'password': password,
        },
      );
      
      if (response.statusCode == 200) {
        return response.data;
      }
      
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        AppLogger.warning('AuthService', 'Invalid credentials');
        return null;
      }
      
      AppLogger.error('AuthService', 'Login error: $e');
      throw Exception('Login failed: ${e.message}');
    } catch (e) {
      AppLogger.error('AuthService', 'Login error: $e');
      throw Exception('Login failed: $e');
    }
  }
}