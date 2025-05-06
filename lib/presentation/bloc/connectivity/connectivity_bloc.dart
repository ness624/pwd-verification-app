// connectivity_bloc.dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pwd_verification_app/core/services/connectivity_service.dart';
import 'package:pwd_verification_app/core/utils/logger.dart';
import 'package:pwd_verification_app/presentation/bloc/connectivity/connectivity_event.dart';
import 'package:pwd_verification_app/presentation/bloc/connectivity/connectivity_state.dart';

class ConnectivityBloc extends Bloc<ConnectivityEvent, ConnectivityState> {
  final ConnectivityService _connectivityService;
  StreamSubscription<ConnectionStatus>? _connectivitySubscription;
  
  ConnectivityBloc(this._connectivityService) : super(ConnectivityInitial()) {
    on<ConnectivityStatusChanged>(_onStatusChanged);
    on<ConnectivityStartMonitoring>(_onStartMonitoring);
    on<ConnectivityStopMonitoring>(_onStopMonitoring);
  }
  
  void _onStatusChanged(
    ConnectivityStatusChanged event,
    Emitter<ConnectivityState> emit,
  ) {
    AppLogger.info('ConnectivityBloc', 'Connection status changed: ${event.status}');
    emit(ConnectivityStatus.fromConnectionStatus(event.status));
  }
  
  void _onStartMonitoring(
    ConnectivityStartMonitoring event,
    Emitter<ConnectivityState> emit,
  ) {
    AppLogger.info('ConnectivityBloc', 'Starting connectivity monitoring');
    
    // Initialize connectivity service if not already initialized
    _connectivityService.initialize();
    
    // Subscribe to connectivity changes
    _connectivitySubscription?.cancel();
    _connectivitySubscription = _connectivityService.connectionStatusStream.listen(
      (status) => add(ConnectivityStatusChanged(status)),
    );
    
    // Emit initial status
    final initialStatus = _connectivityService.currentStatus;
    emit(ConnectivityStatus.fromConnectionStatus(initialStatus));
  }
  
  void _onStopMonitoring(
    ConnectivityStopMonitoring event,
    Emitter<ConnectivityState> emit,
  ) {
    AppLogger.info('ConnectivityBloc', 'Stopping connectivity monitoring');
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }
  
  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    return super.close();
  }
}