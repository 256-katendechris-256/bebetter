import 'book.dart';

enum ReadingStatus {
  wantToRead('WANT_TO_READ'),
  reading('READING'),
  finished('FINISHED'),
  dropped('DROPPED');

  final String value;
  const ReadingStatus(this.value);

  static ReadingStatus fromString(String value) {
    return ReadingStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => ReadingStatus.wantToRead,
    );
  }
}

class UserBook {
  final int id;
  final Book book;
  final ReadingStatus status;
  final int currentPage;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final double progressPercent;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserBook({
    required this.id,
    required this.book,
    required this.status,
    required this.currentPage,
    this.startedAt,
    this.finishedAt,
    required this.progressPercent,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserBook.fromJson(Map<String, dynamic> json) {
    return UserBook(
      id: json['id'] as int,
      book: Book.fromJson(json['book'] as Map<String, dynamic>),
      status: ReadingStatus.fromString(json['status'] as String),
      currentPage: json['current_page'] as int? ?? 0,
      startedAt: json['started_at'] != null
          ? DateTime.tryParse(json['started_at'] as String)
          : null,
      finishedAt: json['finished_at'] != null
          ? DateTime.tryParse(json['finished_at'] as String)
          : null,
      progressPercent: (json['progress_percent'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'book': book.toJson(),
        'status': status.value,
        'current_page': currentPage,
        'started_at': startedAt?.toIso8601String(),
        'finished_at': finishedAt?.toIso8601String(),
        'progress_percent': progressPercent,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  double get progressFraction => progressPercent / 100;
}
