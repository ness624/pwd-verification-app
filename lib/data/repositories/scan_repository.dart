import 'dart:async';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import 'package:pwd_verification_app/core/api/api_client.dart'; // Keep for connectivity check for now
import 'package:pwd_verification_app/core/storage/secure_storage.dart';
import 'package:pwd_verification_app/core/utils/logger.dart';
import 'package:pwd_verification_app/data/models/pwd_info.dart';
import 'package:pwd_verification_app/data/models/scan_result.dart';
import 'package:pwd_verification_app/data/models/user.dart' as AppUser;
import 'package:pwd_verification_app/data/services/qr_service.dart';
import 'package:pwd_verification_app/data/repositories/auth_repository.dart';

class ScanRepository {
  final ApiClient _apiClient; // For connectivity check, can be replaced by ConnectivityService
  final QRService _qrService;
  final SecureStorage _secureStorage;
  final SupabaseClient _supabaseClient;
  final AuthRepository _authRepository;
  final Uuid _uuid = const Uuid();

  ScanRepository(
    this._apiClient,
    this._qrService,
    this._secureStorage,
    this._supabaseClient,
    this._authRepository,
  );

  Future<ScanResult?> verifyQRCode(String qrData) async {
    AppUser.User? currentUser = await _authRepository.getCurrentUser();
    String establishmentName = currentUser?.establishmentName ?? 'N/A Establishment';
    String? establishmentLocation = 'Default Location'; // TODO: Get actual location

    try {
      if (qrData.startsWith('MANUAL:')) {
         return _createPlaceholderManualScanResult(qrData.substring(7), establishmentName, establishmentLocation);
      }

      final pwdInfo = await _qrService.decryptQRData(qrData);
      if (pwdInfo == null) {
        AppLogger.warning('ScanRepository', 'Invalid QR code format or decryption failed.');
        // Create a ScanResult for logging purposes even if PWDInfo is minimal
        final invalidScan = ScanResult(
          scanId: _uuid.v4(), scanTime: DateTime.now(),
          pwdInfo: PWDInfo(id: 'UNKNOWN_PWD', fullName: 'N/A', pwdNumber: 'N/A', expiryDate: DateTime.now(), disabilityType: 'N/A'),
          isValid: false, invalidReason: 'Invalid QR code format or encryption',
          establishmentName: establishmentName, establishmentLocation: establishmentLocation,
          isSyncedWithServer: false,
        );
        await _saveScanResultLocally(invalidScan);
        _syncScanResultToServer(invalidScan); // Attempt to log this failure
        return invalidScan;
      }

      final bool isExpired = pwdInfo.isExpired;
      final bool isValid = !isExpired;
      String? invalidReason = isExpired ? 'PWD ID has expired on ${_formatDate(pwdInfo.expiryDate)}' : null;

      final scanResult = ScanResult(
        scanId: _uuid.v4(), scanTime: DateTime.now(),
        pwdInfo: pwdInfo, isValid: isValid, invalidReason: invalidReason,
        establishmentName: establishmentName, establishmentLocation: establishmentLocation,
        isSyncedWithServer: false,
      );

      await _saveScanResultLocally(scanResult);
      _syncScanResultToServer(scanResult);
      return scanResult;

    } catch (e) {
      AppLogger.error('ScanRepository', 'Error verifying QR code: $e');
      final errorScan = ScanResult(
        scanId: _uuid.v4(), scanTime: DateTime.now(),
        pwdInfo: PWDInfo(id: 'ERROR_PWD', fullName: 'N/A', pwdNumber: 'N/A', expiryDate: DateTime.now(), disabilityType: 'N/A'),
        isValid: false, invalidReason: 'Error during verification: ${e.toString()}',
        establishmentName: establishmentName, establishmentLocation: establishmentLocation,
        isSyncedWithServer: false,
      );
      await _saveScanResultLocally(errorScan);
      _syncScanResultToServer(errorScan); // Attempt to log this error
      return errorScan;
    }
  }

