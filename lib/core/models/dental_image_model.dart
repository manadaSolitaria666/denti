// lib/core/models/dental_image_model.dart
import 'package:equatable/equatable.dart';

class DentalImageModel extends Equatable {
  final String id; // Podría ser el nombre del archivo en Storage o un ID único
  final String angleDescription; // Ej: "Frontal", "Lateral Izquierda", etc.
  final String localPath; // Ruta local antes de subir
  final String? downloadUrl; // URL de Firebase Storage después de subir

  const DentalImageModel({
    required this.id,
    required this.angleDescription,
    required this.localPath,
    this.downloadUrl,
  });

  DentalImageModel copyWith({
    String? id,
    String? angleDescription,
    String? localPath,
    String? downloadUrl,
  }) {
    return DentalImageModel(
      id: id ?? this.id,
      angleDescription: angleDescription ?? this.angleDescription,
      localPath: localPath ?? this.localPath,
      downloadUrl: downloadUrl ?? this.downloadUrl,
    );
  }

  Map<String, dynamic> toMap() { // Para guardar en Firestore como parte de un reporte
    return {
      'id': id,
      'angleDescription': angleDescription,
      'downloadUrl': downloadUrl,
    };
  }

  factory DentalImageModel.fromMap(Map<String, dynamic> map) {
    return DentalImageModel(
      id: map['id'] as String,
      angleDescription: map['angleDescription'] as String,
      localPath: '', // La ruta local no se guarda en Firestore
      downloadUrl: map['downloadUrl'] as String?,
    );
  }


  @override
  List<Object?> get props => [id, angleDescription, localPath, downloadUrl];
}