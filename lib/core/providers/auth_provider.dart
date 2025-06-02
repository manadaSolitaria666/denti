// lib/core/providers/auth_provider.dart
import 'package:dental_ai_app/core/providers/user_data_provider.dart';
import 'package:dental_ai_app/core/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AuthScreenStatus { initial, loading, success, error }

class AuthNotifier extends StateNotifier<AuthScreenStatus> {
  final AuthService _authService;
  final UserProfileNotifier _userProfileNotifier;

  AuthNotifier(this._authService, this._userProfileNotifier) : super(AuthScreenStatus.initial);

  Future<void> signIn(String email, String password) async {
    state = AuthScreenStatus.loading;
    try {
      await _authService.signInWithEmailAndPassword(email, password);
      state = AuthScreenStatus.success;
    } catch (e) {
      state = AuthScreenStatus.error;
      rethrow;
    }
  }

  Future<void> signUp(String email, String password) async {
    state = AuthScreenStatus.loading;
    try {
      UserCredential userCredential = await _authService.createUserWithEmailAndPassword(email, password);
      if (userCredential.user != null) {
        await _userProfileNotifier.createUserProfileAfterRegistration(
          userCredential.user!.uid,
          email,
        );
      }
      state = AuthScreenStatus.success;
    } catch (e) {
      state = AuthScreenStatus.error;
      rethrow;
    }
  }

  Future<void> signOut() async {
    state = AuthScreenStatus.loading;
    try {
      await _authService.signOut();
      state = AuthScreenStatus.initial;
    } catch (e) {
      state = AuthScreenStatus.error;
      rethrow;
    }
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthScreenStatus>((ref) {
  return AuthNotifier(
    ref.watch(authServiceProvider),
    ref.watch(userProfileNotifierProvider.notifier),
  );
});