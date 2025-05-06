// lib/data/models/user.dart
import 'package:equatable/equatable.dart'; // Add Equatable for comparison

// Keep your enum definition
enum UserRole {
  establishmentAdmin,
  establishmentStaff,
  unknown // Add an unknown/default state
}

class User extends Equatable { // Extend Equatable
  final String id; // Provided by Supabase Auth
  final String? email; // Provided by Supabase Auth, make nullable if needed
  final String? username; // Assuming this comes from your profile table, make nullable
  final String fullName; // Assuming this comes from profile
  final UserRole role; // Assuming this comes from profile
  final String establishmentId; // Assuming this comes from profile
  final String establishmentName; // Assuming this comes from profile
  final DateTime? lastLoginTime; // Provided by Supabase Auth, make nullable

  const User({
    required this.id,
    this.email, // Make nullable
    this.username, // Make nullable
    required this.fullName,
    required this.role,
    required this.establishmentId,
    required this.establishmentName,
    this.lastLoginTime, // Make nullable
  });

  // Factory constructor for creating User from JSON (e.g., secure storage)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '', // Handle potential null from storage
      email: json['email'], // Read email
      username: json['username'], // Read username
      fullName: json['fullName'] ?? 'N/A', // Handle potential null
      role: UserRole.values.firstWhere( // Safer way to handle enum parsing
          (e) => e.name == json['role'],
          orElse: () => UserRole.unknown // Default if parse fails
      ),
      establishmentId: json['establishmentId'] ?? '', // Handle potential null
      establishmentName: json['establishmentName'] ?? '', // Handle potential null
      lastLoginTime: json['lastLoginTime'] != null
          ? DateTime.tryParse(json['lastLoginTime']) // Use tryParse for safety
          : null,
    );
  }

  // Method for converting User to JSON (e.g., for secure storage)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'fullName': fullName,
      'role': role.name,
      'establishmentId': establishmentId,
      'establishmentName': establishmentName,
      'lastLoginTime': lastLoginTime?.toIso8601String(), // Handle potential null
    };
  }

  // Equatable implementation
  @override
  List<Object?> get props => [
        id, email, username, fullName, role, establishmentId, establishmentName, lastLoginTime
      ];

  // Optional: copyWith method for easier state updates if needed elsewhere
  User copyWith({
    String? id,
    String? email,
    String? username,
    String? fullName,
    UserRole? role,
    String? establishmentId,
    String? establishmentName,
    DateTime? lastLoginTime,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      establishmentId: establishmentId ?? this.establishmentId,
      establishmentName: establishmentName ?? this.establishmentName,
      lastLoginTime: lastLoginTime ?? this.lastLoginTime,
    );
  }
}