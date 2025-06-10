// lib/features/blog/widgets/blog_post_card.dart
import 'package:dental_ai_app/core/models/blog_post_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BlogPostCard extends StatelessWidget {
  final BlogPostModel post;
  final VoidCallback onTap;

  const BlogPostCard({super.key, required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Usar 'createdAt' y convertirlo de Timestamp a DateTime
    final String formattedDate = DateFormat('dd MMM, yyyy').format(post.createdAt.toDate());

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Usar 'coverImageUrl'
            if (post.coverImageUrl != null && post.coverImageUrl!.isNotEmpty)
              Hero(
                tag: 'blog_image_${post.id}',
                child: Image.network(
                  post.coverImageUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  // ... (errorBuilder y loadingBuilder sin cambios)
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Text(formattedDate, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  // Usar 'excerpt' en lugar de 'summary'
                  Text(post.excerpt, style: Theme.of(context).textTheme.bodyMedium, maxLines: 3, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 12),
                  Align(alignment: Alignment.centerRight, child: Text('Leer más →', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}