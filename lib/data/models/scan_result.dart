import 'package:equatable/equatable.dart'; // Import Equatable
import 'package:pwd_verification_app/data/models/pwd_info.dart';

// Make ScanResult extend Equatable for easier comparison and if used in BLoC states
class ScanResult extends Equatable {
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
      scanId: json['scanId'] as String, // Added explicit cast
      scanTime: DateTime.parse(json['scanTime'] as String), // Added explicit cast
      pwdInfo: PWDInfo.fromJson(json['pwdInfo'] as Map<String, dynamic>), // Added explicit cast
      isValid: json['isValid'] as bool, // Added explicit cast
      invalidReason: json['invalidReason'] as String?,
      establishmentName: json['establishmentName'] as String, // Added explicit cast
      establishmentLocation: json['establishmentLocation'] as String?,
      isSyncedWithServer: json['isSyncedWithServer'] as bool? ?? false, // Added explicit cast
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

  // --- ADDED copyWith METHOD ---
  ScanResult copyWith({
    String? scanId,
    DateTime? scanTime,
    PWDInfo? pwdInfo,
    bool? isValid,
    String? invalidReason,
    // Allow explicitly setting invalidReason to null
    bool setInvalidReasonToNull = false,
    String? establishmentName,
    String? establishmentLocation,
    // Allow explicitly setting establishmentLocation to null
    bool setEstablishmentLocationToNull = false,
    bool? isSyncedWithServer,
  }) {
    return ScanResult(
      scanId: scanId ?? this.scanId,
      scanTime: scanTime ?? this.scanTime,
      pwdInfo: pwdInfo ?? this.pwdInfo,
      isValid: isValid ?? this.isValid,
      invalidReason: setInvalidReasonToNull ? null : (invalidReason ?? this.invalidReason),
      establishmentName: establishmentName ?? this.establishmentName,
      establishmentLocation: setEstablishmentLocationToNull ? null : (establishmentLocation ?? this.establishmentLocation),
      isSyncedWithServer: isSyncedWithServer ?? this.isSyncedWithServer,
    );
  }

  // --- ADDED Equatable props ---
  @override
  List<Object?> get props => [
        scanId,
        scanTime,
        pwdInfo,
        isValid,
        invalidReason,
        establishmentName,
        establishmentLocation,
        isSyncedWithServer,
      ];
}