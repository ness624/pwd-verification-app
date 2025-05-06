// scan_state.dart
import 'package:equatable/equatable.dart';
import 'package:pwd_verification_app/data/models/scan_result.dart';

abstract class ScanState extends Equatable {
  const ScanState();
  
  @override
  List<Object?> get props => [];
}

class ScanInitial extends ScanState {
  const ScanInitial();
}

class ScanInProgress extends ScanState {
  const ScanInProgress();
}

class ScanSuccess extends ScanState {
  final ScanResult scanResult;
  
  const ScanSuccess(this.scanResult);
  
  @override
  List<Object?> get props => [scanResult];
}

class ScanFailure extends ScanState {
  final String message;
  
  const ScanFailure(this.message);
  
  @override
  List<Object?> get props => [message];
}

class ScanHistoryLoaded extends ScanState {
  final List<ScanResult> scanHistory;
  
  const ScanHistoryLoaded(this.scanHistory);
  
  @override
  List<Object?> get props => [scanHistory];
}