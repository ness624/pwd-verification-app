import 'package:equatable/equatable.dart';

enum UserRole {
  establishmentAdmin,
  establishmentStaff,
  unknown // Default/fallback
}

class User extends Equatable {
  final String id; // This will be the Supabase Auth User UID (from auth.users.id)
  final String? email; // From Supabase Auth
  final String? username; // Will be null as it's not in mobile_users
  final String fullName; // From mobile_users.full_name
  final UserRole role; // Will be UserRole.unknown as it's not in mobile_users
  final String? establishmentId; // This will be mobile_users.id (PK of mobile_users table)
  final String establishmentName; // From mobile_users.organization_name
  final DateTime? lastLoginTime; // From Supabase Auth or mobile_users.last_login_at

  const User({
    required this.id,
    this.email,
    this.username, // Will be null
    required this.fullName,
    this.role = UserRole.unknown, // Defaults to unknown
    this.establishmentId, // Mapped from mobile_users.id
    required this.establishmentName,
    this.lastLoginTime,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'],
      username: json['username'], // Will be null if not in JSON
      fullName: json['fullName'] ?? 'N/A',
      role: json['role'] != null && json['role'] is String // Check if role is a string before parsing
          ? UserRole.values.firstWhere(
              (e) => e.name == json['role'],
              orElse: () => UserRole.unknown,
            )
          : UserRole.unknown,
      establishmentId: json['establishmentId'], // Will be null if not in JSON
      establishmentName: json['establishmentName'] ?? '',
      lastLoginTime: json['lastLoginTime'] != null
          ? DateTime.tryParse(json['lastLoginTime'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'fullName': fullName,
      'role': role.name,
      'establishmentId': establishmentId,
      'establishmentName': establishmentName,
      'lastLoginTime': lastLoginTime?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id, email, username, fullName, role, establishmentId, establishmentName, lastLoginTime
      ];

  User copyWith({
    String? id,
    String? email,
    String? username, // Can pass null
    String? fullName,
    UserRole? role,
    String? establishmentId, // Can pass null
    String? establishmentName,
    DateTime? lastLoginTime,
    bool setUsernameToNull = false,
    bool setEstablishmentIdToNull = false,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      username: setUsernameToNull ? null : (username ?? this.username),
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      establishmentId: setEstablishmentIdToNull ? null : (establishmentId ?? this.establishmentId),
      establishmentName: establishmentName ?? this.establishmentName,
      lastLoginTime: lastLoginTime ?? this.lastLoginTime,
    );
  }
}