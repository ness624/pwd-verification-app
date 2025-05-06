import 'dart:async';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:pwd_verification_app/core/api/api_client.dart';
import 'package:pwd_verification_app/core/storage/secure_storage.dart';
import 'package:pwd_verification_app/core/utils/logger.dart';
import 'package:pwd_verification_app/data/models/pwd_info.dart';
import 'package:pwd_verification_app/data/models/scan_result.dart';
import 'package:pwd_verification_app/data/models/user.dart';
import 'package:pwd_verification_app/data/services/qr_service.dart';
import 'package:pwd_verification_app/core/services/mock_data_service.dart';

class ScanRepository {
  final ApiClient _apiClient;
  final QRService _qrService;
  final SecureStorage _secureStorage;
  final MockDataService _mockDataService;
  final Uuid _uuid = const Uuid();
  
  ScanRepository(this._apiClient, this._qrService, this._secureStorage) 
      : _mockDataService = MockDataService();
  
  Future<ScanResult?> verifyQRCode(String qrData) async {
    try {
      // Check if it's a manual entry
      if (qrData.startsWith('MANUAL:')) {
        return _handleManualEntry(qrData.substring(7));
      }
      
      // Regular QR code scan processing
      final pwdInfo = await _qrService.decryptQRData(qrData);
      if (pwdInfo == null) {
        return ScanResult(
          scanId: _uuid.v4(),
          scanTime: DateTime.now(),
          pwdInfo: PWDInfo(
            id: '',
            fullName: '',
            pwdNumber: '',
            expiryDate: DateTime.now(),
            disabilityType: '',
          ),
          isValid: false,
          invalidReason: 'Invalid QR code format or encryption',
          establishmentName: await _getEstablishmentName(),
          establishmentLocation: await _getEstablishmentLocation(),
        );
      }
      
      // Step 2: Validate the PWD info (e.g., check expiry date)
      final bool isExpired = pwdInfo.isExpired;
      final bool isValid = !isExpired;
      String? invalidReason;
      
      if (isExpired) {
        invalidReason = 'PWD ID has expired on ${_formatDate(pwdInfo.expiryDate)}';
      }
      
      // Step 3: Create scan result
      final scanResult = ScanResult(
        scanId: _uuid.v4(),
        scanTime: DateTime.now(),
        pwdInfo: pwdInfo,
        isValid: isValid,
        invalidReason: invalidReason,
        establishmentName: await _getEstablishmentName(),
        establishmentLocation: await _getEstablishmentLocation(),
      );
      
      // Step 4: Save scan result locally
      await _saveScanResult(scanResult);
      
      // Step 5: Send scan result to server (if online)
      _syncScanResult(scanResult);
      
      return scanResult;
    } catch (e) {
      AppLogger.error('ScanRepository', 'Error verifying QR code: $e');
      return null;
    }
  }
  
  Future<ScanResult> _handleManualEntry(String pwdId) async {
    AppLogger.info('ScanRepository', 'Processing manual entry: $pwdId');
    
    // In a real app, we would call a special API endpoint to verify the PWD ID
    // For now, we'll use the mock service to generate a PWD info for testing
    
    // Simulating network call delay
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // Create a PWD info with the entered ID
    // 70% chance of being valid
    final isValid = MockDataService().generateRandomScanResult(
      isValid: _getRandomValidityForManualEntry(pwdId),
    );
    
    // Make sure the PWD ID is set to the manually entered value
    final updatedPwdInfo = PWDInfo(
      id: isValid.pwdInfo.id,
      fullName: isValid.pwdInfo.fullName,
      pwdNumber: pwdId, // Use the manually entered ID
      expiryDate: isValid.pwdInfo.expiryDate,
      disabilityType: isValid.pwdInfo.disabilityType,
      address: isValid.pwdInfo.address,
      contactNumber: isValid.pwdInfo.contactNumber,
    );
    
    // Create the scan result
    final scanResult = ScanResult(
      scanId: _uuid.v4(),
      scanTime: DateTime.now(),
      pwdInfo: updatedPwdInfo,
      isValid: isValid.isValid,
      invalidReason: isValid.invalidReason,
      establishmentName: await _getEstablishmentName(),
      establishmentLocation: await _getEstablishmentLocation(),
      isSyncedWithServer: false, // Manual entries need sync
    );
    
    // Save the scan result
    await _saveScanResult(scanResult);
    
    return scanResult;
  }
  
  // Helper function to determine if a manual entry should be valid or not
  // In a real app, this would be based on server verification
  bool _getRandomValidityForManualEntry(String pwdId) {
    // For consistent results based on the PWD ID
    final random = DateTime.now().microsecondsSinceEpoch % 10;
    
    // 70% chance of being valid
    return random < 7;
  }
  
  Future<void> _saveScanResult(ScanResult scanResult) async {
    try {
      // Get existing scan history from the secure storage
      final scanHistory = await _secureStorage.getScanHistory();
      
      // Add new scan result
      scanHistory.add(scanResult);
      
      // Limit history to last 100 scans
      if (scanHistory.length > 100) {
        scanHistory.removeRange(0, scanHistory.length - 100);
      }
      
      // Save back to storage
      await _secureStorage.saveScanHistory(scanHistory);
      
      // If scan is not valid, also add to sync queue
      if (!scanResult.isSyncedWithServer) {
        await _addToSyncQueue(scanResult);
      }
    } catch (e) {
      AppLogger.error('ScanRepository', 'Error saving scan result: $e');
    }
  }
  
