// lib/data/models/establishment.dart
enum EstablishmentType {
  restaurant,
  retailStore,
  transportationService,
  government,
  hotel,
  other
}

class Establishment {
  final String id;
  final String name;
  final String? address;
  final String? contactNumber;
  final String? email;
  final EstablishmentType type;
  
  const Establishment({
    required this.id,
    required this.name,
    this.address,
    this.contactNumber,
    this.email,
    required this.type,
  });
  
  factory Establishment.fromJson(Map<String, dynamic> json) {
    return Establishment(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      contactNumber: json['contactNumber'],
      email: json['email'],
      type: EstablishmentType.values.byName(json['type']),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'contactNumber': contactNumber,
      'email': email,  
      'type': type.name,
    };
  }
}