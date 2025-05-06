// scan_event.dart
import 'package:equatable/equatable.dart';

abstract class ScanEvent extends Equatable {
  const ScanEvent();
  
  @override
  List<Object?> get props => [];
}

class VerifyQRCode extends ScanEvent {
  final String qrData;
  
  const VerifyQRCode(this.qrData);
  
  @override
  List<Object?> get props => [qrData];
}

class ResetScan extends ScanEvent {
  const ResetScan();
}

class LoadScanHistory extends ScanEvent {
  const LoadScanHistory();
}