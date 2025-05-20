import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  
  @override
  List<Object?> get props => [];
}

class LoginEvent extends AuthEvent {
  final String username;
  final String password;
  
  const LoginEvent(this.username, this.password);
  
  @override
  List<Object?> get props => [username, password];
}

class RegisterEvent extends AuthEvent {
  final String email;
  final String password;
  final String fullName;
  final String phoneNumber;
  final String organizationName;
  final String organizationType;
  
  const RegisterEvent({
    required this.email,
    required this.password,
    required this.fullName,
    required this.phoneNumber,
    required this.organizationName,
    required this.organizationType,
  });
  
  @override
  List<Object?> get props => [email, password, fullName, phoneNumber, organizationName, organizationType];
}

class LogoutEvent extends AuthEvent {}

class CheckAuthStatusEvent extends AuthEvent {}

class AuthServerEventOccurred extends AuthEvent {
  final AuthChangeEvent event;
  
  const AuthServerEventOccurred(this.event);
  
  @override
  List<Object?> get props => [event];
}