import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:pwd_verification_app/core/utils/logger.dart';

enum ConnectionStatus {
  offline,
  wifi,
  mobile,
  unknown
}

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<ConnectionStatus> _connectionStatusController = 
      StreamController<ConnectionStatus>.broadcast();
  
  Stream<ConnectionStatus> get connectionStatusStream => _connectionStatusController.stream;
  bool _isInitialized = false;
  
  // Late initialization because we don't want to start listening
  // until we have subscribers to the stream
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  
  ConnectionStatus _currentStatus = ConnectionStatus.unknown;
  ConnectionStatus get currentStatus => _currentStatus;
  
  void initialize() {
    if (_isInitialized) return;
    
    _initConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    _isInitialized = true;
  }
  
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectionStatusController.close();
    _isInitialized = false;
  }
  
  Future<void> _initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      AppLogger.error('ConnectivityService', 'Error checking connectivity: $e');
      _currentStatus = ConnectionStatus.unknown;
      _connectionStatusController.add(_currentStatus);
    }
  }
  
  void _updateConnectionStatus(ConnectivityResult result) {
    AppLogger.debug('ConnectivityService', 'Connectivity changed: $result');
    
    ConnectionStatus newStatus;
    
    switch (result) {
      case ConnectivityResult.wifi:
        newStatus = ConnectionStatus.wifi;
        break;
      case ConnectivityResult.mobile:
        newStatus = ConnectionStatus.mobile;
        break;
      case ConnectivityResult.none:
        newStatus = ConnectionStatus.offline;
        break;
      default:
        newStatus = ConnectionStatus.unknown;
        break;
    }
    
    if (_currentStatus != newStatus) {
      _currentStatus = newStatus;
      _connectionStatusController.add(_currentStatus);
      
      AppLogger.info('ConnectivityService', 'Connection status: $_currentStatus');
    }
  }
  
  bool get isConnected => 
      _currentStatus == ConnectionStatus.wifi || 
      _currentStatus == ConnectionStatus.mobile;
      
  bool get isWifi => _currentStatus == ConnectionStatus.wifi;
  
  bool get isMobile => _currentStatus == ConnectionStatus.mobile;
  
  bool get isOffline => _currentStatus == ConnectionStatus.offline;
  
  String get statusText {
    switch (_currentStatus) {
      case ConnectionStatus.wifi:
        return 'WiFi';
      case ConnectionStatus.mobile:
        return 'Mobile Data';
      case ConnectionStatus.offline:
        return 'Offline';
      case ConnectionStatus.unknown:
        return 'Unknown';
    }
  }
}