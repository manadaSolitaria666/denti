// lib/core/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dental_ai_app/core/models/blog_post_model.dart';
import 'package:dental_ai_app/core/models/clinic_model.dart';
import 'package:dental_ai_app/core/models/diagnosis_report_model.dart';
import 'package:dental_ai_app/core/models/user_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FirestoreService {
  final FirebaseFirestore _db;

  FirestoreService(this._db);

  // --- REFERENCIAS A COLECCIONES ---
  CollectionReference<UserModel> get usersCollection => _db.collection('users').withConverter<UserModel>(
        fromFirestore: (snapshots, _) => UserModel.fromFirestore(snapshots),
        toFirestore: (user, _) => user.toFirestore(),
      );

  CollectionReference<DiagnosisReportModel> reportsCollection(String userId) =>
      _db.collection('users').doc(userId).collection('diagnosisReports').withConverter<DiagnosisReportModel>(
            fromFirestore: (snapshots, _) => DiagnosisReportModel.fromFirestore(snapshots),
            toFirestore: (report, _) => report.toFirestore(),
          );

  CollectionReference<ClinicModel> get clinicsCollection => _db.collection('clinics').withConverter<ClinicModel>(
        fromFirestore: (snapshots, _) => ClinicModel.fromFirestore(snapshots),
        toFirestore: (clinic, _) => throw UnimplementedError(), 
      );

  CollectionReference<BlogPostModel> get postsCollection => _db.collection('posts').withConverter<BlogPostModel>(
        fromFirestore: (snapshots, _) => BlogPostModel.fromFirestore(snapshots),
        toFirestore: (post, _) => throw UnimplementedError(),
      ); 

  // --- OPERACIONES DE USUARIO ---
  Future<void> setUserData(UserModel user) async {
    try {
      await usersCollection.doc(user.id).set(user, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Error al guardar datos del usuario: ${e.toString()}');
    }
  }

  Future<UserModel?> getUserData(String userId) async {
    try {
      final docSnapshot = await usersCollection.doc(userId).get();
      if (docSnapshot.exists) {
        return docSnapshot.data();
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener datos del usuario: ${e.toString()}');
    }
  }

  Stream<UserModel?> streamUserData(String userId) {
     try {
      return usersCollection.doc(userId).snapshots().map((snapshot) => snapshot.data());
    } catch (e) {
      return Stream.error('Error al obtener datos del usuario en tiempo real: ${e.toString()}');
    }
  }

  // --- OPERACIONES DE REPORTE DE DIAGNÓSTICO ---
  Future<DocumentReference<DiagnosisReportModel>> addDiagnosisReport(String userId, DiagnosisReportModel report) async {
    try {
      return await reportsCollection(userId).add(report);
    } catch (e) {
      throw Exception('Error al guardar el reporte de diagnóstico: ${e.toString()}');
    }
  }

  Stream<List<DiagnosisReportModel>> streamDiagnosisReports(String userId) {
    try {
      return reportsCollection(userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
    } catch (e) {
      return Stream.error('Error al obtener reportes de diagnóstico: ${e.toString()}');
    }
  }

  Future<void> deleteDiagnosisReport(String userId, String reportId) async {
    try {
      await reportsCollection(userId).doc(reportId).delete();
    } catch (e) {
      throw Exception('Error al eliminar el reporte: ${e.toString()}');
    }
  }

  // --- OPERACIONES DEL BLOG ---
  Future<List<BlogPostModel>> getAllPosts() async {
    try {
      final snapshot = await postsCollection.orderBy('createdAt', descending: true).get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Error al cargar los posts del blog: ${e.toString()}');
    }
  }

  Future<BlogPostModel?> getPostById(String postId) async {
    try {
      final docSnapshot = await postsCollection.doc(postId).get();
      return docSnapshot.data();
    } catch (e) {
      throw Exception('Error al cargar el post: ${e.toString()}');
    }
  }
  
  // --- OPERACIÓN DE CLÍNICAS ---
  Future<List<ClinicModel>> getAllClinics() async {
    try {
      if (kDebugMode) print("[FirestoreService] Obteniendo clínicas...");
      final snapshot = await clinicsCollection.get();
      final clinics = snapshot.docs.map((doc) => doc.data()).toList();
      if (kDebugMode) print("[FirestoreService] Se encontraron ${clinics.length} clínicas.");
      return clinics;
    } catch (e) {
      if (kDebugMode) print("[FirestoreService] Error obteniendo clínicas: $e");
      throw Exception('Error al cargar las clínicas desde la base de datos.');
    }
  }
} // <<<--- ESTA ES LA LLAVE DE CIERRE CORRECTA PARA LA CLASE

// PROVIDERS
final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService(ref.watch(firebaseFirestoreProvider));
});