  Future<ScanResult> _createPlaceholderManualScanResult(String pwdId, String estName, String? estLoc) async {
     AppLogger.info('ScanRepository', 'Creating placeholder manual entry scan: $pwdId');
     final pwdInfoForManual = PWDInfo( id: 'MANUAL_ENTRY_NO_PWD_ID', fullName: 'Manual Entry Lookup', pwdNumber: pwdId, expiryDate: DateTime.now().add(const Duration(days: 30)), disabilityType: 'Manual Lookup' );
     final scanResult = ScanResult( scanId: _uuid.v4(), scanTime: DateTime.now(), pwdInfo: pwdInfoForManual, isValid: false, invalidReason: "Manual entry pending verification", establishmentName: estName, establishmentLocation: estLoc, isSyncedWithServer: false );
     await _saveScanResultLocally(scanResult);
     _syncScanResultToServer(scanResult);
     return scanResult;
  }

  Future<void> _saveScanResultLocally(ScanResult scanResult) async {
    try {
      final scanHistory = await _secureStorage.getScanHistory();
      scanHistory.add(scanResult);
      await _secureStorage.saveScanHistory(scanHistory);
      AppLogger.info('ScanRepository', 'Scan result ${scanResult.scanId} saved locally.');
      if (!scanResult.isSyncedWithServer) await _addToSyncQueue(scanResult);
    } catch (e) { AppLogger.error('ScanRepository', 'Error saving scan result locally: $e'); }
  }

  Future<void> _addToSyncQueue(ScanResult scanResult) async {
    try {
      final syncQueue = await _secureStorage.getSyncQueue();
      if (!syncQueue.any((s) => s.scanId == scanResult.scanId)) {
         syncQueue.add(scanResult);
         await _secureStorage.saveSyncQueue(syncQueue);
         AppLogger.info('ScanRepository', 'Scan ${scanResult.scanId} added to sync queue.');
      }
    } catch (e) { AppLogger.error('ScanRepository', 'Error adding to sync queue: $e'); }
  }

  Future<void> _syncScanResultToServer(ScanResult scanResult) async {
    AppUser.User? currentUser = await _authRepository.getCurrentUser();
    if (currentUser == null) {
      AppLogger.warning('ScanRepository', 'Cannot sync scan, no current user found.');
      await _addToSyncQueue(scanResult); // Ensure it's queued if user is somehow not available
      return;
    }

    try {
      final isConnected = await _apiClient.checkConnectivity(); // Replace with ConnectivityService later
      if (!isConnected) {
        AppLogger.info('ScanRepository', 'Device is offline. Scan ${scanResult.scanId} remains in queue.');
        await _addToSyncQueue(scanResult); // Ensure it's queued
        return;
      }

      AppLogger.info('ScanRepository', 'Attempting to sync scan result: ${scanResult.scanId}');

      // 1. Log to central `scan_logs`
      String centralScanLogId = _uuid.v4(); // Generate ID for the central log
      final Map<String, dynamic> scanLogData = {
        'id': centralScanLogId,
        'pwd_id': scanResult.pwdInfo.id, // Assuming pwdInfo.id is the UUID of the PWD record
        // 'qr_instance_uuid': null, // TODO: Where does this come from? (e.g., from PWDInfo)
        'scanned_by': currentUser.id, // This is the auth_id of the mobile user
        // 'device_id': null, // TODO: Get from device_info_plus
        // 'latitude': null, // TODO: Get from geolocator
        // 'longitude': null, // TODO: Get from geolocator
        'verification_status': scanResult.isValid ? 'valid' : (scanResult.invalidReason ?? 'invalid'),
        'created_at': scanResult.scanTime.toIso8601String(),
        // 'app_version': null, // TODO: Get from package_info_plus
        'scan_metadata': scanResult.invalidReason != null ? {'reason': scanResult.invalidReason} : null,
        // 'ip_address': null, // Typically captured server-side
        // 'user_agent': null, // TODO: Get from device_info_plus
        'establishment_id': currentUser.establishmentId, // This is mobile_users.id
        'mobile_user_id': currentUser.id, // This is mobile_users.auth_id
        // 'device_model': null, // TODO: Get from device_info_plus
      };

      await _supabaseClient.from('scan_logs').insert(scanLogData);
      AppLogger.info('ScanRepository', 'Scan logged to central scan_logs with ID: $centralScanLogId');

      // 2. Log to `mobile_user_scan_history`
      final Map<String, dynamic> mobileHistoryData = {
        // 'id' will be auto-generated by Supabase if it's a PK with default
        'mobile_user_id': currentUser.id, // auth_id
        'scan_log_id': centralScanLogId, // Link to the central log
        'pwd_id': scanResult.pwdInfo.id,
        'pwd_id_number': scanResult.pwdInfo.pwdNumber,
        'pwd_full_name': scanResult.pwdInfo.fullName,
        'verification_status': scanResult.isValid ? 'valid' : (scanResult.invalidReason ?? 'invalid'),
        'scanned_at': scanResult.scanTime.toIso8601String(),
        // 'latitude': null,
        // 'longitude': null,
        // 'location_name': scanResult.establishmentLocation, // Or derive from lat/long
        // 'device_id': null,
      };
      await _supabaseClient.from('mobile_user_scan_history').insert(mobileHistoryData);
      AppLogger.info('ScanRepository', 'Scan logged to mobile_user_scan_history.');

      // If both inserts are successful, mark as synced and update local storage
      final updatedScanResult = scanResult.copyWith(isSyncedWithServer: true);
      await _updateScanResultInLocalStorage(updatedScanResult);
      await _removeFromSyncQueue(scanResult.scanId);
      AppLogger.info('ScanRepository', 'Scan ${scanResult.scanId} successfully synced and updated locally.');

    } catch (e) {
      AppLogger.error('ScanRepository', 'Error syncing scan result ${scanResult.scanId}: $e');
      // Ensure it's (still) in the sync queue on any error during sync
      final notYetSyncedScan = scanResult.copyWith(isSyncedWithServer: false);
      await _saveScanResultLocally(notYetSyncedScan); // This will also add to queue if not synced
    }
  }

