import 'genre.dart';

class Book {
  final int id;
  final String title;
  final String? author;
  final String? isbn10;
  final String? isbn13;
  final int? totalPages;
  final String? coverUrl;
  final String? description;
  final String? publisher;
  final String? publishedDate;
  final String? language;
  final String? googleBooksId;
  final List<Genre> genres;
  final int? addedBy;
  final String? fileUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Book({
    required this.id,
    required this.title,
    this.author,
    this.isbn10,
    this.isbn13,
    this.totalPages,
    this.coverUrl,
    this.description,
    this.publisher,
    this.publishedDate,
    this.language,
    this.googleBooksId,
    this.genres = const [],
    this.addedBy,
    this.fileUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as int,
      title: json['title'] as String,
      author: json['author'] as String?,
      isbn10: json['isbn_10'] as String?,
      isbn13: json['isbn_13'] as String?,
      totalPages: json['total_pages'] as int?,
      coverUrl: json['cover_url'] as String?,
      description: json['description'] as String?,
      publisher: json['publisher'] as String?,
      publishedDate: json['published_date'] as String?,
      language: json['language'] as String?,
      googleBooksId: json['google_books_id'] as String?,
      genres: (json['genres'] as List<dynamic>?)
              ?.map((g) => Genre.fromJson(g as Map<String, dynamic>))
              .toList() ??
          [],
      addedBy: json['added_by'] as int?,
      fileUrl: json['file'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'author': author,
        'isbn_10': isbn10,
        'isbn_13': isbn13,
        'total_pages': totalPages,
        'cover_url': coverUrl,
        'description': description,
        'publisher': publisher,
        'published_date': publishedDate,
        'language': language,
        'google_books_id': googleBooksId,
        'genres': genres.map((g) => g.toJson()).toList(),
        'added_by': addedBy,
        'file': fileUrl,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  bool get hasPdf => fileUrl != null && fileUrl!.isNotEmpty;

  String get genreNames =>
      genres.map((g) => g.name).take(2).join(', ');
}
