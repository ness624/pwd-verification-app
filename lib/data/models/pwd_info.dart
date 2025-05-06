// pwd_info.dart
class PWDInfo {
  final String id;
  final String fullName;
  final String pwdNumber;
  final DateTime expiryDate;
  final String disabilityType;
  final String? address;
  final String? contactNumber;
  final String? photo; // Base64 encoded image string
  
  const PWDInfo({
    required this.id,
    required this.fullName,
    required this.pwdNumber,
    required this.expiryDate,
    required this.disabilityType,
    this.address,
    this.contactNumber,
    this.photo,
  });
  
  factory PWDInfo.fromJson(Map<String, dynamic> json) {
    return PWDInfo(
      id: json['id'],
      fullName: json['fullName'],
      pwdNumber: json['pwdNumber'],
      expiryDate: DateTime.parse(json['expiryDate']),
      disabilityType: json['disabilityType'],
      address: json['address'],
      contactNumber: json['contactNumber'],
      photo: json['photo'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'pwdNumber': pwdNumber,
      'expiryDate': expiryDate.toIso8601String(),
      'disabilityType': disabilityType,
      'address': address,
      'contactNumber': contactNumber,
      'photo': photo,
    };
  }
  
  bool get isExpired => expiryDate.isBefore(DateTime.now());
}