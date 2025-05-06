// connectivity_event.dart
import 'package:equatable/equatable.dart';
import 'package:pwd_verification_app/core/services/connectivity_service.dart';

abstract class ConnectivityEvent extends Equatable {
  const ConnectivityEvent();
  
  @override
  List<Object?> get props => [];
}

class ConnectivityStatusChanged extends ConnectivityEvent {
  final ConnectionStatus status;
  
  const ConnectivityStatusChanged(this.status);
  
  @override
  List<Object?> get props => [status];
}

class ConnectivityStartMonitoring extends ConnectivityEvent {}

class ConnectivityStopMonitoring extends ConnectivityEvent {}