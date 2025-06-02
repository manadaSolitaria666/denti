// lib/core/models/blog_post_model.dart
import 'package:equatable/equatable.dart';

class BlogPostModel extends Equatable {
  final String id;
  final String title;
  final String summary; // Un resumen corto
  final String content; // Contenido completo (puede ser HTML o Markdown)
  final String? imageUrl;
  final DateTime publishedDate;
  final String? videoUrl; // Opcional

  const BlogPostModel({
    required this.id,
    required this.title,
    required this.summary,
    required this.content,
    this.imageUrl,
    required this.publishedDate,
    this.videoUrl,
  });

  factory BlogPostModel.fromJson(Map<String, dynamic> json) {
    return BlogPostModel(
      id: json['id'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String,
      content: json['content'] as String,
      imageUrl: json['imageUrl'] as String?,
      publishedDate: DateTime.parse(json['publishedDate'] as String),
      videoUrl: json['videoUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'summary': summary,
      'content': content,
      'imageUrl': imageUrl,
      'publishedDate': publishedDate.toIso8601String(),
      'videoUrl': videoUrl,
    };
  }

  @override
  List<Object?> get props => [id, title, summary, content, imageUrl, publishedDate, videoUrl];
}