// lib/core/providers/diagnosis_provider.dart (Corregido)
import 'dart:io';
import 'package:dental_ai_app/core/models/dental_image_model.dart';
import 'package:dental_ai_app/core/models/diagnosis_report_model.dart';
import 'package:dental_ai_app/core/services/auth_service.dart';
import 'package:dental_ai_app/core/services/firestore_service.dart';
import 'package:dental_ai_app/core/services/gemini_service.dart';
import 'package:dental_ai_app/core/services/storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

// La clase DiagnosisFlowState se mantiene igual
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

// El Notifier con el método corregido
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
    state = state.copyWith(localImageFiles: [], formData: {});
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
      String diagnosisSessionId = _uuid.v4();

      for (int i = 0; i < state.localImageFiles.length; i++) {
        final file = state.localImageFiles[i];
        final angleDesc = state.formData['image_angle_description_$i'] ?? 'image_unknown_angle_$i';
        
        final downloadUrl = await _storageService.uploadDentalImage(
          userId: userId,
          imageFile: file,
          diagnosisId: diagnosisSessionId,
          angleDescription: angleDesc,
        );
        uploadedImageModels.add(DentalImageModel(
          id: _uuid.v4(), 
          angleDescription: angleDesc,
          localPath: file.path,
          downloadUrl: downloadUrl,
        ));
      }

      final geminiResult = await _geminiService.analyzeDentalData(
        formData: state.formData,
        imageFiles: state.localImageFiles,
      );

      // Verificar si Gemini devolvió un error
      if (geminiResult['error'] != null) {
        throw Exception(geminiResult['error']);
      }

      // --- INICIO DE LA CORRECCIÓN ---
      // Usar el nuevo factory constructor de DiagnosisReportModel para crear el reporte
      // a partir de la respuesta estructurada de Gemini.
      final DiagnosisReportModel reportDraft = DiagnosisReportModel.fromGeminiResponse(
        geminiResult, // El mapa completo devuelto por GeminiService
        userId: userId,
        formData: state.formData,
        images: uploadedImageModels,
      );
      // --- FIN DE LA CORRECCIÓN ---

      final docRef = await _firestoreService.addDiagnosisReport(userId, reportDraft);
      
      final finalReport = reportDraft.copyWith(id: docRef.id); 

      state = state.copyWith(isLoading: false, currentGeneratedReport: finalReport);
      return finalReport.id;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error en generateDiagnosisAndSaveReport: $e\n$stackTrace');
      }
      state = state.copyWith(isLoading: false, errorMessage: "Error al generar diagnóstico: ${e.toString()}");
      return null;
    }
  }
}

// Los providers se mantienen igual
final diagnosisNotifierProvider = StateNotifierProvider<DiagnosisNotifier, DiagnosisFlowState>((ref) {
  return DiagnosisNotifier(
    ref.watch(geminiServiceProvider),
    ref.watch(storageServiceProvider),
    ref.watch(firestoreServiceProvider),
    ref.watch(authServiceProvider),
  );
});

final diagnosisHistoryProvider = StreamProvider.autoDispose<List<DiagnosisReportModel>>((ref) {
  final userId = ref.watch(authStateChangesProvider).value?.uid;
  if (userId == null) {
    return Stream.value([]);
  }
  try {
    return ref.watch(firestoreServiceProvider).streamDiagnosisReports(userId);
  } catch (e) {
    return Stream.error("Error al cargar historial: ${e.toString()}");
  }
});
