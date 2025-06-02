// lib/core/providers/user_data_provider.dart
import 'dart:async';
import 'package:dental_ai_app/core/models/user_model.dart';
import 'package:dental_ai_app/core/services/auth_service.dart';
import 'package:dental_ai_app/core/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserProfileNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final FirestoreService _firestoreService;
  final AuthService _authService;
  User? _currentUser;
  StreamSubscription<User?>? _authStateSubscription;

  UserProfileNotifier(this._firestoreService, this._authService) : super(const AsyncValue.loading()) {
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    _authStateSubscription?.cancel();
    _authStateSubscription = _authService.authStateChanges.listen((user) {
      _currentUser = user;
      if (user != null) {
        if (state is! AsyncData || (state.asData?.value?.id != user.uid)) {
          _loadUserProfile(user.uid);
        }
      } else {
        if (mounted) {
          state = const AsyncValue.data(null);
        }
      }
    });
  }

  Future<void> _loadUserProfile(String userId) async {
    if (state is AsyncLoading && state.asData?.value?.id == userId) return;

    if (mounted) {
      state = const AsyncValue.loading();
    }
    try {
      final userModel = await _firestoreService.getUserData(userId);
      if (mounted) {
        state = AsyncValue.data(userModel);
      }
    } catch (e, s) {
      if (mounted) {
        state = AsyncValue.error(e, s);
      }
    }
  }

  Future<UserModel?> getOrFetchUserProfile(String userId) async {
    if (state is AsyncData && state.asData?.value?.id == userId) {
      return state.asData!.value;
    }
    await _loadUserProfile(userId);
    return state.asData?.value;
  }

  Future<void> createUserProfileAfterRegistration(String userId, String email) async {
    try {
      final newUser = UserModel(
        id: userId,
        email: email,
        termsAccepted: false,
        createdAt: null, 
      );
      await _firestoreService.setUserData(newUser);
      if (mounted) {
        state = AsyncValue.data(newUser);
      }
    } catch (e, s) {
      if (mounted) {
        state = AsyncValue.error(e, s);
      }
      rethrow;
    }
  }

  Future<void> updateUserDetails({
    required String name,
    required String surname,
    required int age,
    required String sex,
    required bool termsAccepted,
  }) async {
    if (_currentUser == null) {
      if (mounted) {
        state = AsyncValue.error("Usuario no autenticado para actualizar detalles.", StackTrace.current);
      }
      return;
    }
    
    UserModel? baseProfile = state.asData?.value;

    if (baseProfile == null || baseProfile.id != _currentUser!.uid) {
        baseProfile = await _firestoreService.getUserData(_currentUser!.uid);
    }

    final updatedUser = (baseProfile ?? UserModel(id: _currentUser!.uid, email: _currentUser!.email))
        .copyWith(
      name: name,
      surname: surname,
      age: age,
      sex: sex,
      termsAccepted: termsAccepted,
    );

    try {
      await _firestoreService.setUserData(updatedUser);
      if (mounted) {
        state = AsyncValue.data(updatedUser);
      }
    } catch (e, s) {
      if (mounted) {
        state = AsyncValue.error(e, s);
      }
      rethrow;
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}

final userProfileNotifierProvider =
    StateNotifierProvider<UserProfileNotifier, AsyncValue<UserModel?>>((ref) {
  return UserProfileNotifier(
    ref.watch(firestoreServiceProvider),
    ref.watch(authServiceProvider),
  );
});

final currentUserProfileProvider = Provider<UserModel?>((ref) {
  final asyncUserProfile = ref.watch(userProfileNotifierProvider);
  return asyncUserProfile.whenOrNull(data: (user) => user);
});