  Future<void> _removeFromSyncQueue(String scanId) async {
    try {
        final syncQueue = await _secureStorage.getSyncQueue();
        syncQueue.removeWhere((s) => s.scanId == scanId);
        await _secureStorage.saveSyncQueue(syncQueue);
        AppLogger.info('ScanRepository', 'Scan $scanId removed from sync queue.');
    } catch (e) {
        AppLogger.error('ScanRepository', 'Error removing scan $scanId from sync queue: $e');
    }
  }


  Future<void> _updateScanResultInLocalStorage(ScanResult updatedScanResult) async {
    try {
      final scanHistory = await _secureStorage.getScanHistory();
      final index = scanHistory.indexWhere((s) => s.scanId == updatedScanResult.scanId);
      if (index != -1) { scanHistory[index] = updatedScanResult; await _secureStorage.saveScanHistory(scanHistory); }
    } catch (e) { AppLogger.error('ScanRepository', 'Error updating scan result in local storage: $e'); }
  }

  Future<List<ScanResult>> getScanHistory() async {
    // This should now fetch from mobile_user_scan_history table for the current user
    AppUser.User? currentUser = await _authRepository.getCurrentUser();
    if (currentUser == null) {
        AppLogger.warning('ScanRepository', 'getScanHistory: No current user. Returning empty list.');
        return [];
    }

    try {
        AppLogger.info('ScanRepository', 'Fetching scan history for mobile_user_id: ${currentUser.id}');
        final response = await _supabaseClient
            .from('mobile_user_scan_history')
            .select()
            .eq('mobile_user_id', currentUser.id) // Filter by current mobile user's auth_id
            .order('scanned_at', ascending: false); // Get most recent first

        final List<ScanResult> history = response.map<ScanResult>((item) {
            // Map Supabase row data back to ScanResult model
            // This mapping needs to be precise.
            return ScanResult(
                scanId: item['id'], // Assuming 'id' from mobile_user_scan_history is the scanId for the app
                scanTime: DateTime.parse(item['scanned_at']),
                pwdInfo: PWDInfo(
                    id: item['pwd_id'] ?? 'N/A',
                    pwdNumber: item['pwd_id_number'] ?? 'N/A',
                    fullName: item['pwd_full_name'] ?? 'N/A',
                    // These might not be in mobile_user_scan_history, set defaults or fetch if needed
                    expiryDate: DateTime.now(), // Placeholder
                    disabilityType: 'N/A', // Placeholder
                ),
                isValid: item['verification_status'] == 'valid',
                invalidReason: item['verification_status'] != 'valid' ? item['verification_status'] : null,
                establishmentName: currentUser.establishmentName, // From logged-in user
                establishmentLocation: "Default Location", // TODO: get from user or device
                isSyncedWithServer: true, // Data from server is considered synced
            );
        }).toList();
        AppLogger.info('ScanRepository', 'Fetched ${history.length} items from mobile_user_scan_history.');
        return history;

    } catch (e) {
      AppLogger.error('ScanRepository', 'Error getting scan history from Supabase: $e');
      // Fallback to local storage if server fetch fails? Or just return empty?
      // For now, let's return local history as a fallback.
      // This behavior can be refined.
      AppLogger.info('ScanRepository', 'Falling back to local scan history.');
      final localHistory = await _secureStorage.getScanHistory();
      return localHistory.reversed.toList();
    }
  }


