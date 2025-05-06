// secure_storage.dart
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pwd_verification_app/core/utils/logger.dart';
import 'package:pwd_verification_app/data/models/scan_result.dart';
import 'package:pwd_verification_app/data/models/user.dart';

class SecureStorage {
  static const String _userKey = 'current_user';
  static const String _scanHistoryKey = 'scan_history';
  static const String _syncQueueKey = 'sync_queue';
  static const String _establishmentLocationKey = 'establishment_location';
  
  final FlutterSecureStorage _storage;
  
  SecureStorage(this._storage);
  
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      AppLogger.error('SecureStorage', 'Error reading from secure storage: $e');
      return null;
    }
  }
  
  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      AppLogger.error('SecureStorage', 'Error writing to secure storage: $e');
    }
  }
  
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      AppLogger.error('SecureStorage', 'Error deleting from secure storage: $e');
    }
  }
  
  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      AppLogger.error('SecureStorage', 'Error deleting all from secure storage: $e');
    }
  }
  
  // Added methods for ScanRepository
  Future<User?> getUser() async {
    try {
      final userJson = await read(_userKey);
      if (userJson != null) {
        return User.fromJson(jsonDecode(userJson));
      }
      return null;
    } catch (e) {
      AppLogger.error('SecureStorage', 'Error getting user: $e');
      return null;
    }
  }
  
  Future<String?> getEstablishmentLocation() async {
    try {
      return await read(_establishmentLocationKey);
    } catch (e) {
      AppLogger.error('SecureStorage', 'Error getting establishment location: $e');
      return null;
    }
  }
  
  Future<List<ScanResult>> getScanHistory() async {
    try {
      final json = await read(_scanHistoryKey);
      if (json == null) {
        return [];
      }
      
      final List<dynamic> scanList = jsonDecode(json);
      return scanList.map((item) => ScanResult.fromJson(item)).toList();
    } catch (e) {
      AppLogger.error('SecureStorage', 'Error getting scan history: $e');
      return [];
    }
  }
  
  Future<void> saveScanHistory(List<ScanResult> scanHistory) async {
    try {
      final List<Map<String, dynamic>> jsonList = scanHistory
          .map((scan) => scan.toJson())
          .toList();
      
      await write(_scanHistoryKey, jsonEncode(jsonList));
    } catch (e) {
      AppLogger.error('SecureStorage', 'Error saving scan history: $e');
    }
  }
  
  Future<List<ScanResult>> getSyncQueue() async {
    try {
      final json = await read(_syncQueueKey);
      if (json == null) {
        return [];
      }
      
      final List<dynamic> syncList = jsonDecode(json);
      return syncList.map((item) => ScanResult.fromJson(item)).toList();
    } catch (e) {
      AppLogger.error('SecureStorage', 'Error getting sync queue: $e');
      return [];
    }
  }
  
  Future<void> saveSyncQueue(List<ScanResult> syncQueue) async {
    try {
      final List<Map<String, dynamic>> jsonList = syncQueue
          .map((scan) => scan.toJson())
          .toList();
      
      await write(_syncQueueKey, jsonEncode(jsonList));
    } catch (e) {
      AppLogger.error('SecureStorage', 'Error saving sync queue: $e');
    }
  }
}