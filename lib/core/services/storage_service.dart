// lib/core/services/storage_service.dart
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p; // Para obtener la extensión del archivo

class StorageService {
  final FirebaseStorage _firebaseStorage;

  StorageService(this._firebaseStorage);

  Future<String> uploadDentalImage({
    required String userId,
    required File imageFile,
    required String diagnosisId, // Para organizar las imágenes por diagnóstico
    required String angleDescription, // Ej: "frontal", "lateral_derecha"
  }) async {
    try {
      final fileExtension = p.extension(imageFile.path);
      final fileName = '${angleDescription}_${DateTime.now().millisecondsSinceEpoch}$fileExtension';
      final ref = _firebaseStorage
          .ref()
          .child('users/$userId/diagnoses/$diagnosisId/images/$fileName');

      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      // print('Error al subir imagen: ${e.message}');
      throw Exception('Error al subir la imagen: ${e.message}');
    } catch (e) {
      // print('Error inesperado al subir imagen: $e');
      throw Exception('Ocurrió un error inesperado al subir la imagen.');
    }
  }

  Future<void> deleteDentalImage(String downloadUrl) async {
    try {
      final ref = _firebaseStorage.refFromURL(downloadUrl);
      await ref.delete();
    } on FirebaseException catch (e) {
      // print('Error al eliminar imagen: ${e.message}');
      // No relanzar excepción si el archivo no existe, podría ser un borrado previo
      if (e.code != 'object-not-found') {
        throw Exception('Error al eliminar la imagen: ${e.message}');
      }
    } catch (e) {
      // print('Error inesperado al eliminar imagen: $e');
      throw Exception('Ocurrió un error inesperado al eliminar la imagen.');
    }
  }
}

// Provider para FirebaseStorage
final firebaseStorageProvider = Provider<FirebaseStorage>((ref) => FirebaseStorage.instance);

// Provider para StorageService
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(ref.watch(firebaseStorageProvider));
});