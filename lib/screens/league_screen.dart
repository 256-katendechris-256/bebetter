import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/leaderboard.dart';
import '../models/reading_stats.dart';
import '../services/api_service.dart';

class LeagueScreen extends StatefulWidget {
  final ReadingStats? stats;
  final VoidCallback onRefresh;

  const LeagueScreen({
    super.key,
    this.stats,
    required this.onRefresh,
  });

  @override
  State<LeagueScreen> createState() => _LeagueScreenState();
}

class _LeagueScreenState extends State<LeagueScreen> with SingleTickerProviderStateMixin {
  final _api = ApiService();
  
  LeaderboardResponse? _leaderboard;
  MyRankResponse? _myRank;
  bool _loading = true;
  String? _error;
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _api.getLeaderboard(limit: 50),
        _api.getMyRank(),
      ]);

      if (!mounted) return;

      final leaderboardRes = results[0];
      final myRankRes = results[1];

      setState(() {
        if (leaderboardRes.statusCode == 200) {
          _leaderboard = LeaderboardResponse.fromJson(leaderboardRes.data);
        }
        if (myRankRes.statusCode == 200) {
          _myRank = MyRankResponse.fromJson(myRankRes.data);
        }
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load leaderboard';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.emerald,
      onRefresh: () async {
        await _loadData();
        widget.onRefresh();
      },
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.emerald))
          : _error != null
              ? _buildError()
              : CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader()),
                    SliverToBoxAdapter(child: _buildMyPosition()),
                    SliverToBoxAdapter(child: _buildTabBar()),
                    SliverToBoxAdapter(child: _buildLeaderboardList()),
                  ],
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(_error!, style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.emerald),
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final stats = widget.stats;
    
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A5F), Color(0xFF0D1B2A)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D1B2A).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text('🏆', style: TextStyle(fontSize: 28)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Diamond League',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_leaderboard?.totalParticipants ?? 0} active readers',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.7),
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
              _StatBadge(
                icon: '⭐',
                value: '${stats?.totalXp ?? 0}',
                label: 'Your XP',
                color: Colors.amber,
              ),
              const SizedBox(width: 12),
              _StatBadge(
                icon: '🔥',
                value: '${stats?.currentStreak ?? 0}',
                label: 'Streak',
                color: Colors.orange,
              ),
              const SizedBox(width: 12),
              _StatBadge(
                icon: '📚',
                value: '${stats?.booksFinished ?? 0}',
                label: 'Books',
                color: AppColors.emerald,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMyPosition() {
    final rank = _myRank?.rank ?? _leaderboard?.currentUserRank;
    final xpToNext = _myRank?.xpToNextRank ?? 0;

    if (rank == null) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.goldSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gold.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.emoji_events_outlined, color: AppColors.gold),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Start reading to join!',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Read your first pages to appear on the leaderboard',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.emerald.withOpacity(0.1), AppColors.emeraldSoft],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.emerald.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.emerald,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.emerald.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '#$rank',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Position',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                if (xpToNext > 0) ...[
                  Text(
                    '$xpToNext XP to next rank',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: 0.7,
                      minHeight: 6,
                      backgroundColor: Colors.white,
                      valueColor: const AlwaysStoppedAnimation(AppColors.emerald),
                    ),
                  ),
                ] else
                  const Text(
                    'You\'re at the top! 🎉',
                    style: TextStyle(fontSize: 12, color: AppColors.emerald, fontWeight: FontWeight.w600),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        onTap: (_) => setState(() {}),
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        dividerColor: Colors.transparent,
        labelColor: AppColors.textPrimary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        tabs: const [
          Tab(text: 'Top Readers'),
          Tab(text: 'Near You'),
        ],
      ),
    );
  }

  Widget _buildLeaderboardList() {
    final entries = _tabController.index == 0
        ? _leaderboard?.leaderboard ?? []
        : _buildNearbyList();

    if (entries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.people_outline, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No readers yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Be the first to join!',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        children: [
          // Top 3 podium for first tab
          if (_tabController.index == 0 && entries.length >= 3) ...[
            _buildPodium(entries.take(3).toList()),
            const SizedBox(height: 20),
          ],
          
          // Rest of the list
          ...entries.skip(_tabController.index == 0 ? 3 : 0).map((entry) => 
            _LeaderboardCard(entry: entry),
          ),
        ],
      ),
    );
  }

  List<LeaderboardEntry> _buildNearbyList() {
    final List<LeaderboardEntry> nearby = [];
    if (_myRank != null) {
      nearby.addAll(_myRank!.above.reversed);
      
      // Add current user
      final currentUserEntry = _leaderboard?.leaderboard.where((e) => e.isCurrentUser).firstOrNull ??
          _leaderboard?.currentUserEntry;
      if (currentUserEntry != null) {
        nearby.add(currentUserEntry);
      }
      
      nearby.addAll(_myRank!.below);
    }
    return nearby;
  }

  Widget _buildPodium(List<LeaderboardEntry> top3) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (top3.length > 1) _PodiumPlace(entry: top3[1], place: 2),
        _PodiumPlace(entry: top3[0], place: 1),
        if (top3.length > 2) _PodiumPlace(entry: top3[2], place: 3),
      ],
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String icon;
  final String value;
  final String label;
  final Color color;

  const _StatBadge({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PodiumPlace extends StatelessWidget {
  final LeaderboardEntry entry;
  final int place;

  const _PodiumPlace({required this.entry, required this.place});

  @override
  Widget build(BuildContext context) {
    final isFirst = place == 1;
    final height = isFirst ? 120.0 : (place == 2 ? 100.0 : 80.0);
    final medal = place == 1 ? '🥇' : (place == 2 ? '🥈' : '🥉');
    final color = place == 1
        ? Colors.amber
        : (place == 2 ? Colors.grey.shade400 : Colors.orange.shade300);

    return Container(
      width: isFirst ? 110 : 90,
      margin: EdgeInsets.symmetric(horizontal: isFirst ? 8 : 4),
      child: Column(
        children: [
          Container(
            width: isFirst ? 64 : 52,
            height: isFirst ? 64 : 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: entry.isCurrentUser ? AppColors.emerald : color.withOpacity(0.2),
              border: Border.all(color: color, width: 3),
              boxShadow: isFirst
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                entry.displayName[0].toUpperCase(),
                style: TextStyle(
                  fontSize: isFirst ? 24 : 20,
                  fontWeight: FontWeight.w800,
                  color: entry.isCurrentUser ? Colors.white : color,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(medal, style: TextStyle(fontSize: isFirst ? 24 : 20)),
          const SizedBox(height: 4),
          Text(
            entry.displayName,
            style: TextStyle(
              fontSize: isFirst ? 13 : 11,
              fontWeight: FontWeight.w700,
              color: entry.isCurrentUser ? AppColors.emerald : AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          Text(
            '${entry.totalXp} XP',
            style: TextStyle(
              fontSize: isFirst ? 12 : 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color.withOpacity(0.8), color],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Center(
              child: Text(
                '#$place',
                style: TextStyle(
                  fontSize: isFirst ? 20 : 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardCard extends StatelessWidget {
  final LeaderboardEntry entry;

  const _LeaderboardCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isYou = entry.isCurrentUser;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isYou ? AppColors.emeraldSoft : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: isYou ? Border.all(color: AppColors.emerald.withOpacity(0.3)) : null,
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
          SizedBox(
            width: 32,
            child: Text(
              '#${entry.rank}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: isYou ? AppColors.emerald : AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isYou ? AppColors.emerald.withOpacity(0.15) : const Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                entry.displayName[0].toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: isYou ? AppColors.emerald : AppColors.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isYou ? '${entry.displayName} (you)' : entry.displayName,
                  style: TextStyle(
                    fontWeight: isYou ? FontWeight.w700 : FontWeight.w600,
                    fontSize: 14,
                    color: isYou ? AppColors.emerald : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (entry.currentStreak > 0) ...[
                      const Text('🔥', style: TextStyle(fontSize: 11)),
                      const SizedBox(width: 2),
                      Text(
                        '${entry.currentStreak}',
                        style: TextStyle(fontSize: 11, color: Colors.orange.shade600),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      '${entry.totalPagesRead} pages',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isYou ? AppColors.emerald : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${entry.totalXp} XP',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: isYou ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
