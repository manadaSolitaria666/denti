// lib/core/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  AuthService(this._firebaseAuth, this._googleSignIn);

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
  User? get currentUser => _firebaseAuth.currentUser;

  // --- Lógica para Google Sign-In ---
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Iniciar el flujo de inicio de sesión de Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // El usuario canceló el flujo
        return null;
      }

      // Obtener los detalles de autenticación de la solicitud
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Crear una credencial de Firebase con el token de Google
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Iniciar sesión en Firebase con la credencial
      return await _firebaseAuth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('Error de FirebaseAuth en Google Sign-In: ${e.message}');
      }
      throw Exception('Error al iniciar sesión con Google: ${e.message}');
    } catch (e) {
      if (kDebugMode) {
        print('Error inesperado en Google Sign-In: ${e.toString()}');
      }
      // Considera desconectar para limpiar el estado de google_sign_in si falla
      await _googleSignIn.signOut();
      throw Exception('Ocurrió un error inesperado al intentar iniciar sesión con Google.');
    }
  }

  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw Exception('Error al iniciar sesión: ${e.message}');
    } catch (e) {
      throw Exception('Ocurrió un error inesperado: ${e.toString()}');
    }
  }

  Future<UserCredential> createUserWithEmailAndPassword(String email, String password) async {
    try {
      return await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw Exception('Error al registrar: ${e.message}');
    } catch (e) {
      throw Exception('Ocurrió un error inesperado: ${e.toString()}');
    }
  }

  Future<void> signOut() async {
    // Cerrar sesión tanto en Google como en Firebase
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }
}

// Providers para los servicios de autenticación
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);
final googleSignInProvider = Provider<GoogleSignIn>((ref) => GoogleSignIn());

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref.watch(firebaseAuthProvider),
    ref.watch(googleSignInProvider), // Inyectar GoogleSignIn
  );
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

