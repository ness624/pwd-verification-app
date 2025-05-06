// scan_result.dart
import 'package:pwd_verification_app/data/models/pwd_info.dart';

class ScanResult {
  final String scanId;
  final DateTime scanTime;
  final PWDInfo pwdInfo;
  final bool isValid;
  final String? invalidReason;
  final String establishmentName;
  final String? establishmentLocation;
  final bool isSyncedWithServer;
  
  const ScanResult({
    required this.scanId,
    required this.scanTime,
    required this.pwdInfo,
    required this.isValid,
    this.invalidReason,
    required this.establishmentName,
    this.establishmentLocation,
    this.isSyncedWithServer = false,
  });
  
  factory ScanResult.fromJson(Map<String, dynamic> json) {
    return ScanResult(
      scanId: json['scanId'],
      scanTime: DateTime.parse(json['scanTime']),
      pwdInfo: PWDInfo.fromJson(json['pwdInfo']),
      isValid: json['isValid'],
      invalidReason: json['invalidReason'],
      establishmentName: json['establishmentName'],
      establishmentLocation: json['establishmentLocation'],
      isSyncedWithServer: json['isSyncedWithServer'] ?? false,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'scanId': scanId,
      'scanTime': scanTime.toIso8601String(),
      'pwdInfo': pwdInfo.toJson(),
      'isValid': isValid,
      'invalidReason': invalidReason,
      'establishmentName': establishmentName,
      'establishmentLocation': establishmentLocation,
      'isSyncedWithServer': isSyncedWithServer,
    };
  }
}