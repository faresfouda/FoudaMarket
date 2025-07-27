import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firebase_service.dart';
import '../../models/user_model.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../../core/services/auth_service.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();
  AuthBloc() : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<SignInRequested>(_onSignInRequested);
    on<SignUpRequested>(_onSignUpRequested);
    on<SignOutRequested>(_onSignOutRequested);
    on<PasswordResetRequested>(_onPasswordResetRequested);
    on<GuestLoginRequested>((event, emit) {
      emit(Guest());
    });
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Get user profile from Firestore
        final userProfile = await _firebaseService.getUserProfile(user.uid);
        print('userProfile from Firestore: $userProfile');
        UserModel? userModel;
        if (userProfile != null && userProfile is Map<String, dynamic>) {
          try {
            userModel = UserModel(
              id: userProfile['id'] ?? user.uid,
              name: userProfile['name'] ?? user.displayName ?? 'User',
              email: userProfile['email'] ?? user.email ?? '',
              phone: userProfile['phone'] ?? user.phoneNumber ?? '',
              role: userProfile['role'] ?? 'user',
              avatarUrl: userProfile['avatar_url'],
              createdAt: userProfile['createdAt'] != null
                  ? (userProfile['createdAt'] as Timestamp).toDate()
                  : DateTime.now(),
              updatedAt: userProfile['updatedAt'] != null
                  ? (userProfile['updatedAt'] as Timestamp).toDate()
                  : DateTime.now(),
            );
          } catch (e) {
            print('❌ Error creating UserModel: $e');
            print('❌ userProfile data: $userProfile');
            emit(AuthError(message: 'خطأ في قراءة بيانات المستخدم!'));
            return;
          }
        } else {
          print('❌ Firestore userProfile is not a Map: $userProfile');
          print('❌ userProfile type: ${userProfile.runtimeType}');
          // محاولة إصلاح بيانات المستخدم
          try {
            await _authService.repairUserProfile(user.uid, user);
            // إعادة محاولة قراءة البيانات بعد الإصلاح
            final repairedProfile = await _firebaseService.getUserProfile(user.uid);
            if (repairedProfile != null && repairedProfile is Map<String, dynamic>) {
              userModel = UserModel(
                id: repairedProfile['id'] ?? user.uid,
                name: repairedProfile['name'] ?? user.displayName ?? 'User',
                email: repairedProfile['email'] ?? user.email ?? '',
                phone: repairedProfile['phone'] ?? user.phoneNumber ?? '',
                role: repairedProfile['role'] ?? 'user',
                avatarUrl: repairedProfile['avatar_url'],
                createdAt: repairedProfile['createdAt'] != null
                    ? (repairedProfile['createdAt'] as Timestamp).toDate()
                    : DateTime.now(),
                updatedAt: repairedProfile['updatedAt'] != null
                    ? (repairedProfile['updatedAt'] as Timestamp).toDate()
                    : DateTime.now(),
              );
              print('✅ User profile repaired successfully');
            } else {
              emit(AuthError(message: 'فشل في إصلاح بيانات المستخدم!'));
              return;
            }
          } catch (e) {
            print('❌ Failed to repair user profile: $e');
            emit(AuthError(message: 'بيانات المستخدم غير صالحة!'));
            return;
          }
        }
        emit(Authenticated(user: user, userProfile: userModel));
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onSignInRequested(
    SignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final credential = await _firebaseService.signIn(
        email: event.email,
        password: event.password,
      );

      if (credential.user != null) {
        // Get user profile from Firestore
        final userProfile = await _firebaseService.getUserProfile(
          credential.user!.uid,
        );
        print('userProfile from Firestore: $userProfile');
        UserModel? userModel;
        if (userProfile != null && userProfile is Map<String, dynamic>) {
          try {
            userModel = UserModel(
              id: userProfile['id'] ?? credential.user!.uid,
              name: userProfile['name'] ?? credential.user!.displayName ?? 'User',
              email: userProfile['email'] ?? credential.user!.email ?? '',
              phone: userProfile['phone'] ?? credential.user!.phoneNumber ?? '',
              role: userProfile['role'] ?? 'user',
              avatarUrl: userProfile['avatar_url'],
              createdAt: userProfile['createdAt'] != null
                  ? (userProfile['createdAt'] as Timestamp).toDate()
                  : DateTime.now(),
              updatedAt: userProfile['updatedAt'] != null
                  ? (userProfile['updatedAt'] as Timestamp).toDate()
                  : DateTime.now(),
            );
          } catch (e) {
            print('❌ Error creating UserModel: $e');
            print('❌ userProfile data: $userProfile');
            emit(AuthError(message: 'خطأ في قراءة بيانات المستخدم!'));
            return;
          }
        } else {
          print('❌ Firestore userProfile is not a Map: $userProfile');
          print('❌ userProfile type: ${userProfile.runtimeType}');
          emit(AuthError(message: 'بيانات المستخدم غير صالحة!'));
          return;
        }
        emit(Authenticated(user: credential.user!, userProfile: userModel));
      } else {
        emit(AuthError(message: 'Sign in failed'));
      }
    } catch (e) {
      emit(AuthError(message: _getErrorMessage(e)));
    }
  }

  Future<void> _onSignUpRequested(
    SignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final credential = await _firebaseService.signUp(
        email: event.email,
        password: event.password,
        name: event.name,
        phone: event.phone,
        role: event.role,
      );

      if (credential.user != null) {
        // Send email verification if not verified
        if (!credential.user!.emailVerified) {
          await credential.user!.sendEmailVerification();
          emit(EmailVerificationRequired(credential.user!.email!));
          // لا تسجل دخوله مباشرة
          return;
        }
        // Sign out the user immediately after successful signup
        await _firebaseService.signOut();
        // Emit success state instead of authenticated
        emit(SignUpSuccess(email: event.email));
      } else {
        emit(AuthError(message: 'Sign up failed'));
      }
    } catch (e) {
      emit(AuthError(message: _getErrorMessage(e)));
    }
  }

  // Future<void> _onGoogleSignInRequested(
  //   GoogleSignInRequested event,
  //   Emitter<AuthState> emit,
  // ) async {
  //   emit(AuthLoading());
  //   try {
  //     final userCredential = await _googleAuthService.signInWithGoogle();

  //     if (userCredential?.user != null) {
  //       // Get user profile from Firestore
  //       final userProfile = await _googleAuthService.getUserProfile(
  //         userCredential!.user!.uid,
  //       );
  //       UserModel? userModel;
  //       if (userProfile != null) {
  //         userModel = userProfile;
  //       }
  //       emit(Authenticated(user: userCredential.user!, userProfile: userModel));
  //     } else {
  //       emit(AuthError(message: 'تم إلغاء تسجيل الدخول بجوجل من قبل المستخدم.'));
  //     }
  //   } catch (e) {
  //     emit(AuthError(message: _getGoogleSignInErrorMessage(e)));
  //   }
  // }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _firebaseService.signOut();
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onPasswordResetRequested(
    PasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _firebaseService.resetPassword(event.email);
      emit(PasswordResetSent(email: event.email));
    } catch (e) {
      emit(AuthError(message: _getErrorMessage(e)));
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'لا يوجد مستخدم بهذا البريد الإلكتروني.';
        case 'wrong-password':
          return 'كلمة المرور غير صحيحة.';
        case 'email-already-in-use':
          return 'البريد الإلكتروني مستخدم بالفعل.';
        case 'weak-password':
          return 'كلمة المرور ضعيفة جداً.';
        case 'invalid-email':
          return 'البريد الإلكتروني غير صحيح.';
        case 'too-many-requests':
          return 'عدد كبير من المحاولات. يرجى المحاولة لاحقاً.';
        case 'network-request-failed':
          return 'فشل في الاتصال بالإنترنت. تحقق من اتصالك.';
        case 'operation-not-allowed':
          return 'هذه العملية غير مسموح بها.';
        default:
          return 'حدث خطأ غير متوقع. يرجى المحاولة لاحقاً.';
      }
    }

    if (error.toString().contains('network') ||
        error.toString().contains('connection')) {
      return 'فشل في الاتصال بالشبكة. تحقق من الإنترنت.';
    }

    return 'حدث خطأ غير متوقع: ${error.toString()}';
  }

  String _getGoogleSignInErrorMessage(dynamic error) {
    final errorStr = error.toString();
    if (errorStr.contains('access_denied')) {
      return 'تم رفض الوصول من جوجل. يرجى السماح للتطبيق بالوصول.';
    }
    if (errorStr.contains('sign_in_canceled') || errorStr.contains('popup_closed_by_user')) {
      return 'تم إلغاء العملية من قبل المستخدم.';
    }
    if (errorStr.contains('network') || errorStr.contains('connection')) {
      return 'فشل في الاتصال بالإنترنت. تحقق من اتصالك.';
    }
    if (errorStr.contains('account-exists-with-different-credential')) {
      return 'البريد مرتبط بطريقة تسجيل مختلفة.';
    }
    return 'حدث خطأ أثناء تسجيل الدخول بجوجل: $errorStr';
  }
}
