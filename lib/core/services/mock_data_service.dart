import 'dart:math';
import 'package:pwd_verification_app/data/models/pwd_info.dart';
import 'package:pwd_verification_app/data/models/scan_result.dart';
import 'package:pwd_verification_app/core/utils/logger.dart';

/// A service that provides mock data for testing purposes.
/// This eliminates the need for a backend during development.
class MockDataService {
  final Random _random = Random();
  
  // Lists of sample data
  final List<String> _firstNames = [
    'Juan', 'Maria', 'Pedro', 'Ana', 'Jose', 'Sofia', 'Miguel', 'Gabriela',
    'Ricardo', 'Camila', 'Luis', 'Isabella', 'Antonio', 'Elena', 'Carlos'
  ];
  
  final List<String> _lastNames = [
    'Garcia', 'Santos', 'Reyes', 'Lim', 'Cruz', 'Gonzales', 'Bautista', 'Ramos',
    'Aquino', 'Pascual', 'Mendoza', 'Torres', 'Rivera', 'Diaz', 'Villanueva'
  ];
  
  final List<String> _disabilityTypes = [
    'Visual', 'Hearing', 'Physical', 'Intellectual', 'Psychosocial',
    'Multiple', 'Learning', 'Chronic Illness', 'Speech'
  ];
  
  final List<String> _addresses = [
    '123 Main St, Quezon City',
    '456 Elm St, Manila',
    '789 Oak St, Makati',
    '234 Pine St, Pasig',
    '567 Maple St, Taguig',
    '890 Cedar St, Parañaque',
    '345 Walnut St, Pasay',
    '678 Birch St, Caloocan',
    '901 Spruce St, Las Piñas',
    '432 Ash St, Muntinlupa'
  ];
  
  final List<String> _phoneNumbers = [
    '09171234567', '09182345678', '09193456789', '09204567890',
    '09215678901', '09226789012', '09237890123', '09248901234',
    '09259012345', '09269123456'
  ];
  
  final List<String> _establishments = [
    'SM Megamall', 'Robinsons Galleria', 'Ayala Malls Manila Bay',
    'Gateway Mall', 'Shangri-La Plaza', 'Glorietta', 'The Podium',
    'Festival Mall', 'Alabang Town Center', 'Greenbelt'
  ];
  
  /// Generate a random PWD ID string
  String _generatePwdId() {
    final year = 2021 + _random.nextInt(4);
    final region = _random.nextInt(17) + 1;
    final series = 10000 + _random.nextInt(90000);
    
    return 'PWD-$year-$region-$series';
  }
  
  /// Generate a random date within a range
  DateTime _generateRandomDate({
    required DateTime start,
    required DateTime end,
  }) {
    return start.add(Duration(
      days: _random.nextInt(end.difference(start).inDays),
    ));
  }
  
