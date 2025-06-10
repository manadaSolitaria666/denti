// lib/core/providers/blog_provider.dart
import 'package:dental_ai_app/core/models/blog_post_model.dart';
import 'package:dental_ai_app/core/services/firestore_service.dart'; // <<<--- CAMBIO
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider para obtener la lista de posts del blog desde Firestore
final blogPostsProvider = FutureProvider.autoDispose<List<BlogPostModel>>((ref) async {
  // Ya no usamos BlogApiService, usamos FirestoreService
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getAllPosts();
});

// Provider para obtener un post específico por ID desde Firestore
final blogPostDetailProvider = FutureProvider.autoDispose.family<BlogPostModel?, String>((ref, postId) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getPostById(postId);
});
