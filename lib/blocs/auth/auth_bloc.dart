import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firebase_service.dart';
import '../../models/user_model.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AuthBloc() : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<SignInRequested>(_onSignInRequested);
    on<SignUpRequested>(_onSignUpRequested);
    on<SignOutRequested>(_onSignOutRequested);
    on<PasswordResetRequested>(_onPasswordResetRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    print('AuthBloc: AuthLoading emitted (AuthCheckRequested)');
    print('AuthBloc: FirebaseAuth.currentUser at AuthCheckRequested: ' + _auth.currentUser.toString());
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Get user profile from Firestore
        final userProfile = await _firebaseService.getUserProfile(user.uid);
        UserModel? userModel;
        if (userProfile != null) {
          userModel = UserModel(
            id: userProfile['id'],
            name: userProfile['name'],
            email: userProfile['email'],
            phone: userProfile['phone'],
            role: userProfile['role'],
            createdAt: userProfile['createdAt'] != null
                ? (userProfile['createdAt'] as Timestamp).toDate()
                : DateTime.now(),
            updatedAt: userProfile['updatedAt'] != null
                ? (userProfile['updatedAt'] as Timestamp).toDate()
                : DateTime.now(),
          );
        }
        print('AuthBloc: Authenticated emitted (AuthCheckRequested)');
        emit(Authenticated(user: user, userProfile: userModel));
      } else {
        print('AuthBloc: Unauthenticated emitted (AuthCheckRequested)');
        emit(Unauthenticated());
      }
    } catch (e) {
      print('AuthBloc: AuthError emitted (AuthCheckRequested): ' + e.toString());
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onSignInRequested(
    SignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    print('AuthBloc: AuthLoading emitted (SignInRequested)');
    try {
      final credential = await _firebaseService.signIn(
        email: event.email,
        password: event.password,
      );
      
      if (credential.user != null) {
        // Get user profile from Firestore
        final userProfile = await _firebaseService.getUserProfile(credential.user!.uid);
        UserModel? userModel;
        if (userProfile != null) {
          userModel = UserModel(
            id: userProfile['id'],
            name: userProfile['name'],
            email: userProfile['email'],
            phone: userProfile['phone'],
            role: userProfile['role'],
            createdAt: userProfile['createdAt'] != null
                ? (userProfile['createdAt'] as Timestamp).toDate()
                : DateTime.now(),
            updatedAt: userProfile['updatedAt'] != null
                ? (userProfile['updatedAt'] as Timestamp).toDate()
                : DateTime.now(),
          );
        }
        print('AuthBloc: Authenticated emitted (SignInRequested)');
        emit(Authenticated(user: credential.user!, userProfile: userModel));
      } else {
        print('AuthBloc: AuthError emitted (SignInRequested): Sign in failed');
        emit(AuthError(message: 'Sign in failed'));
      }
    } catch (e) {
      print('AuthBloc: AuthError emitted (SignInRequested): ' + e.toString());
      emit(AuthError(message: _getErrorMessage(e)));
    }
  }

  Future<void> _onSignUpRequested(
    SignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    print('AuthBloc: AuthLoading emitted (SignUpRequested)');
    try {
      print('Starting signup process for: ${event.email}');
      
      final credential = await _firebaseService.signUp(
        email: event.email,
        password: event.password,
        name: event.name,
        phone: event.phone,
        role: event.role,
      );
      
      print('Signup successful, user ID: ${credential.user?.uid}');
      
      if (credential.user != null) {
        // Sign out the user immediately after successful signup
        await _firebaseService.signOut();
        print('User signed out after signup');
        print('AuthBloc: SignUpSuccess emitted (SignUpRequested)');
        // Emit success state instead of authenticated
        emit(SignUpSuccess(email: event.email));
      } else {
        print('AuthBloc: AuthError emitted (SignUpRequested): Sign up failed');
        emit(AuthError(message: 'Sign up failed'));
      }
    } catch (e) {
      print('Signup error in BLoC: $e');
      print('AuthBloc: AuthError emitted (SignUpRequested): ' + e.toString());
      emit(AuthError(message: _getErrorMessage(e)));
    }
  }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    print('AuthBloc: AuthLoading emitted (SignOutRequested)');
    try {
      await _firebaseService.signOut();
      print('AuthBloc: Unauthenticated emitted (SignOutRequested)');
      emit(Unauthenticated());
    } catch (e) {
      print('AuthBloc: AuthError emitted (SignOutRequested): ' + e.toString());
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onPasswordResetRequested(
    PasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    print('AuthBloc: AuthLoading emitted (PasswordResetRequested)');
    try {
      await _firebaseService.resetPassword(event.email);
      print('AuthBloc: PasswordResetSent emitted (PasswordResetRequested)');
      emit(PasswordResetSent(email: event.email));
    } catch (e) {
      print('AuthBloc: AuthError emitted (PasswordResetRequested): ' + e.toString());
      emit(AuthError(message: _getErrorMessage(e)));
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'لا يوجد مستخدم بهذا البريد الإلكتروني';
        case 'wrong-password':
          return 'كلمة المرور غير صحيحة';
        case 'email-already-in-use':
          return 'البريد الإلكتروني مستخدم بالفعل';
        case 'weak-password':
          return 'كلمة المرور ضعيفة جداً';
        case 'invalid-email':
          return 'البريد الإلكتروني غير صحيح';
        case 'too-many-requests':
          return 'تم تجاوز الحد الأقصى للمحاولات، يرجى المحاولة لاحقاً';
        case 'network-request-failed':
          return 'فشل في الاتصال بالشبكة، يرجى التحقق من اتصال الإنترنت';
        case 'operation-not-allowed':
          return 'العملية غير مسموح بها';
        default:
          return error.message ?? 'حدث خطأ غير متوقع';
      }
    }
    

    
    // Handle network errors
    if (error.toString().contains('network') || error.toString().contains('connection')) {
      return 'مشكلة في الاتصال بالشبكة، يرجى التحقق من اتصال الإنترنت';
    }
    
    return error.toString();
  }
} 