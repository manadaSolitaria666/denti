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

  // --- Método para Google Sign-In ---
  Future<void> googleSignIn() async {
    state = AuthScreenStatus.loading;
    try {
      final userCredential = await _authService.signInWithGoogle();
      if (userCredential?.user != null) {
        // Verificar si el usuario ya existe en Firestore
        final userProfile = await _userProfileNotifier.getOrFetchUserProfile(userCredential!.user!.uid);
        if (userProfile == null) {
          // Si es un usuario nuevo, crear su perfil en Firestore
          await _userProfileNotifier.createUserProfileAfterRegistration(
            userCredential.user!.uid,
            userCredential.user!.email ?? '',
          );
        }
      }
      state = AuthScreenStatus.success;
    } catch (e) {
      state = AuthScreenStatus.error;
      rethrow;
    }
  }

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
      final userCredential = await _authService.createUserWithEmailAndPassword(email, password);
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
