// lib/features/blog/screens/blog_detail_screen.dart
import 'package:dental_ai_app/core/models/blog_post_model.dart';
import 'package:dental_ai_app/core/providers/blog_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class BlogDetailScreen extends ConsumerWidget {
  final String postId;
  final BlogPostModel? post;

  const BlogDetailScreen({super.key, required this.postId, this.post});

  // ... (_launchUrl sin cambios)

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blogPostAsyncValue = post != null
        ? AsyncValue.data(post!)
        : ref.watch(blogPostDetailProvider(postId));

    return Scaffold(
      body: blogPostAsyncValue.when(
        data: (loadedPost) {
          if (loadedPost == null) {
            return const Center(child: Text('Artículo no encontrado.'));
          }
          final String formattedDate = DateFormat('dd MMMM, yyyy').format(loadedPost.createdAt.toDate());

          return CustomScrollView(
            slivers: <Widget>[
              SliverAppBar(
                expandedHeight: 250.0,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Text(loadedPost.title, style: const TextStyle(fontSize: 16.0), maxLines: 1, overflow: TextOverflow.ellipsis),
                  // Usar 'coverImageUrl'
                  background: loadedPost.coverImageUrl != null && loadedPost.coverImageUrl!.isNotEmpty
                      ? Hero(
                          tag: 'blog_image_${loadedPost.id}',
                          child: Image.network(
                            loadedPost.coverImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey),
                          ),
                        )
                      : Container(color: Theme.of(context).primaryColor.withOpacity(0.3)),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(loadedPost.title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Publicado el $formattedDate', style: Theme.of(context).textTheme.bodySmall),
                      const Divider(height: 24),
                      // Usar el campo 'content' para renderizar con flutter_html
                      Html(data: loadedPost.content),
                      // ... (sección de video si la tuvieras)
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (err, stack) => Scaffold(appBar: AppBar(title: const Text('Error')), body: Center(child: Text('Error al cargar el artículo.'))),
      ),
    );
  }
}