  /// Generate a random PWD information object
  PWDInfo generateRandomPwdInfo({bool? isExpired}) {
    final fullName = '${_firstNames[_random.nextInt(_firstNames.length)]} ${_lastNames[_random.nextInt(_lastNames.length)]}';
    final pwdNumber = _generatePwdId();
    
    // Generate expiry date based on isExpired parameter
    final now = DateTime.now();
    late DateTime expiryDate;
    
    if (isExpired == true) {
      // Generate an expired date (between 2 years ago and yesterday)
      expiryDate = _generateRandomDate(
        start: now.subtract(const Duration(days: 730)),
        end: now.subtract(const Duration(days: 1)),
      );
    } else if (isExpired == false) {
      // Generate a valid date (between tomorrow and 2 years from now)
      expiryDate = _generateRandomDate(
        start: now.add(const Duration(days: 1)),
        end: now.add(const Duration(days: 730)),
      );
    } else {
      // Random (80% valid, 20% expired)
      if (_random.nextDouble() < 0.8) {
        expiryDate = _generateRandomDate(
          start: now.add(const Duration(days: 1)),
          end: now.add(const Duration(days: 730)),
        );
      } else {
        expiryDate = _generateRandomDate(
          start: now.subtract(const Duration(days: 730)),
          end: now.subtract(const Duration(days: 1)),
        );
      }
    }
    
    return PWDInfo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fullName: fullName,
      pwdNumber: pwdNumber,
      expiryDate: expiryDate,
      disabilityType: _disabilityTypes[_random.nextInt(_disabilityTypes.length)],
      address: _random.nextBool() ? _addresses[_random.nextInt(_addresses.length)] : null,
      contactNumber: _random.nextBool() ? _phoneNumbers[_random.nextInt(_phoneNumbers.length)] : null,
    );
  }
  
  /// Generate a random scan result
  ScanResult generateRandomScanResult({bool? isValid, bool? isSynced}) {
    // Determine validity
    final shouldBeValid = isValid ?? (_random.nextDouble() < 0.8); // 80% valid by default
    
    // Generate PWD info
    final pwdInfo = generateRandomPwdInfo(isExpired: !shouldBeValid);
    
    // Generate scan time (between 7 days ago and now)
    final now = DateTime.now();
    final scanTime = _generateRandomDate(
      start: now.subtract(const Duration(days: 7)),
      end: now,
    );
    
    // Determine if synced
    final synced = isSynced ?? (_random.nextDouble() < 0.7); // 70% synced by default
    
    // Generate reason if invalid
    String? invalidReason;
    if (!shouldBeValid) {
      if (pwdInfo.isExpired) {
        invalidReason = 'PWD ID has expired on ${pwdInfo.expiryDate.day}/${pwdInfo.expiryDate.month}/${pwdInfo.expiryDate.year}';
      } else {
        final reasons = [
          'QR code data is corrupted',
          'Invalid QR code format',
          'PWD ID has been revoked',
          'Verification failed - cannot confirm authenticity'
        ];
        invalidReason = reasons[_random.nextInt(reasons.length)];
      }
    }
    
    return ScanResult(
      scanId: 'scan-${DateTime.now().millisecondsSinceEpoch}-${_random.nextInt(1000)}',
      scanTime: scanTime,
      pwdInfo: pwdInfo,
      isValid: shouldBeValid,
      invalidReason: invalidReason,
      establishmentName: _establishments[_random.nextInt(_establishments.length)],
      establishmentLocation: _random.nextBool() ? 'Manila, Philippines' : null,
      isSyncedWithServer: synced,
    );
  }
  
  /// Generate a list of random scan results
  List<ScanResult> generateRandomScanHistory({int count = 20}) {
    AppLogger.info('MockDataService', 'Generating $count random scan results');
    
    List<ScanResult> results = [];
    for (int i = 0; i < count; i++) {
      results.add(generateRandomScanResult());
    }
    
    // Sort by scan time (newest first)
    results.sort((a, b) => b.scanTime.compareTo(a.scanTime));
    
    return results;
  }
  
  /// Generate a fake verification response that simulates network latency
  Future<ScanResult> fakeVerifyQrCode(String qrData) async {
    AppLogger.info('MockDataService', 'Fake QR verification: $qrData');
    
    // Simulate network delay
    await Future.delayed(Duration(milliseconds: 800 + _random.nextInt(1200)));
    
    // 80% chance of success
    if (_random.nextDouble() < 0.8) {
      return generateRandomScanResult(isValid: true, isSynced: true);
    } else {
      return generateRandomScanResult(isValid: false, isSynced: true);
    }
  }
  
  /// Simulate syncing data with server with artificial delay
  Future<bool> fakeSyncWithServer(ScanResult scanResult) async {
    AppLogger.info('MockDataService', 'Fake sync with server: ${scanResult.scanId}');
    
    // Simulate network delay
    await Future.delayed(Duration(milliseconds: 500 + _random.nextInt(1000)));
    
    // 90% chance of success
    return _random.nextDouble() < 0.9;
  }
  
  /// Simulate batch syncing with server with artificial delay
  Future<int> fakeBatchSync(List<ScanResult> scanResults) async {
    AppLogger.info('MockDataService', 'Fake batch sync: ${scanResults.length} records');
    
    // Simulate network delay
    await Future.delayed(Duration(milliseconds: 1000 + _random.nextInt(2000)));
    
    // Randomly determine how many were synced successfully
    final successRate = 0.7 + (_random.nextDouble() * 0.3); // 70-100% success
    final successCount = (scanResults.length * successRate).floor();
    
    return successCount;
  }
}