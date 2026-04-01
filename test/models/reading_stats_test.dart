import 'package:flutter_test/flutter_test.dart';
import 'package:bbeta/models/reading_stats.dart';

void main() {
  group('ReadingStats Model', () {
    test('fromJson creates ReadingStats correctly', () {
      final json = {
        'total_xp': 1500,
        'current_streak': 7,
        'books_finished': 3,
        'total_time_hours': 24.5,
      };

      final stats = ReadingStats.fromJson(json);

      expect(stats.totalXp, 1500);
      expect(stats.currentStreak, 7);
      expect(stats.booksFinished, 3);
      expect(stats.totalTimeHours, 24.5);
    });

    test('fromJson handles missing fields with defaults', () {
      final json = <String, dynamic>{};

      final stats = ReadingStats.fromJson(json);

      expect(stats.totalXp, 0);
      expect(stats.currentStreak, 0);
      expect(stats.booksFinished, 0);
      expect(stats.totalTimeHours, 0.0);
    });

    test('formattedTotalHours formats correctly', () {
      final stats = ReadingStats(
        totalXp: 0,
        currentStreak: 0,
        booksFinished: 0,
        totalTimeHours: 24.567,
      );

      expect(stats.formattedTotalHours, '24.6');
    });

    test('toJson creates correct map', () {
      final stats = ReadingStats(
        totalXp: 1500,
        currentStreak: 7,
        booksFinished: 3,
        totalTimeHours: 24.5,
      );

      final json = stats.toJson();

      expect(json['total_xp'], 1500);
      expect(json['current_streak'], 7);
      expect(json['books_finished'], 3);
      expect(json['total_time_hours'], 24.5);
    });
  });

  group('ReadingSession Model', () {
    test('fromJson creates ReadingSession correctly', () {
      final json = {
        'id': 1,
        'book': 5,
        'book_title': 'The Great Gatsby',
        'start_page': 10,
        'end_page': 25,
        'pages_read': 15,
        'duration_minutes': 30,
        'xp_earned': 50,
        'created_at': '2024-01-15T10:30:00Z',
      };

      final session = ReadingSession.fromJson(json);

      expect(session.id, 1);
      expect(session.bookId, 5);
      expect(session.bookTitle, 'The Great Gatsby');
      expect(session.startPage, 10);
      expect(session.endPage, 25);
      expect(session.pagesRead, 15);
      expect(session.durationMinutes, 30);
      expect(session.xpEarned, 50);
    });

    test('toJson creates correct map', () {
      final session = ReadingSession(
        id: 1,
        bookId: 5,
        bookTitle: 'Test Book',
        startPage: 1,
        endPage: 10,
        pagesRead: 9,
        durationMinutes: 20,
        xpEarned: 30,
        createdAt: DateTime.parse('2024-01-15T10:30:00Z'),
      );

      final json = session.toJson();

      expect(json['id'], 1);
      expect(json['book'], 5);
      expect(json['book_title'], 'Test Book');
      expect(json['start_page'], 1);
      expect(json['end_page'], 10);
      expect(json['pages_read'], 9);
      expect(json['duration_minutes'], 20);
      expect(json['xp_earned'], 30);
    });
  });
}
