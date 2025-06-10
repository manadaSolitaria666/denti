// lib/core/models/blog_post_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class BlogPostModel extends Equatable {
  final String id;
  final String title;
  final String content;
  final String excerpt; // Resumen o extracto
  final String? coverImageUrl;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  // Podrías añadir un modelo de autor si lo necesitas
  // final Map<String, dynamic> author; 

  const BlogPostModel({
    required this.id,
    required this.title,
    required this.content,
    required this.excerpt,
    this.coverImageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor para crear desde un DocumentSnapshot de Firestore
  factory BlogPostModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return BlogPostModel(
      id: doc.id,
      title: data['title'] as String? ?? 'Sin Título',
      content: data['content'] as String? ?? 'Contenido no disponible.',
      excerpt: data['excerpt'] as String? ?? '',
      coverImageUrl: data['coverImageUrl'] as String?,
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp? ?? Timestamp.now(),
    );
  }

  @override
  List<Object?> get props => [id, title, excerpt, coverImageUrl, createdAt];
}
