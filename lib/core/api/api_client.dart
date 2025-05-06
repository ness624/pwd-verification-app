// api_client.dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:pwd_verification_app/core/storage/secure_storage.dart';
import 'package:pwd_verification_app/core/utils/logger.dart';
import 'package:pwd_verification_app/data/models/scan_result.dart';

class ApiClient {
  final Dio _dio;
  final SecureStorage _secureStorage;
  final Connectivity _connectivity = Connectivity();
  
  ApiClient(this._dio, this._secureStorage) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: _onResponse,
        onError: _onError,
      ),
    );
  }
  
  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Add authentication token if available
    final authToken = await _secureStorage.read('auth_token');
    if (authToken != null) {
      options.headers['Authorization'] = 'Bearer $authToken';
    }
    
    AppLogger.debug('ApiClient', 'Request: ${options.method} ${options.path}');
    handler.next(options);
  }
  
  void _onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    AppLogger.debug(
      'ApiClient',
      'Response: ${response.statusCode} ${response.requestOptions.path}',
    );
    handler.next(response);
  }
  
  void _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) {
    AppLogger.error(
      'ApiClient',
      'Error: ${error.response?.statusCode} ${error.requestOptions.path}',
    );
    
    // Handle token expiration
    if (error.response?.statusCode == 401) {
      _handleUnauthorized();
    }
    
    handler.next(error);
  }
  
  Future<void> _handleUnauthorized() async {
    // Clear auth token and notify app to navigate to login
    await _secureStorage.delete('auth_token');
    await _secureStorage.delete('current_user');
    
    // In a real app, you might want to use an event bus or similar to notify
    // the app to navigate to the login screen
  }
  
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.get(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
  }
  
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }
  
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }
  
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.delete(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }
  
  // Added methods for ScanRepository
  Future<bool> checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      AppLogger.error('ApiClient', 'Error checking connectivity: $e');
      return false;
    }
  }
  
  Future<bool> sendScanResult(ScanResult scanResult) async {
    try {
      final response = await post(
        '/scans',
        data: scanResult.toJson(),
      );
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      AppLogger.error('ApiClient', 'Error sending scan result: $e');
      return false;
    }
  }
}
