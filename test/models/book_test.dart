import 'package:flutter_test/flutter_test.dart';
import 'package:bbeta/models/book.dart';
import 'package:bbeta/models/genre.dart';

void main() {
  group('Book Model', () {
    test('fromJson creates Book correctly with all fields', () {
      final json = {
        'id': 1,
        'title': 'The Great Gatsby',
        'author': 'F. Scott Fitzgerald',
        'isbn_10': '1234567890',
        'isbn_13': '1234567890123',
        'total_pages': 180,
        'cover_url': 'https://example.com/cover.jpg',
        'description': 'A classic American novel',
        'publisher': 'Scribner',
        'published_date': '1925-04-10',
        'language': 'en',
        'google_books_id': 'abc123',
        'genres': [
          {'id': 1, 'name': 'Fiction', 'slug': 'fiction'},
          {'id': 2, 'name': 'Classic', 'slug': 'classic'},
        ],
        'added_by': 1,
        'file': 'https://example.com/book.pdf',
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-02T00:00:00Z',
      };

      final book = Book.fromJson(json);

      expect(book.id, 1);
      expect(book.title, 'The Great Gatsby');
      expect(book.author, 'F. Scott Fitzgerald');
      expect(book.isbn10, '1234567890');
      expect(book.isbn13, '1234567890123');
      expect(book.totalPages, 180);
      expect(book.coverUrl, 'https://example.com/cover.jpg');
      expect(book.description, 'A classic American novel');
      expect(book.publisher, 'Scribner');
      expect(book.language, 'en');
      expect(book.genres.length, 2);
      expect(book.genres[0].name, 'Fiction');
      expect(book.fileUrl, 'https://example.com/book.pdf');
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 1,
        'title': 'Minimal Book',
      };

      final book = Book.fromJson(json);

      expect(book.id, 1);
      expect(book.title, 'Minimal Book');
      expect(book.author, isNull);
      expect(book.totalPages, isNull);
      expect(book.genres, isEmpty);
      expect(book.fileUrl, isNull);
    });

    test('hasPdf returns true when fileUrl is present', () {
      final book = Book(
        id: 1,
        title: 'Test Book',
        fileUrl: 'https://example.com/book.pdf',
      );

      expect(book.hasPdf, true);
    });

    test('hasPdf returns false when fileUrl is null', () {
      final book = Book(
        id: 1,
        title: 'Test Book',
        fileUrl: null,
      );

      expect(book.hasPdf, false);
    });

    test('hasPdf returns false when fileUrl is empty', () {
      final book = Book(
        id: 1,
        title: 'Test Book',
        fileUrl: '',
      );

      expect(book.hasPdf, false);
    });

    test('genreNames returns comma-separated genre names', () {
      final book = Book(
        id: 1,
        title: 'Test Book',
        genres: [
          Genre(id: 1, name: 'Fiction', slug: 'fiction'),
          Genre(id: 2, name: 'Classic', slug: 'classic'),
          Genre(id: 3, name: 'Drama', slug: 'drama'),
        ],
      );

      expect(book.genreNames, 'Fiction, Classic');
    });

    test('genreNames returns empty string when no genres', () {
      final book = Book(
        id: 1,
        title: 'Test Book',
        genres: [],
      );

      expect(book.genreNames, '');
    });

    test('toJson creates correct map', () {
      final book = Book(
        id: 1,
        title: 'Test Book',
        author: 'Test Author',
        totalPages: 100,
        genres: [Genre(id: 1, name: 'Fiction', slug: 'fiction')],
      );

      final json = book.toJson();

      expect(json['id'], 1);
      expect(json['title'], 'Test Book');
      expect(json['author'], 'Test Author');
      expect(json['total_pages'], 100);
      expect((json['genres'] as List).length, 1);
    });
  });

  group('Genre Model', () {
    test('fromJson creates Genre correctly', () {
      final json = {
        'id': 1,
        'name': 'Science Fiction',
        'slug': 'science-fiction',
      };

      final genre = Genre.fromJson(json);

      expect(genre.id, 1);
      expect(genre.name, 'Science Fiction');
      expect(genre.slug, 'science-fiction');
    });

    test('toJson creates correct map', () {
      final genre = Genre(id: 1, name: 'Fiction', slug: 'fiction');

      final json = genre.toJson();

      expect(json['id'], 1);
      expect(json['name'], 'Fiction');
      expect(json['slug'], 'fiction');
    });
  });
}
