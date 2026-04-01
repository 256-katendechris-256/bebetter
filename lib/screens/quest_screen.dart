import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/reading_stats.dart';
import '../services/api_service.dart';

class QuestScreen extends StatefulWidget {
  const QuestScreen({super.key});

  @override
  State<QuestScreen> createState() => _QuestScreenState();
}

class _QuestScreenState extends State<QuestScreen> {
  final _api = ApiService();
  
  ReadingStats? _stats;
  bool _loading = true;
  
  // Daily quests
  final List<Quest> _dailyQuests = [
    Quest(
      id: 'read_15_min',
      title: 'Daily Reader',
      description: 'Read for 15 minutes today',
      icon: '📖',
      xpReward: 25,
      targetValue: 15,
      unit: 'minutes',
    ),
    Quest(
      id: 'read_10_pages',
      title: 'Page Turner',
      description: 'Read 10 pages today',
      icon: '📄',
      xpReward: 30,
      targetValue: 10,
      unit: 'pages',
    ),
    Quest(
      id: 'maintain_streak',
      title: 'Keep the Fire',
      description: 'Maintain your reading streak',
      icon: '🔥',
      xpReward: 20,
      targetValue: 1,
      unit: 'day',
    ),
  ];

  // Weekly quests
  final List<Quest> _weeklyQuests = [
    Quest(
      id: 'read_100_pages',
      title: 'Century Club',
      description: 'Read 100 pages this week',
      icon: '💯',
      xpReward: 150,
      targetValue: 100,
      unit: 'pages',
    ),
    Quest(
      id: 'read_5_days',
      title: 'Dedicated Reader',
      description: 'Read on 5 different days',
      icon: '📅',
      xpReward: 100,
      targetValue: 5,
      unit: 'days',
    ),
    Quest(
      id: 'read_3_hours',
      title: 'Marathon Reader',
      description: 'Read for 3 hours total',
      icon: '⏱️',
      xpReward: 200,
      targetValue: 3,
      unit: 'hours',
    ),
  ];

  // Achievements/Milestones
  final List<Achievement> _achievements = [
    Achievement(
      id: 'first_book',
      title: 'First Steps',
      description: 'Finish your first book',
      icon: '🎉',
      requirement: 1,
      type: AchievementType.booksFinished,
    ),
    Achievement(
      id: 'streak_7',
      title: 'Week Warrior',
      description: 'Maintain a 7-day streak',
      icon: '🔥',
      requirement: 7,
      type: AchievementType.streak,
    ),
    Achievement(
      id: 'streak_30',
      title: 'Monthly Master',
      description: 'Maintain a 30-day streak',
      icon: '👑',
      requirement: 30,
      type: AchievementType.streak,
    ),
    Achievement(
      id: 'xp_500',
      title: 'Rising Star',
      description: 'Earn 500 XP',
      icon: '⭐',
      requirement: 500,
      type: AchievementType.xp,
    ),
    Achievement(
      id: 'xp_5000',
      title: 'Legend',
      description: 'Earn 5,000 XP',
      icon: '🏆',
      requirement: 5000,
      type: AchievementType.xp,
    ),
    Achievement(
      id: 'pages_1000',
      title: 'Bookworm',
      description: 'Read 1,000 pages',
      icon: '📚',
      requirement: 1000,
      type: AchievementType.pagesRead,
    ),
    Achievement(
      id: 'books_5',
      title: 'Avid Reader',
      description: 'Finish 5 books',
      icon: '📖',
      requirement: 5,
      type: AchievementType.booksFinished,
    ),
    Achievement(
      id: 'books_10',
      title: 'Bibliophile',
      description: 'Finish 10 books',
      icon: '🎓',
      requirement: 10,
      type: AchievementType.booksFinished,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final res = await _api.getReadingStats();
      if (res.statusCode == 200 && mounted) {
        setState(() {
          _stats = ReadingStats.fromJson(res.data);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.emerald))
                : RefreshIndicator(
                    color: AppColors.emerald,
                    onRefresh: _loadData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProgressCard(),
                          const SizedBox(height: 24),
                          _buildSectionHeader('Daily Quests', '🎯', 'Resets at midnight'),
                          const SizedBox(height: 12),
                          ..._dailyQuests.map((q) => _QuestCard(quest: q, stats: _stats)),
                          const SizedBox(height: 24),
                          _buildSectionHeader('Weekly Challenges', '🏅', 'Resets on Monday'),
                          const SizedBox(height: 12),
                          ..._weeklyQuests.map((q) => _QuestCard(quest: q, stats: _stats)),
                          const SizedBox(height: 24),
                          _buildSectionHeader('Achievements', '🏆', '${_getUnlockedCount()} of ${_achievements.length} unlocked'),
                          const SizedBox(height: 12),
                          _buildAchievementsGrid(),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppColors.ink,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 8,
        right: 16,
        bottom: 14,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Quests & Achievements',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Text('⭐', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  '${_stats?.totalXp ?? 0} XP',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    final streak = _stats?.currentStreak ?? 0;
    final booksFinished = _stats?.booksFinished ?? 0;
    final totalXp = _stats?.totalXp ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text('🎮', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Journey',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Complete quests to earn XP and badges',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _ProgressStat(icon: '🔥', value: '$streak', label: 'Day Streak'),
              _ProgressStat(icon: '📚', value: '$booksFinished', label: 'Books Done'),
              _ProgressStat(icon: '⭐', value: _formatXp(totalXp), label: 'Total XP'),
            ],
          ),
        ],
      ),
    );
  }

  String _formatXp(int xp) {
    if (xp >= 1000) {
      return '${(xp / 1000).toStringAsFixed(1)}k';
    }
    return xp.toString();
  }

  Widget _buildSectionHeader(String title, String emoji, String subtitle) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  int _getUnlockedCount() {
    int count = 0;
    for (final achievement in _achievements) {
      if (achievement.isUnlocked(_stats)) count++;
    }
    return count;
  }

  Widget _buildAchievementsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _achievements.length,
      itemBuilder: (context, index) {
        return _AchievementCard(
          achievement: _achievements[index],
          stats: _stats,
        );
      },
    );
  }
}

