import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final User user;
  final UserModel? userProfile;

  const Authenticated({
    required this.user,
    this.userProfile,
  });

  @override
  List<Object?> get props => [user, userProfile];
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}

class PasswordResetSent extends AuthState {
  final String email;

  const PasswordResetSent({required this.email});

  @override
  List<Object?> get props => [email];
}

class SignUpSuccess extends AuthState {
  final String email;
  final String message;

  const SignUpSuccess({
    required this.email,
    this.message = 'تم إنشاء الحساب بنجاح! يمكنك الآن تسجيل الدخول.',
  });

  @override
  List<Object?> get props => [email, message];
}

class Guest extends AuthState {
  @override
  List<Object?> get props => [];
} 