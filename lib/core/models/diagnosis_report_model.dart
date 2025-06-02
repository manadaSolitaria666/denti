// lib/core/models/diagnosis_report_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dental_ai_app/core/models/dental_image_model.dart';
import 'package:equatable/equatable.dart';

class DiagnosisReportModel extends Equatable {
  final String id; // ID del documento en Firestore
  final String userId;
  final Timestamp createdAt;
  final Map<String, dynamic> formData; // Datos del formulario (síntomas, etc.)
  final List<DentalImageModel> images; // Lista de imágenes asociadas
  final String geminiPrompt; // El prompt exacto enviado a Gemini
  final String geminiResponseRaw; // Respuesta cruda de Gemini
  final String identifiedSigns; // Signos identificados (parseado de la respuesta)
  final String recommendations; // Recomendaciones (parseado de la respuesta)
  final String? error; // Si hubo un error en el proceso

  const DiagnosisReportModel({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.formData,
    required this.images,
    required this.geminiPrompt,
    required this.geminiResponseRaw,
    required this.identifiedSigns,
    required this.recommendations,
    this.error, // Puede ser nulo
  });

  // Factory constructor para crear desde un DocumentSnapshot de Firestore
  factory DiagnosisReportModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      // Considera cómo manejar el caso en que el documento no tiene datos.
      // Podrías lanzar una excepción o devolver un objeto con valores por defecto/error.
      // Por ahora, lanzaremos una excepción para ser explícitos.
      throw StateError('Missing data for DiagnosisReportModel from Firestore with ID: ${doc.id}');
    }
    return DiagnosisReportModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '', // Proveer un valor por defecto si es nulo
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(), // Proveer un valor por defecto
      formData: Map<String, dynamic>.from(data['formData'] as Map? ?? {}),
      images: (data['images'] as List<dynamic>?)
              ?.map((imgData) => DentalImageModel.fromMap(Map<String, dynamic>.from(imgData as Map)))
              .toList() ??
          [],
      geminiPrompt: data['geminiPrompt'] as String? ?? "Prompt no registrado.",
      geminiResponseRaw: data['geminiResponseRaw'] as String? ?? "Respuesta cruda no registrada.",
      identifiedSigns: data['identifiedSigns'] as String? ?? "No se pudieron identificar signos específicos.",
      recommendations: data['recommendations'] as String? ?? "No se pudieron generar recomendaciones.",
      error: data['error'] as String?, // 'error' puede ser nulo
    );
  }

  // Método para convertir a un Map para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      // 'createdAt' usualmente se maneja con FieldValue.serverTimestamp() al crear,
      // pero si se actualiza un objeto existente, se puede pasar el valor actual.
      // Si 'createdAt' es null en el objeto y es una nueva creación, FirestoreService debería manejarlo.
      'createdAt': createdAt, 
      'formData': formData,
      'images': images.map((img) => img.toMap()).toList(),
      'geminiPrompt': geminiPrompt,
      'geminiResponseRaw': geminiResponseRaw,
      'identifiedSigns': identifiedSigns,
      'recommendations': recommendations,
      if (error != null) 'error': error, // Solo incluir si no es nulo
    };
  }

  // Método copyWith para crear una copia del objeto con campos actualizados
  DiagnosisReportModel copyWith({
    String? id,
    String? userId,
    Timestamp? createdAt,
    Map<String, dynamic>? formData,
    List<DentalImageModel>? images,
    String? geminiPrompt,
    String? geminiResponseRaw,
    String? identifiedSigns,
    String? recommendations,
    String? error,
    bool clearError = false, // Para explícitamente establecer el error a null
  }) {
    return DiagnosisReportModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      formData: formData ?? this.formData,
      images: images ?? this.images,
      geminiPrompt: geminiPrompt ?? this.geminiPrompt,
      geminiResponseRaw: geminiResponseRaw ?? this.geminiResponseRaw,
      identifiedSigns: identifiedSigns ?? this.identifiedSigns,
      recommendations: recommendations ?? this.recommendations,
      error: clearError ? null : (error ?? this.error), // Manejo para limpiar o actualizar el error
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        createdAt,
        formData,
        images,
        geminiPrompt,
        geminiResponseRaw,
        identifiedSigns,
        recommendations,
        error,
      ];
}
