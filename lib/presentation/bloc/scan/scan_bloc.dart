// scan_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pwd_verification_app/core/utils/logger.dart';
import 'package:pwd_verification_app/data/repositories/scan_repository.dart';
import 'package:pwd_verification_app/presentation/bloc/scan/scan_event.dart';
import 'package:pwd_verification_app/presentation/bloc/scan/scan_state.dart';

class ScanBloc extends Bloc<ScanEvent, ScanState> {
  final ScanRepository _scanRepository;
  
  ScanBloc(this._scanRepository) : super(const ScanInitial()) {
    on<VerifyQRCode>(_onVerifyQRCode);
    on<ResetScan>(_onResetScan);
    on<LoadScanHistory>(_onLoadScanHistory);
  }
  
  Future<void> _onVerifyQRCode(
    VerifyQRCode event,
    Emitter<ScanState> emit,
  ) async {
    try {
      emit(const ScanInProgress());
      
      final scanResult = await _scanRepository.verifyQRCode(event.qrData);
      
      if (scanResult != null) {
        emit(ScanSuccess(scanResult));
      } else {
        emit(const ScanFailure('Failed to verify QR code. Please try again.'));
      }
    } catch (e) {
      AppLogger.error('ScanBloc', 'Error during QR code verification: $e');
      emit(const ScanFailure('An error occurred. Please try again.'));
    }
  }
  
  void _onResetScan(
    ResetScan event,
    Emitter<ScanState> emit,
  ) {
    emit(const ScanInitial());
  }
  
  Future<void> _onLoadScanHistory(
    LoadScanHistory event,
    Emitter<ScanState> emit,
  ) async {
    try {
      emit(const ScanInProgress());
      
      final scanHistory = await _scanRepository.getScanHistory();
      
      emit(ScanHistoryLoaded(scanHistory));
    } catch (e) {
      AppLogger.error('ScanBloc', 'Error loading scan history: $e');
      emit(const ScanFailure('Failed to load scan history. Please try again.'));
    }
  }
}