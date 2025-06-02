// lib/features/blog/screens/blog_detail_screen.dart
import 'package:dental_ai_app/core/models/blog_post_model.dart';
import 'package:dental_ai_app/core/providers/blog_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart'; // Para renderizar contenido HTML
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class BlogDetailScreen extends ConsumerWidget {
  final String postId;
  final BlogPostModel? post; // Opcional, si se pasa desde la lista para carga rápida

  const BlogDetailScreen({
    super.key,
    required this.postId,
    this.post,
  });

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // print('No se pudo lanzar $urlString');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Si tenemos el post, lo usamos, si no, lo cargamos.
    final blogPostAsyncValue = post != null
        ? AsyncValue.data(post!) // Usa el post pasado si existe
        : ref.watch(blogPostDetailProvider(postId)); // Carga por ID si no

    return Scaffold(
      body: blogPostAsyncValue.when(
        data: (loadedPost) {
          if (loadedPost == null) {
            return const Center(child: Text('Artículo no encontrado.'));
          }
          final DateFormat dateFormat = DateFormat('dd MMMM, yyyy');
          final String formattedDate = dateFormat.format(loadedPost.publishedDate);

          return CustomScrollView(
            slivers: <Widget>[
              SliverAppBar(
                expandedHeight: 250.0,
                floating: false,
                pinned: true,
                stretch: true,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  titlePadding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 12.0),
                  title: Text(
                    loadedPost.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16.0, // Tamaño más pequeño para el título en la barra colapsada
                      shadows: <Shadow>[
                        Shadow(
                          offset: Offset(0.0, 1.0),
                          blurRadius: 3.0,
                          color: Color.fromARGB(150, 0, 0, 0),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  background: loadedPost.imageUrl != null && loadedPost.imageUrl!.isNotEmpty
                      ? Hero(
                          tag: 'blog_image_${loadedPost.id}',
                          child: Image.network(
                            loadedPost.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(color: Colors.grey, child: const Icon(Icons.broken_image, size: 100)),
                          ),
                        )
                      : Container(color: Theme.of(context).primaryColor.withOpacity(0.3)), // Placeholder si no hay imagen
                ),
                 // Para asegurar que el título de la appbar no se superponga con los iconos de acción/leading
                // cuando está completamente colapsada.
                // titleSpacing: NavigationToolbar.kMiddleSpacing,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        loadedPost.title,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Publicado el $formattedDate',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                      ),
                      const Divider(height: 24, thickness: 1),
                      // Renderizar contenido HTML
                      Html(
                        data: loadedPost.content,
                        onLinkTap: (url, attributes, element) {
                          if (url != null) {
                            _launchUrl(url);
                          }
                        },
                        style: {
                          "body": Style(
                            fontSize: FontSize(16.0),
                            lineHeight: LineHeight.number(1.5),
                          ),
                          "p": Style(margin: Margins.only(bottom: 12.0)),
                           "h1": Style(fontSize: FontSize(24.0), fontWeight: FontWeight.bold),
                           "h2": Style(fontSize: FontSize(20.0), fontWeight: FontWeight.bold),
                           "h3": Style(fontSize: FontSize(18.0), fontWeight: FontWeight.bold),
                           // Puedes añadir más estilos para otros tags HTML
                        },
                      ),
                      if (loadedPost.videoUrl != null && loadedPost.videoUrl!.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          'Video Relacionado:',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        // Placeholder para un reproductor de video o un enlace
                        // Por simplicidad, un botón para abrir en YouTube/navegador
                        Center(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.play_circle_outline),
                            label: const Text('Ver Video'),
                            onPressed: () => _launchUrl(loadedPost.videoUrl!),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (err, stack) {
          // print("Error en BlogDetailScreen: $err");
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error al cargar el artículo: ${err.toString()}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
