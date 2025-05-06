// connectivity_state.dart
import 'package:equatable/equatable.dart';
import 'package:pwd_verification_app/core/services/connectivity_service.dart';

abstract class ConnectivityState extends Equatable {
  const ConnectivityState();
  
  @override
  List<Object?> get props => [];
}

class ConnectivityInitial extends ConnectivityState {}

class ConnectivityStatus extends ConnectivityState {
  final ConnectionStatus status;
  final bool isConnected;
  final bool isWifi;
  final bool isMobile;
  final String message;
  
  const ConnectivityStatus({
    required this.status,
    required this.isConnected,
    required this.isWifi,
    required this.isMobile,
    required this.message,
  });
  
  @override
  List<Object?> get props => [status, isConnected, isWifi, isMobile, message];
  
  factory ConnectivityStatus.fromConnectionStatus(ConnectionStatus status) {
    final isConnected = status == ConnectionStatus.wifi || status == ConnectionStatus.mobile;
    final isWifi = status == ConnectionStatus.wifi;
    final isMobile = status == ConnectionStatus.mobile;
    
    String message;
    switch (status) {
      case ConnectionStatus.wifi:
        message = 'Connected to WiFi';
        break;
      case ConnectionStatus.mobile:
        message = 'Connected to Mobile Data';
        break;
      case ConnectionStatus.offline:
        message = 'No Internet Connection';
        break;
      case ConnectionStatus.unknown:
        message = 'Connection Status Unknown';
        break;
    }
    
    return ConnectivityStatus(
      status: status,
      isConnected: isConnected,
      isWifi: isWifi,
      isMobile: isMobile,
      message: message,
    );
  }
}