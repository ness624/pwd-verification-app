// qr_service.dart
import 'dart:convert';
import 'package:encrypt/encrypt.dart';
import 'package:pwd_verification_app/core/encryption/security_utils.dart';
import 'package:pwd_verification_app/core/utils/logger.dart';
import 'package:pwd_verification_app/data/models/pwd_info.dart';

class QRService {
  final SecurityUtils _securityUtils;
  
  QRService(this._securityUtils);
  
  Future<PWDInfo?> decryptQRData(String encryptedData) async {
    try {
      // Decode the base64 data first
      final base64Data = encryptedData.trim();
      final decodedData = base64Decode(base64Data);
      final dataString = utf8.decode(decodedData);
      
      // Extract IV and encrypted content
      final parts = dataString.split(':');
      if (parts.length != 2) {
        AppLogger.error('QRService', 'Invalid encrypted data format');
        return null;
      }
      
      final ivString = parts[0];
      final encryptedContent = parts[1];
      
      // Decrypt the content
      final iv = IV.fromBase64(ivString);
      final decryptedJson = await _securityUtils.decrypt(encryptedContent, iv);
      
      if (decryptedJson == null) {
        AppLogger.error('QRService', 'Failed to decrypt QR data');
        return null;
      }
      
      // Parse the decrypted JSON
      final Map<String, dynamic> jsonData = jsonDecode(decryptedJson);
      return PWDInfo.fromJson(jsonData);
    } catch (e) {
      AppLogger.error('QRService', 'Error decrypting QR data: $e');
      return null;
    }
  }
  
  Future<String?> encryptPWDInfo(PWDInfo pwdInfo) async {
    try {
      // Convert PWD info to JSON
      final jsonString = jsonEncode(pwdInfo.toJson());
      
      // Generate IV
      final iv = _securityUtils.generateIV();
      
      // Encrypt the JSON
      final encryptedContent = _securityUtils.encryptSync(jsonString, iv);
      
      // Combine IV and encrypted content
      final combined = '${iv.base64}:$encryptedContent';
      
      // Base64 encode the entire result
      return base64Encode(utf8.encode(combined));
    } catch (e) {
      AppLogger.error('QRService', 'Error encrypting PWD info: $e');
      return null;
    }
  }
}