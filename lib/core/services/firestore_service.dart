// lib/core/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dental_ai_app/core/models/diagnosis_report_model.dart';
import 'package:dental_ai_app/core/models/user_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FirestoreService {
  final FirebaseFirestore _db;

  FirestoreService(this._db);

  // Colección de usuarios
  CollectionReference<UserModel> get usersCollection => _db.collection('users').withConverter<UserModel>(
        fromFirestore: (snapshots, _) => UserModel.fromFirestore(snapshots),
        toFirestore: (user, _) => user.toFirestore(),
      );

  // Colección de reportes de diagnóstico
  CollectionReference<DiagnosisReportModel> reportsCollection(String userId) =>
      _db.collection('users').doc(userId).collection('diagnosisReports').withConverter<DiagnosisReportModel>(
            fromFirestore: (snapshots, _) => DiagnosisReportModel.fromFirestore(snapshots),
            toFirestore: (report, _) => report.toFirestore(),
          );

  // --- Operaciones de Usuario ---
  Future<void> setUserData(UserModel user) async {
    try {
      await usersCollection.doc(user.id).set(user, SetOptions(merge: true));
    } catch (e) {
      // print('Error en setUserData: $e');
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
      // print('Error en getUserData: $e');
      throw Exception('Error al obtener datos del usuario: ${e.toString()}');
    }
  }

  Stream<UserModel?> streamUserData(String userId) {
     try {
      return usersCollection.doc(userId).snapshots().map((snapshot) => snapshot.data());
    } catch (e) {
      // print('Error en streamUserData: $e');
      return Stream.error('Error al obtener datos del usuario en tiempo real: ${e.toString()}');
    }
  }


  // --- Operaciones de Reporte de Diagnóstico ---
  Future<DocumentReference<DiagnosisReportModel>> addDiagnosisReport(String userId, DiagnosisReportModel report) async {
    try {
      // Asegurarse que el createdAt se establece aquí si no se hizo antes
      final reportWithTimestamp = report.createdAt.millisecondsSinceEpoch == 0 // Chequeo simple
          ? DiagnosisReportModel(
              id: report.id, // El ID se genera por Firestore, pero puede pasarse si ya existe
              userId: userId,
              createdAt: Timestamp.now(), // Establece el timestamp aquí
              formData: report.formData,
              images: report.images,
              geminiPrompt: report.geminiPrompt,
              geminiResponseRaw: report.geminiResponseRaw,
              identifiedSigns: report.identifiedSigns,
              recommendations: report.recommendations,
              error: report.error,
            )
          : report;
      return await reportsCollection(userId).add(reportWithTimestamp);
    } catch (e) {
      // print('Error en addDiagnosisReport: $e');
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
      // print('Error en streamDiagnosisReports: $e');
      return Stream.error('Error al obtener reportes de diagnóstico: ${e.toString()}');
    }
  }

  Future<void> deleteDiagnosisReport(String userId, String reportId) async {
    try {
      await reportsCollection(userId).doc(reportId).delete();
    } catch (e) {
      // print('Error en deleteDiagnosisReport: $e');
      throw Exception('Error al eliminar el reporte: ${e.toString()}');
    }
  }
}

// Provider para FirebaseFirestore
final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

// Provider para FirestoreService
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService(ref.watch(firebaseFirestoreProvider));
});