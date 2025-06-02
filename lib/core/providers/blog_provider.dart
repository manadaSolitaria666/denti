// lib/core/providers/blog_provider.dart
import 'package:dental_ai_app/core/models/blog_post_model.dart';
import 'package:dental_ai_app/core/services/blog_api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final blogPostsProvider = FutureProvider.autoDispose<List<BlogPostModel>>((ref) async {
  final blogService = ref.watch(blogApiServiceProvider);
  try {
    return await blogService.getBlogPosts();
  } catch (e) {
    rethrow;
  }
});

final blogPostDetailProvider = FutureProvider.autoDispose.family<BlogPostModel?, String>((ref, postId) async {
  final blogService = ref.watch(blogApiServiceProvider);
  try {
    return await blogService.getBlogPostById(postId);
  } catch (e) {
    return null;
  }
});