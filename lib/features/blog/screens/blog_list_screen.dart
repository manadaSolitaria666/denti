// lib/features/blog/screens/blog_list_screen.dart
import 'package:dental_ai_app/core/navigation/app_router.dart';
import 'package:dental_ai_app/core/providers/blog_provider.dart';
import 'package:dental_ai_app/features/blog/widgets/blog_post_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class BlogListScreen extends ConsumerWidget {
  const BlogListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blogPostsAsyncValue = ref.watch(blogPostsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blog Educativo Dental'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Invalida el provider para forzar una recarga
          ref.invalidate(blogPostsProvider);
          // Espera a que el nuevo FutureProvider complete.
          // Esto es una forma de esperar, pero puede ser más complejo si hay errores.
          // Una mejor manera podría ser usar `ref.refresh(blogPostsProvider.future)`
          await ref.read(blogPostsProvider.future);
        },
        child: blogPostsAsyncValue.when(
          data: (posts) {
            if (posts.isEmpty) {
              return LayoutBuilder( // Para que el Center ocupe el espacio disponible en ListView
                builder: (context, constraints) {
                  return SingleChildScrollView( // Para que el RefreshIndicator funcione
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.article_outlined, size: 80, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No hay artículos disponibles.',
                                style: Theme.of(context).textTheme.headlineSmall,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Vuelve más tarde para leer contenido educativo.',
                                style: Theme.of(context).textTheme.titleMedium,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return BlogPostCard(
                  post: post,
                  onTap: () {
                    context.goNamed(
                      AppRoutes.blogDetail,
                      pathParameters: {'postId': post.id},
                      extra: post, // Pasa el objeto post para evitar recargarlo si ya lo tenemos
                    );
                  },
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) {
            // print("Error en BlogListScreen: $err");
            return LayoutBuilder( // Para que el Center ocupe el espacio disponible en ListView
                builder: (context, constraints) {
                  return SingleChildScrollView( // Para que el RefreshIndicator funcione
                     physics: const AlwaysScrollableScrollPhysics(),
                     child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, color: Colors.red, size: 50),
                                const SizedBox(height: 10),
                                Text(
                                  'Error al cargar artículos: ${err.toString()}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.red),
                                ),
                                const SizedBox(height: 10),
                                ElevatedButton(
                                  onPressed: () => ref.invalidate(blogPostsProvider),
                                  child: const Text("Reintentar")
                                )
                              ],
                            ),
                          ),
                        ),
                     ),
                  );
                }
            );
          },
        ),
      ),
    );
  }
}