  Future<String> _getEstablishmentName() async {
    final currentUser = await _authRepository.getCurrentUser();
    return currentUser?.establishmentName ?? 'Demo Establishment';
  }

  Future<String?> _getEstablishmentLocation() async {
    final currentUser = await _authRepository.getCurrentUser();
    // return currentUser?.establishmentLocation; // If user model has this
    return 'Manila, Philippines'; // Placeholder
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  Future<bool> syncPendingScans() async {
    final isConnected = await _apiClient.checkConnectivity(); // Or use ConnectivityService
    if (!isConnected) { AppLogger.info('ScanRepository', 'SyncPendingScans: Device offline.'); return false; }

    final syncQueue = await _secureStorage.getSyncQueue();
    if (syncQueue.isEmpty) { AppLogger.info('ScanRepository', 'SyncPendingScans: Sync queue is empty.'); return true; }

    AppLogger.info('ScanRepository', 'SyncPendingScans: Attempting to sync ${syncQueue.length} items.');
    List<ScanResult> successfullySyncedItems = [];
    bool oneSyncFailed = false;

    for (final scanToSync in List<ScanResult>.from(syncQueue)) { // Iterate over a copy
      try {
        await _syncScanResultToServer(scanToSync); // This now handles both inserts
        // If _syncScanResultToServer doesn't throw, we assume it updated the item's isSyncedWithServer flag
        // and removed it from queue if successful.
        // For robustness, we can re-check from storage or assume success leads to removal.
        // Let's assume if it doesn't throw, it was handled.
        // The _syncScanResultToServer method should remove from queue on success.
        // For simplicity, here we'll just check if it's still in the refetched queue.
      } catch (e) {
        AppLogger.error('ScanRepository', 'SyncPendingScans: Error syncing item ${scanToSync.scanId} during batch sync: $e');
        oneSyncFailed = true;
      }
    }
    // After attempting all, refetch queue to see what's left
    final remainingQueue = await _secureStorage.getSyncQueue();
    if (remainingQueue.isEmpty && !oneSyncFailed) {
        AppLogger.info('ScanRepository', 'SyncPendingScans: All items processed successfully.');
        return true;
    } else {
        AppLogger.warning('ScanRepository', 'SyncPendingScans: ${remainingQueue.length} items remain in queue or some errors occurred.');
        return false;
    }
  }

  Future<int> getUnsyncedCount() async {
    try { final syncQueue = await _secureStorage.getSyncQueue(); return syncQueue.length; }
    catch (e) { AppLogger.error('ScanRepository', 'Error getting unsynced count: $e'); return 0; }
  }

  Future<bool> clearScanHistory() async {
    AppUser.User? currentUser = await _authRepository.getCurrentUser();
    if (currentUser == null) {
        AppLogger.warning('ScanRepository', 'clearScanHistory: No current user. Cannot clear server history.');
        // Clear local only
        await _secureStorage.saveScanHistory([]);
        await _secureStorage.saveSyncQueue([]);
        AppLogger.info('ScanRepository', 'Local scan history and sync queue cleared (no user for server clear).');
        return true;
    }
    try {
      // Clear server-side history for this user
      await _supabaseClient
        .from('mobile_user_scan_history')
        .delete()
        .eq('mobile_user_id', currentUser.id);
      AppLogger.info('ScanRepository', 'Server-side mobile_user_scan_history cleared for user ${currentUser.id}.');

      // Clear local history and queue
      await _secureStorage.saveScanHistory([]);
      await _secureStorage.saveSyncQueue([]);
      AppLogger.info('ScanRepository', 'Local scan history and sync queue cleared.');
      return true;
    } catch (e) {
      AppLogger.error('ScanRepository', 'Error clearing scan history (server or local): $e');
      // Attempt to clear local anyway if server fails
      try {
        await _secureStorage.saveScanHistory([]);
        await _secureStorage.saveSyncQueue([]);
      } catch (localClearError) {
        AppLogger.error('ScanRepository', 'Error clearing local scan history during fallback: $localClearError');
      }
      return false;
    }
  }
}