  Future<void> _addToSyncQueue(ScanResult scanResult) async {
    try {
      final syncQueue = await _secureStorage.getSyncQueue();
      syncQueue.add(scanResult);
      await _secureStorage.saveSyncQueue(syncQueue);
    } catch (e) {
      AppLogger.error('ScanRepository', 'Error adding to sync queue: $e');
    }
  }
  
  Future<void> _syncScanResult(ScanResult scanResult) async {
    try {
      // Check if device is connected to the internet
      final isConnected = await _apiClient.checkConnectivity();
      
      if (!isConnected) {
        AppLogger.info('ScanRepository', 'Device is offline, scan result will be synced later');
        return;
      }
      
      // Send scan result to server
      final success = await _apiClient.sendScanResult(scanResult);
      
      if (success) {
        // Update local record as synced
        final updatedScanResult = ScanResult(
          scanId: scanResult.scanId,
          scanTime: scanResult.scanTime,
          pwdInfo: scanResult.pwdInfo,
          isValid: scanResult.isValid,
          invalidReason: scanResult.invalidReason,
          establishmentName: scanResult.establishmentName,
          establishmentLocation: scanResult.establishmentLocation,
          isSyncedWithServer: true,
        );
        
        await _updateScanResultInStorage(updatedScanResult);
      }
    } catch (e) {
      AppLogger.error('ScanRepository', 'Error syncing scan result: $e');
      // We don't throw the error - just log it and continue
      // The scan will be marked as not synced, and can be synced later
    }
  }
  
  Future<void> _updateScanResultInStorage(ScanResult updatedScanResult) async {
    try {
      final scanHistory = await _secureStorage.getScanHistory();
      
      for (int i = 0; i < scanHistory.length; i++) {
        if (scanHistory[i].scanId == updatedScanResult.scanId) {
          scanHistory[i] = updatedScanResult;
          break;
        }
      }
      
      await _secureStorage.saveScanHistory(scanHistory);
    } catch (e) {
      AppLogger.error('ScanRepository', 'Error updating scan result: $e');
    }
  }
  
  Future<List<ScanResult>> getScanHistory() async {
    try {
      // For demonstration, sometimes use mock data if the real history is empty
      final scanHistory = await _secureStorage.getScanHistory();
      
      if (scanHistory.isEmpty) {
        // Return mock data for testing
        return _mockDataService.generateRandomScanHistory(count: 15);
      }
      
      return scanHistory.reversed.toList();
    } catch (e) {
      AppLogger.error('ScanRepository', 'Error getting scan history: $e');
      return [];
    }
  }
  
  Future<String> _getEstablishmentName() async {
    try {
      final user = await _secureStorage.getUser();
      if (user != null) {
        return user.establishmentName;
      }
      return 'Demo Establishment';
    } catch (e) {
      return 'Demo Establishment';
    }
  }
  
  Future<String?> _getEstablishmentLocation() async {
    try {
      return await _secureStorage.getEstablishmentLocation() ?? 'Manila, Philippines';
    } catch (e) {
      return 'Manila, Philippines';
    }
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  Future<bool> syncPendingScans() async {
    try {
      // Check connectivity
      final isConnected = await _apiClient.checkConnectivity();
      
      if (!isConnected) {
        return false;
      }
      
      // Get sync queue
      final syncQueue = await _secureStorage.getSyncQueue();
      
      if (syncQueue.isEmpty) {
        return true;
      }
      
      // Try to sync each scan
      bool allSynced = true;
      final synced = <ScanResult>[];
      
      for (final scan in syncQueue) {
        // Skip already synced scans
        if (scan.isSyncedWithServer) {
          synced.add(scan);
          continue;
        }
        
        // Try to sync
        final success = await _apiClient.sendScanResult(scan);
        
        if (success) {
          // Update scan as synced
          final updatedScan = ScanResult(
            scanId: scan.scanId,
            scanTime: scan.scanTime,
            pwdInfo: scan.pwdInfo,
            isValid: scan.isValid,
            invalidReason: scan.invalidReason,
            establishmentName: scan.establishmentName,
            establishmentLocation: scan.establishmentLocation,
            isSyncedWithServer: true,
          );
          
          // Update in scan history
          await _updateScanResultInStorage(updatedScan);
          
          // Add to synced list
          synced.add(updatedScan);
        } else {
          allSynced = false;
        }
      }
      
      // Remove synced scans from queue
      if (synced.isNotEmpty) {
        final newQueue = syncQueue
            .where((scan) => !synced.any((s) => s.scanId == scan.scanId))
            .toList();
        
        await _secureStorage.saveSyncQueue(newQueue);
      }
      
      return allSynced;
    } catch (e) {
      AppLogger.error('ScanRepository', 'Error syncing pending scans: $e');
      return false;
    }
  }
  
  // Method to get count of unsynced scans
  Future<int> getUnsyncedCount() async {
    try {
      final syncQueue = await _secureStorage.getSyncQueue();
      return syncQueue.length;
    } catch (e) {
      AppLogger.error('ScanRepository', 'Error getting unsynced count: $e');
      return 0;
    }
  }
  
  // Method for bulk operations on scan history
  Future<bool> clearScanHistory() async {
    try {
      await _secureStorage.saveScanHistory([]);
      return true;
    } catch (e) {
      AppLogger.error('ScanRepository', 'Error clearing scan history: $e');
      return false;
    }
  }
}