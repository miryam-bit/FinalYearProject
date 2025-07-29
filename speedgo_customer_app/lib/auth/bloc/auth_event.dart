import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class LoginRequested extends AuthEvent {
  final String phone;
  final String password;

  const LoginRequested({required this.phone, required this.password});

  @override
  List<Object> get props => [phone, password];
}

class LogoutRequested extends AuthEvent {}

class RegistrationRequested extends AuthEvent {
  final String name;
  final String email;
  final String phone;
  final String password;
  final String passwordConfirmation;

  const RegistrationRequested({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.passwordConfirmation,
  });

  @override
  List<Object> get props => [name, email, phone, password, passwordConfirmation];
}

class OtpVerificationRequested extends AuthEvent {
  final String phone;
  final String otp;

  const OtpVerificationRequested({required this.phone, required this.otp});

  @override
  List<Object> get props => [phone, otp];
} 