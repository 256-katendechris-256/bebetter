class LeaderboardEntry {
  final int userId;
  final String username;
  final String? firstName;
  final String displayName;
  final int totalXp;
  final int currentStreak;
  final int booksFinished;
  final int totalPagesRead;
  final int rank;
  final bool isCurrentUser;

  LeaderboardEntry({
    required this.userId,
    required this.username,
    this.firstName,
    required this.displayName,
    required this.totalXp,
    required this.currentStreak,
    required this.booksFinished,
    required this.totalPagesRead,
    required this.rank,
    required this.isCurrentUser,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['user_id'] as int,
      username: json['username'] as String? ?? '',
      firstName: json['first_name'] as String?,
      displayName: json['display_name'] as String? ?? 'Reader',
      totalXp: json['total_xp'] as int? ?? 0,
      currentStreak: json['current_streak'] as int? ?? 0,
      booksFinished: json['books_finished'] as int? ?? 0,
      totalPagesRead: json['total_pages_read'] as int? ?? 0,
      rank: json['rank'] as int? ?? 0,
      isCurrentUser: json['is_current_user'] as bool? ?? false,
    );
  }

  String get formattedXp {
    if (totalXp >= 1000) {
      return '${(totalXp / 1000).toStringAsFixed(1)}k';
    }
    return totalXp.toString();
  }
}

class LeaderboardResponse {
  final List<LeaderboardEntry> leaderboard;
  final int totalParticipants;
  final int? currentUserRank;
  final LeaderboardEntry? currentUserEntry;

  LeaderboardResponse({
    required this.leaderboard,
    required this.totalParticipants,
    this.currentUserRank,
    this.currentUserEntry,
  });

  factory LeaderboardResponse.fromJson(Map<String, dynamic> json) {
    return LeaderboardResponse(
      leaderboard: (json['leaderboard'] as List<dynamic>?)
              ?.map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalParticipants: json['total_participants'] as int? ?? 0,
      currentUserRank: json['current_user_rank'] as int?,
      currentUserEntry: json['current_user_entry'] != null
          ? LeaderboardEntry.fromJson(
              json['current_user_entry'] as Map<String, dynamic>)
          : null,
    );
  }
}

class MyRankResponse {
  final int? rank;
  final int totalParticipants;
  final double percentile;
  final int xpToNextRank;
  final List<LeaderboardEntry> above;
  final List<LeaderboardEntry> below;

  MyRankResponse({
    this.rank,
    required this.totalParticipants,
    required this.percentile,
    required this.xpToNextRank,
    required this.above,
    required this.below,
  });

  factory MyRankResponse.fromJson(Map<String, dynamic> json) {
    return MyRankResponse(
      rank: json['rank'] as int?,
      totalParticipants: json['total_participants'] as int? ?? 0,
      percentile: (json['percentile'] as num?)?.toDouble() ?? 0.0,
      xpToNextRank: json['xp_to_next_rank'] as int? ?? 0,
      above: (json['above'] as List<dynamic>?)
              ?.map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      below: (json['below'] as List<dynamic>?)
              ?.map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