class _ProgressStat extends StatelessWidget {
  final String icon;
  final String value;
  final String label;

  const _ProgressStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Quest {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int xpReward;
  final int targetValue;
  final String unit;

  Quest({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.xpReward,
    required this.targetValue,
    required this.unit,
  });

  double getProgress(ReadingStats? stats) {
    if (stats == null) return 0.0;
    
    switch (id) {
      case 'read_15_min':
        return (stats.totalTimeHours * 60 % 60) / targetValue;
      case 'read_10_pages':
        return 0.3; // Would need daily tracking
      case 'maintain_streak':
        return stats.currentStreak > 0 ? 1.0 : 0.0;
      case 'read_100_pages':
        return 0.4; // Would need weekly tracking
      case 'read_5_days':
        return stats.currentStreak.clamp(0, 5) / targetValue;
      case 'read_3_hours':
        return (stats.totalTimeHours % 10) / targetValue;
      default:
        return 0.0;
    }
  }

  bool isCompleted(ReadingStats? stats) => getProgress(stats) >= 1.0;
}

class _QuestCard extends StatelessWidget {
  final Quest quest;
  final ReadingStats? stats;

  const _QuestCard({required this.quest, this.stats});

  @override
  Widget build(BuildContext context) {
    final progress = quest.getProgress(stats).clamp(0.0, 1.0);
    final isCompleted = progress >= 1.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompleted ? AppColors.emeraldSoft : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: isCompleted 
            ? Border.all(color: AppColors.emerald.withOpacity(0.3))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isCompleted 
                  ? AppColors.emerald.withOpacity(0.15) 
                  : AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                isCompleted ? '✅' : quest.icon,
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        quest.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isCompleted ? AppColors.emerald : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '+${quest.xpReward} XP',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  quest.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: isCompleted 
                        ? AppColors.emerald.withOpacity(0.2)
                        : const Color(0xFFE5E7EB),
                    valueColor: AlwaysStoppedAnimation(
                      isCompleted ? AppColors.emerald : AppColors.emerald,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum AchievementType { streak, xp, pagesRead, booksFinished }

class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int requirement;
  final AchievementType type;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.requirement,
    required this.type,
  });

  bool isUnlocked(ReadingStats? stats) {
    if (stats == null) return false;
    
    switch (type) {
      case AchievementType.streak:
        return stats.currentStreak >= requirement;
      case AchievementType.xp:
        return stats.totalXp >= requirement;
      case AchievementType.pagesRead:
        return false; // Would need total pages tracking
      case AchievementType.booksFinished:
        return stats.booksFinished >= requirement;
    }
  }

  double getProgress(ReadingStats? stats) {
    if (stats == null) return 0.0;
    
    switch (type) {
      case AchievementType.streak:
        return (stats.currentStreak / requirement).clamp(0.0, 1.0);
      case AchievementType.xp:
        return (stats.totalXp / requirement).clamp(0.0, 1.0);
      case AchievementType.pagesRead:
        return 0.0;
      case AchievementType.booksFinished:
        return (stats.booksFinished / requirement).clamp(0.0, 1.0);
    }
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final ReadingStats? stats;

  const _AchievementCard({required this.achievement, this.stats});

  @override
  Widget build(BuildContext context) {
    final isUnlocked = achievement.isUnlocked(stats);
    final progress = achievement.getProgress(stats);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isUnlocked ? AppColors.goldSoft : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: isUnlocked 
            ? Border.all(color: AppColors.gold.withOpacity(0.3))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isUnlocked 
                      ? AppColors.gold.withOpacity(0.2)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    isUnlocked ? achievement.icon : '🔒',
                    style: TextStyle(
                      fontSize: isUnlocked ? 18 : 14,
                    ),
                  ),
                ),
              ),
              if (isUnlocked) ...[
                const Spacer(),
                const Icon(
                  Icons.check_circle,
                  color: AppColors.gold,
                  size: 20,
                ),
              ],
            ],
          ),
          const Spacer(),
          Text(
            achievement.title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isUnlocked ? AppColors.gold : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            achievement.description,
            style: TextStyle(
              fontSize: 10,
              color: isUnlocked ? AppColors.textSecondary : AppColors.textMuted,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (!isUnlocked) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: const Color(0xFFE5E7EB),
                valueColor: const AlwaysStoppedAnimation(AppColors.textMuted),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
