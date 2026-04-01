class ReadingStats {
  final int totalXp;
  final int currentStreak;
  final int booksFinished;
  final double totalTimeHours;

  ReadingStats({
    required this.totalXp,
    required this.currentStreak,
    required this.booksFinished,
    required this.totalTimeHours,
  });

  factory ReadingStats.fromJson(Map<String, dynamic> json) {
    return ReadingStats(
      totalXp: json['total_xp'] as int? ?? 0,
      currentStreak: json['current_streak'] as int? ?? 0,
      booksFinished: json['books_finished'] as int? ?? 0,
      totalTimeHours: (json['total_time_hours'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'total_xp': totalXp,
        'current_streak': currentStreak,
        'books_finished': booksFinished,
        'total_time_hours': totalTimeHours,
      };

  String get formattedTotalHours => totalTimeHours.toStringAsFixed(1);
}

class ReadingSession {
  final int id;
  final int bookId;
  final String bookTitle;
  final int startPage;
  final int endPage;
  final int pagesRead;
  final int durationMinutes;
  final int xpEarned;
  final DateTime createdAt;

  ReadingSession({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    required this.startPage,
    required this.endPage,
    required this.pagesRead,
    required this.durationMinutes,
    required this.xpEarned,
    required this.createdAt,
  });

  factory ReadingSession.fromJson(Map<String, dynamic> json) {
    return ReadingSession(
      id: json['id'] as int,
      bookId: json['book'] as int,
      bookTitle: json['book_title'] as String,
      startPage: json['start_page'] as int,
      endPage: json['end_page'] as int,
      pagesRead: json['pages_read'] as int,
      durationMinutes: json['duration_minutes'] as int,
      xpEarned: json['xp_earned'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'book': bookId,
        'book_title': bookTitle,
        'start_page': startPage,
        'end_page': endPage,
        'pages_read': pagesRead,
        'duration_minutes': durationMinutes,
        'xp_earned': xpEarned,
        'created_at': createdAt.toIso8601String(),
      };
}
