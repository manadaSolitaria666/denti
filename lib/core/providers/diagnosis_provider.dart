// lib/core/providers/diagnosis_provider.dart
import 'dart:io';
import 'package:dental_ai_app/core/models/dental_image_model.dart';
import 'package:dental_ai_app/core/models/diagnosis_report_model.dart';
import 'package:dental_ai_app/core/services/auth_service.dart';
import 'package:dental_ai_app/core/services/firestore_service.dart';
import 'package:dental_ai_app/core/services/gemini_service.dart';
import 'package:dental_ai_app/core/services/storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:path/path.dart' as p; // No longer needed for image ID if using Uuid
import 'package:uuid/uuid.dart'; // For generating IDs unique

class DiagnosisFlowState {
  final Map<String, dynamic> formData;
  final List<File> localImageFiles;
  final bool isLoading;
  final String? errorMessage;
  final DiagnosisReportModel? currentGeneratedReport;

  DiagnosisFlowState({
    this.formData = const {},
    this.localImageFiles = const [],
    this.isLoading = false,
    this.errorMessage,
    this.currentGeneratedReport,
  });

  DiagnosisFlowState copyWith({
    Map<String, dynamic>? formData,
    List<File>? localImageFiles,
    bool? isLoading,
    String? errorMessage,
    DiagnosisReportModel? currentGeneratedReport,
    bool clearError = false,
  }) {
    return DiagnosisFlowState(
      formData: formData ?? this.formData,
      localImageFiles: localImageFiles ?? this.localImageFiles,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      currentGeneratedReport: currentGeneratedReport ?? this.currentGeneratedReport,
    );
  }
}

class DiagnosisNotifier extends StateNotifier<DiagnosisFlowState> {
  final GeminiService _geminiService;
  final StorageService _storageService;
  final FirestoreService _firestoreService;
  final AuthService _authService;
  final Uuid _uuid = const Uuid();

  DiagnosisNotifier(this._geminiService, this._storageService, this._firestoreService, this._authService)
      : super(DiagnosisFlowState());

  void updateFormData(Map<String, dynamic> data) {
    state = state.copyWith(formData: {...state.formData, ...data}, clearError: true);
  }

  void addImageFile(File image) {
    state = state.copyWith(localImageFiles: [...state.localImageFiles, image], clearError: true);
  }

  void removeImageFile(File image) {
    state = state.copyWith(
        localImageFiles: state.localImageFiles.where((f) => f.path != image.path).toList(),
        clearError: true);
  }

  void clearTemporaryImageData() {
    state = state.copyWith(localImageFiles: [], formData: {}); // Clear form data as well
  }

  void resetDiagnosisFlow() {
    state = DiagnosisFlowState();
  }

  Future<String?> generateDiagnosisAndSaveReport() async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      state = state.copyWith(isLoading: false, errorMessage: "Usuario no autenticado.");
      return null;
    }
    if (state.localImageFiles.isEmpty) {
      state = state.copyWith(isLoading: false, errorMessage: "Por favor, capture al menos una imagen.");
      return null;
    }

    state = state.copyWith(isLoading: true, clearError: true, currentGeneratedReport: null);

    try {
      List<DentalImageModel> uploadedImageModels = [];
      String diagnosisSessionId = _uuid.v4(); // Unique ID for this diagnostic session

      for (int i = 0; i < state.localImageFiles.length; i++) {
        final file = state.localImageFiles[i];
        final angleDesc = state.formData['image_angle_description_$i'] ?? 'image_angle_unknown_$i';
        
        final downloadUrl = await _storageService.uploadDentalImage(
          userId: userId,
          imageFile: file,
          diagnosisId: diagnosisSessionId, // Used for organizing in storage
          angleDescription: angleDesc,
        );
        uploadedImageModels.add(DentalImageModel(
          id: _uuid.v4(), // Unique ID for the image model itself
          angleDescription: angleDesc,
          localPath: file.path, // Not stored in Firestore, but part of the model
          downloadUrl: downloadUrl,
        ));
      }

      final geminiResult = await _geminiService.analyzeDentalData(
        formData: state.formData,
        imageFiles: state.localImageFiles,
      );

      // Create the report draft. ID will be empty initially.
      final DiagnosisReportModel reportDraft = DiagnosisReportModel(
        id: '', // Firestore will generate this upon adding the document
        userId: userId,
        createdAt: Timestamp.now(), // Set creation time
        formData: state.formData,
        images: uploadedImageModels, // List of image models with download URLs
        geminiPrompt: geminiResult['fullPrompt'] ?? "Prompt no disponible",
        geminiResponseRaw: geminiResult['rawResponse'] ?? "Respuesta cruda no disponible",
        identifiedSigns: geminiResult['identifiedSigns'] ?? "No se identificaron signos.",
        recommendations: geminiResult['recommendations'] ?? "No hay recomendaciones.",
        error: geminiResult['error'], // This could be null if no error from Gemini
      );

      // Add to Firestore, which returns a DocumentReference
      final docRef = await _firestoreService.addDiagnosisReport(userId, reportDraft);
      
      // Create the final report object by updating the draft with the actual ID from Firestore.
      // This relies on a correctly implemented `copyWith` in DiagnosisReportModel.
      final finalReport = reportDraft.copyWith(id: docRef.id); 

      state = state.copyWith(isLoading: false, currentGeneratedReport: finalReport);
      return finalReport.id; // Return the ID of the created report
    } catch (e) {
      // print('Error en generateDiagnosisAndSaveReport: $e\n$stackTrace'); // For debugging
      state = state.copyWith(isLoading: false, errorMessage: "Error al generar diagnóstico: ${e.toString()}");
      return null;
    }
  }
}

final diagnosisNotifierProvider = StateNotifierProvider<DiagnosisNotifier, DiagnosisFlowState>((ref) {
  return DiagnosisNotifier(
    ref.watch(geminiServiceProvider),
    ref.watch(storageServiceProvider),
    ref.watch(firestoreServiceProvider),
    ref.watch(authServiceProvider),
  );
});

// Provider for the stream of diagnosis history
final diagnosisHistoryProvider = StreamProvider.autoDispose<List<DiagnosisReportModel>>((ref) {
  final userId = ref.watch(authStateChangesProvider).value?.uid;
  if (userId == null) {
    return Stream.value([]); // Return an empty stream if no user is logged in
  }
  try {
    return ref.watch(firestoreServiceProvider).streamDiagnosisReports(userId);
  } catch (e) {
    // print("Error in diagnosisHistoryProvider: $e");
    return Stream.error("Error al cargar historial: ${e.toString()}");
  }
});