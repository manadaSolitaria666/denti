// lib/core/models/diagnosis_report_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dental_ai_app/core/models/dental_image_model.dart';
import 'package:equatable/equatable.dart';

class DiagnosisReportModel extends Equatable {
  final String id;
  final String userId;
  final Timestamp createdAt;
  final Map<String, dynamic> formData;
  final List<DentalImageModel> images;
  
  // New fields for the structured AI response
  final String overallSummary;
  final List<String> possibleConditions;
  final String severityLevel;
  final String detailedRecommendations;
  final String nextSteps;
  
  // Debugging fields
  final String geminiPrompt;
  final String geminiResponseRaw;
  final String? error;

  const DiagnosisReportModel({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.formData,
    required this.images,
    required this.overallSummary,
    required this.possibleConditions,
    required this.severityLevel,
    required this.detailedRecommendations,
    required this.nextSteps,
    required this.geminiPrompt,
    required this.geminiResponseRaw,
    this.error,
  });

  factory DiagnosisReportModel.fromGeminiResponse(Map<String, dynamic> geminiData, {
    required String userId,
    required Map<String, dynamic> formData,
    required List<DentalImageModel> images,
  }) {
    return DiagnosisReportModel(
      id: '',
      userId: userId,
      createdAt: Timestamp.now(),
      formData: formData,
      images: images,
      overallSummary: geminiData['overallSummary'] as String? ?? "No se pudo generar un resumen.",
      possibleConditions: List<String>.from(geminiData['possibleConditions'] as List? ?? []),
      severityLevel: geminiData['severityLevel'] as String? ?? "Indeterminado",
      detailedRecommendations: geminiData['detailedRecommendations'] as String? ?? "No se generaron recomendaciones.",
      nextSteps: geminiData['nextSteps'] as String? ?? "Consultar con un dentista.",
      geminiPrompt: geminiData['fullPrompt'] as String? ?? "Prompt no disponible.",
      geminiResponseRaw: geminiData['rawResponse'] as String? ?? "Respuesta no disponible.",
      error: geminiData['error'] as String?,
    );
  }

  factory DiagnosisReportModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return DiagnosisReportModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      formData: Map<String, dynamic>.from(data['formData'] as Map? ?? {}),
      images: (data['images'] as List<dynamic>?)?.map((img) => DentalImageModel.fromMap(Map<String, dynamic>.from(img))).toList() ?? [],
      overallSummary: data['overallSummary'] as String? ?? "No se encontró resumen.",
      possibleConditions: List<String>.from(data['possibleConditions'] as List? ?? []),
      severityLevel: data['severityLevel'] as String? ?? "Indeterminado",
      detailedRecommendations: data['detailedRecommendations'] as String? ?? "No se encontraron recomendaciones.",
      nextSteps: data['nextSteps'] as String? ?? "Consultar con un dentista.",
      geminiPrompt: data['geminiPrompt'] as String? ?? '',
      geminiResponseRaw: data['geminiResponseRaw'] as String? ?? '',
      error: data['error'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'createdAt': createdAt,
      'formData': formData,
      'images': images.map((img) => img.toMap()).toList(),
      'overallSummary': overallSummary,
      'possibleConditions': possibleConditions,
      'severityLevel': severityLevel,
      'detailedRecommendations': detailedRecommendations,
      'nextSteps': nextSteps,
      'geminiPrompt': geminiPrompt,
      'geminiResponseRaw': geminiResponseRaw,
      if (error != null) 'error': error,
    };
  }

  DiagnosisReportModel copyWith({ String? id }) {
    return DiagnosisReportModel(
      id: id ?? this.id,
      userId: userId,
      createdAt: createdAt,
      formData: formData,
      images: images,
      overallSummary: overallSummary,
      possibleConditions: possibleConditions,
      severityLevel: severityLevel,
      detailedRecommendations: detailedRecommendations,
      nextSteps: nextSteps,
      geminiPrompt: geminiPrompt,
      geminiResponseRaw: geminiResponseRaw,
      error: error,
    );
  }

  @override
  List<Object?> get props => [id, userId, createdAt, overallSummary, severityLevel];
}