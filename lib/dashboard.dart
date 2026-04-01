import 'dart:async';
import 'package:bbeta/Auth/auth_service.dart';
import 'package:bbeta/models/reading_stats.dart';
import 'package:bbeta/screens/bookstore_home_screen.dart';
import 'package:bbeta/screens/league_screen.dart';
import 'package:bbeta/screens/my_list_screen.dart';
import 'package:bbeta/screens/quest_screen.dart';
import 'package:bbeta/services/api_service.dart';
import 'package:bbeta/services/cache_service.dart';
import 'package:bbeta/services/download_service.dart';
import 'package:bbeta/splash_screen.dart';
import 'package:bbeta/screens/book_reader_screen.dart';
import 'package:bbeta/screens/notifications_screen.dart';
import 'package:bbeta/screens/notification_preferences_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../widgets/quote_carousel.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
const Color kInk         = Color(0xFF0D1B2A); // top bar + nav bar
const Color kEmerald     = Color(0xFF059669); // primary accent
const Color kEmeraldSoft = Color(0xFFECFDF5);
const Color kGold        = Color(0xFFF59E0B);
const Color kGoldSoft    = Color(0xFFFFFBEB);
const Color kRed         = Color(0xFFEF4444);
const Color kSurface     = Color(0xFFFFFFFF);
const Color kBg          = Color(0xFFF4F6F8); // slightly cooler grey page bg
const Color kShadow      = Color(0x0D000000); // 5 % black — soft shadow
const Color kTextPrimary   = Color(0xFF111827);
const Color kTextSecondary = Color(0xFF6B7280);
const Color kTextMuted     = Color(0xFF9CA3AF);

// No borders anywhere — depth comes from shadow only
BoxDecoration _card({double radius = 16, Color? color}) => BoxDecoration(
  color       : color ?? kSurface,
  borderRadius: BorderRadius.circular(radius),
  boxShadow   : const [
    BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 3)),
    BoxShadow(color: Color(0x06000000), blurRadius: 4,  offset: Offset(0, 1)),
  ],
);

// ─── Quotes ──────────────────────────────────────────────────────────────────
const _quotes = [
  {'text': 'A reader lives a thousand lives before he dies. The man who never reads lives only one.', 'author': 'George R.R. Martin', 'book': 'A Dance with Dragons'},
  {'text': 'Not all those who wander are lost.', 'author': 'J.R.R. Tolkien', 'book': 'The Fellowship of the Ring'},
  {'text': 'It is our choices, far more than our abilities, that show what we truly are.', 'author': 'J.K. Rowling', 'book': 'Harry Potter and the Chamber of Secrets'},
  {'text': 'Until I feared I would lose it, I never loved to read. One does not love breathing.', 'author': 'Harper Lee', 'book': 'To Kill a Mockingbird'},
];

const _leaderboardData = [
  {'name': 'Sarah K.',        'xp': '1,240', 'you': 'false'},
  {'name': 'Moses A.',        'xp': '980',   'you': 'false'},
  {'name': 'Brian M.',        'xp': '870',   'you': 'false'},
  {'name': 'katendechris511', 'xp': '490',   'you': 'true'},
  {'name': 'Grace N.',        'xp': '410',   'you': 'false'},
];

// ═════════════════════════════════════════════════════════════════════════════
// DASHBOARD
// ═════════════════════════════════════════════════════════════════════════════

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _currentIndex = 0;

  final _api         = ApiService();
  final _authService = AuthService();
  final _cache       = CacheService();

  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _stats;
  ReadingStats? _readingStats;
  List<dynamic> _currentlyReading = [];
  List<dynamic> _books             = [];
  List<dynamic> _filteredBooks     = [];
  List<Map<String, dynamic>>  _myList =[];
  List<Map<String, dynamic>>  _readBooks =[];
  String _searchQuery = '';
  bool _loadingHome    = true;
  bool _loadingLibrary = true;
  Set<int> _bookmarkedBooks = {};
  int _unreadCount = 0;
  
  bool _isOffline = false;
  String _lastSyncText = '';
  late StreamSubscription<List<ConnectivityResult>> _connectivitySub;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
    _loadCachedData();
    _loadHomeData();
    _loadLibraryData();
    _loadUnreadCount();
    Stream.periodic(const Duration(seconds: 60))
        .listen((_) { if (mounted) _loadUnreadCount(); });
  }
  
  @override
  void dispose() {
    _connectivitySub.cancel();
    super.dispose();
  }
  
  Future<void> _initConnectivity() async {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final offline = results.isEmpty || 
          results.every((r) => r == ConnectivityResult.none);
      if (mounted && _isOffline != offline) {
        setState(() => _isOffline = offline);
        if (!offline) {
          _loadHomeData();
          _loadLibraryData();
        }
      }
    });
    
    final results = await Connectivity().checkConnectivity();
    if (mounted) {
      setState(() {
        _isOffline = results.isEmpty || 
            results.every((r) => r == ConnectivityResult.none);
      });
    }
  }
  
  Future<void> _loadCachedData() async {
    final cachedProfile = await _cache.getCachedProfile();
    final cachedStats = await _cache.getCachedStats();
    final cachedReading = await _cache.getCachedCurrentlyReading();
    final cachedBooks = await _cache.getCachedBooks();
    final lastSync = await _cache.getLastSyncText();
    
    if (mounted) {
      setState(() {
        if (cachedProfile != null) _profile = cachedProfile;
        if (cachedStats != null) {
          _stats = cachedStats;
          _readingStats = ReadingStats.fromJson(cachedStats);
        }
        if (cachedReading != null) _currentlyReading = cachedReading;
        if (cachedBooks != null) {
          _books = cachedBooks;
          _filteredBooks = cachedBooks;
        }
        _lastSyncText = lastSync;
      });
    }
  }

  Future<void> _loadUnreadCount() async {
    try {
      final res = await _api.getUnreadCount();
      if (res.statusCode == 200 && mounted) {
        setState(() => _unreadCount = res.data['unread'] ?? 0);
      }
    } catch (_) {}
  }

  Future<void> _loadHomeData() async {
    setState(() => _loadingHome = true);
    try {
      final results = await Future.wait([
        _authService.getProfile(),
        _api.getReadingStats(),
        _api.getCurrentlyReading(),
      ]);
      if (!mounted) return;
      
      final profile = results[0] as Map<String, dynamic>?;
      final statsResponse = results[1] as Response;
      final readingResponse = results[2] as Response;
      
      setState(() {
        _profile = profile;
        if (statsResponse.statusCode == 200) {
          _stats = statsResponse.data;
          _readingStats = ReadingStats.fromJson(statsResponse.data as Map<String, dynamic>);
        }
        if (readingResponse.statusCode == 200) {
          _currentlyReading = readingResponse.data as List? ?? [];
        }
      });
      
      // Cache data for offline use
      if (profile != null) await _cache.cacheProfile(profile);
      if (statsResponse.statusCode == 200) {
        await _cache.cacheStats(statsResponse.data as Map<String, dynamic>);
      }
      if (readingResponse.statusCode == 200) {
        await _cache.cacheCurrentlyReading(_currentlyReading);
      }
      
      final lastSync = await _cache.getLastSyncText();
      if (mounted) setState(() => _lastSyncText = lastSync);
      
    } catch (e) {
      // If online request fails, we already have cached data loaded
      debugPrint('Load home data error: $e');
    }
    if (mounted) setState(() => _loadingHome = false);
  }

  Future<void> _loadLibraryData() async {
    setState(() => _loadingLibrary = true);
    try {
      final res = await _api.getBooks();
      if (res.statusCode == 200 && mounted) {
        List<dynamic> books = [];
        if (res.data is Map) {
          books = (res.data['results'] as List?) ??
              (res.data is List ? res.data as List : []);
        } else if (res.data is List) {
          books = res.data as List;
        }
        if (mounted) setState(() { _books = books; _filteredBooks = books; });
        
        // Cache books for offline use
        await _cache.cacheBooks(books);
      }
    } catch (e) {
      debugPrint('Load library data error: $e');
    }
    if (mounted) setState(() => _loadingLibrary = false);
  }

  String get _displayName {
    if (_profile == null) return 'Reader';
    final first    = _profile!['first_name']?.toString() ?? '';
    final username = _profile!['username']?.toString()   ?? '';
    final email    = _profile!['email']?.toString()      ?? '';
    if (first.isNotEmpty)    return first;
    if (username.isNotEmpty) return username;
    if (email.isNotEmpty)    return email.split('@').first;
    return 'Reader';
  }

  void _filterBooks(String q) {
    setState(() {
      _searchQuery   = q;
      _filteredBooks = q.isEmpty
          ? _books
          : _books.where((b) {
        final t = (b['title']  ?? '').toString().toLowerCase();
        final a = (b['author'] ?? '').toString().toLowerCase();
        return t.contains(q.toLowerCase()) || a.contains(q.toLowerCase());
      }).toList();
    });
  }

  void _toggleBookmark(Map<String, dynamic> book) {
    setState(() {
      final exists = _myList.any((b) => b['id'] == book['id']);

      if (exists) {
        _myList.removeWhere((b) => b['id'] == book['id']);
      } else {
        _myList.add(book);
      }
    });
  }

  Future<void> _handleLogout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
          (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor         : kInk,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          _TopBar(
            displayName      : _displayName,
            streak           : _stats?['current_streak'] ?? 0,
            streakLit        : (_stats?['current_streak'] ?? 0) > 0,
            unreadCount      : _unreadCount,
            onAvatarTap      : () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => SettingsPage(
                  displayName: _displayName,
                  email      : _profile?['email'] ?? '',
                  onLogout   : _handleLogout,
                ))),
            onNotificationTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()))
                .then((_) => _loadUnreadCount()),
            onSearchTap      : () {},
          ),
          if (_isOffline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: kGold.withOpacity(0.9),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You\'re offline. Showing cached data ($_lastSyncText)',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                _buildHome(),
                LeagueScreen(
                  stats: _readingStats,
                  onRefresh: _loadHomeData,
                ),
                _buildLibrary(),
                _buildChat(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }

  // ══ HOME ══════════════════════════════════════════════════════════════════

  Widget _buildHome() {
    return RefreshIndicator(
      color    : kEmerald,
      onRefresh: _loadHomeData,
      child    : SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child  : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const
            QuoteCarousel(),
            const SizedBox(height: 24),
            //const _QuickIcons(),
            _QuickIconsRow(
              onQuestTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QuestScreen()),
              ),
              onMyListTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MyListScreen(
                    savedBooks: _myList,
                    currentlyReading: _currentlyReading,
                    finishedBooks: _readBooks,
                    onToggleBookmark: _toggleBookmark,
                    onMarkAsRead: _markAsRead,
                  ),
                ),
              ).then((_) => setState(() {})),
              onBookstoreTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BookstoreHomeScreen()),
              ).then((_) => setState(() {})),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Currently Reading',
                    style: TextStyle(
                        fontSize    : 20,
                        fontWeight  : FontWeight.w800,
                        color       : kTextPrimary,
                        letterSpacing: -0.4)),
                GestureDetector(
                  onTap: () => setState(() => _currentIndex = 2),
                  child: const Text('See all →',
                      style: TextStyle(
                          fontSize  : 13,
                          fontWeight: FontWeight.w600,
                          color     : kEmerald)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_loadingHome)
              const Center(child: Padding(
                padding: EdgeInsets.all(32),
                child  : CircularProgressIndicator(color: kEmerald),
              ))
            else if (_currentlyReading.isEmpty)
              _EmptyState(
                icon : Icons.auto_stories_outlined,
                title: 'Nothing in progress',
                sub  : 'Head to the Library and start your first book.',
                onTap: () => setState(() => _currentIndex = 2),
              )
            else
              ..._currentlyReading.map((ub) {
                final book     = ub['book']             ?? {};
                final progress = ub['progress_percent'] ?? 0;
                return GestureDetector(
                  onTap: () {
                    final id = book['id'];
                    if (id == null) return;
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => BookReaderScreen(
                        bookId    : id,
                        bookTitle : book['title']   ?? 'Untitled',
                        authors   : (book['author'] ?? '').toString(),
                        coverImage: book['cover_url'],
                        initialPage: (ub['current_page'] ?? 1) as int,
                      ),
                    ));
                  },
                  child: _ReadingCard(
                    title      : book['title']      ?? 'Untitled',
                    author     : book['author']     ?? '',
                    coverUrl   : book['cover_url'],
                    progress   : (progress is num ? progress.toDouble() : 0) / 100,
                    currentPage: ub['current_page'] ?? 0,
                    totalPages : book['total_pages'] ?? 0,
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  // ══ LEAGUE ════════════════════════════════════════════════════════════════

  Widget _buildLeague() {
    final totalXp    = _stats?['total_xp']          ?? 0;
    final streak     = _stats?['current_streak']    ?? 0;
    final booksRead  = _stats?['books_finished']    ?? 0;
    final totalHours = (_stats?['total_time_hours'] ?? 0.0).toStringAsFixed(1);

    return RefreshIndicator(
      color    : kEmerald,
      onRefresh: _loadHomeData,
      child    : SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child  : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatsHero(
              totalXp   : totalXp,
              streak    : streak,
              booksRead : booksRead,
              totalHours: totalHours,
            ),
            const SizedBox(height: 28),
            const Text('Diamond League',
                style: TextStyle(
                    fontSize    : 20,
                    fontWeight  : FontWeight.w800,
                    color       : kTextPrimary,
                    letterSpacing: -0.4)),
            const SizedBox(height: 4),
            const Text('Top readers this week',
                style: TextStyle(fontSize: 13, color: kTextSecondary)),
            const SizedBox(height: 16),
            ..._leaderboardData.asMap().entries.map((e) =>
                _LeaderboardRow(
                  rank : e.key + 1,
                  name : e.value['name']!,
                  xp   : e.value['xp']!,
                  isYou: e.value['you'] == 'true',
                )),
          ],
        ),
      ),
    );
  }

  // ══ LIBRARY ═══════════════════════════════════════════════════════════════

  Widget _buildLibrary() {
    return RefreshIndicator(
      color    : kEmerald,
      onRefresh: _loadLibraryData,
      child    : _loadingLibrary
          ? const Center(child: CircularProgressIndicator(color: kEmerald))
          : _books.isEmpty
          ? _buildEmptyLibrary()
          : CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Library',
                      style: TextStyle(
                          fontSize    : 24,
                          fontWeight  : FontWeight.w800,
                          color       : kTextPrimary,
                          letterSpacing: -0.4)),
                  const SizedBox(height: 14),
                  _SearchBar(
                    query    : _searchQuery,
                    onChanged: _filterBooks,
                    onClear  : () => _filterBooks(''),
                  ),
                  if (_filteredBooks.length != _books.length)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                          '${_filteredBooks.length} of ${_books.length} books',
                          style: const TextStyle(fontSize: 12, color: kTextMuted)),
                    ),
                ],
              ),
            ),
          ),
          if (_filteredBooks.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: _EmptyState(
                  icon : Icons.search_off_rounded,
                  title: 'No results',
                  sub  : 'Try a different search term.',
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              sliver : SliverList(
                delegate: SliverChildBuilderDelegate(
                      (_, i) {
                    final book = _filteredBooks[i];
                    return _LibraryBookCard(
                      book         : book,
                      isBookmarked : _myList.any((b) => b['id'] == book['id']),
                      onBookmarkTap: () => _toggleBookmark(book),
                    );
                  },
                  childCount: _filteredBooks.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyLibrary() => SingleChildScrollView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
    child  : Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Library',
            style: TextStyle(
                fontSize  : 24,
                fontWeight: FontWeight.w800,
                color     : kTextPrimary)),
        SizedBox(height: MediaQuery.of(context).size.height * 0.22),
        const Center(
          child: _EmptyState(
            icon : Icons.menu_book_outlined,
            title: 'No books yet',
            sub  : 'Books added to the club will appear here.',
          ),
        ),
      ],
    ),
  );

  Widget _buildChat() => const Center(
    child: _EmptyState(
      icon : Icons.chat_bubble_outline_rounded,
      title: 'Chat coming soon',
      sub  : 'Real-time club discussions are on the way.',
    ),
  );

  void _markAsRead(Map<String, dynamic> book) {
    setState(() {
      _readBooks.add(book);
      _myList.removeWhere((b)=> b['id'] == book['id']);
    });
  }
}

class _QuickIconsRow extends StatelessWidget {
  final VoidCallback onQuestTap;
  final VoidCallback onMyListTap;
  final VoidCallback onBookstoreTap;
  
  const _QuickIconsRow({
    required this.onQuestTap,
    required this.onMyListTap,
    required this.onBookstoreTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Expanded(child: _QITile(item: const _QI(emoji: '🎯', label: 'Quest', dot: false), onTap: onQuestTap)),
          const SizedBox(width: 8),
          Expanded(child: _QITile(item: const _QI(emoji: '📚', label: 'My list', dot: false), onTap: onMyListTap)),
          const SizedBox(width: 8),
          Expanded(child: _QITile(item: const _QI(emoji: '🛒', label: 'BookStore', dot: false), onTap: onBookstoreTap)),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TOP BAR
// ═════════════════════════════════════════════════════════════════════════════

class _TopBar extends StatelessWidget {
  final String       displayName;
  final int          streak;
  final bool         streakLit;
  final int          unreadCount;
  final VoidCallback onAvatarTap;
  final VoidCallback onNotificationTap;
  final VoidCallback onSearchTap;

  const _TopBar({
    required this.displayName,
    required this.streak,
    required this.streakLit,
    required this.unreadCount,
    required this.onAvatarTap,
    required this.onNotificationTap,
    required this.onSearchTap,
  });

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning,';
    if (h < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  @override
  Widget build(BuildContext context) => Container(
    color  : kInk,
    padding: EdgeInsets.only(
      top   : MediaQuery.of(context).padding.top + 12,
      left  : 18,
      right : 10,
      bottom: 14,
    ),
    child: Row(
      children: [
        // Avatar → Settings
        GestureDetector(
          onTap: onAvatarTap,
          child: Container(
            width : 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kEmerald.withOpacity(0.15),
              border: Border.all(color: kEmerald.withOpacity(0.4), width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(
              displayName[0].toUpperCase(),
              style: const TextStyle(
                  fontSize  : 18,
                  fontWeight: FontWeight.w800,
                  color     : Colors.white),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Greeting + name
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize      : MainAxisSize.min,
            children: [
              Text(_greeting(),
                  style: TextStyle(
                      fontSize : 11,
                      color    : kEmerald.withOpacity(0.8),
                      fontStyle: FontStyle.italic)),
              Text(displayName,
                  style: const TextStyle(
                      fontSize    : 16,
                      fontWeight  : FontWeight.w800,
                      color       : Colors.white,
                      letterSpacing: -0.4),
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        // ── Streak flame ──────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child  : Opacity(
            opacity: streakLit ? 1.0 : 0.3, // dim when not yet earned today
            child  : Column(
              mainAxisSize: MainAxisSize.min,
              children    : [
                const Text('🔥', style: TextStyle(fontSize: 22)),
                Text(
                  '$streak',
                  style: TextStyle(
                    fontSize  : 11,
                    fontWeight: FontWeight.w800,
                    color     : streakLit
                        ? const Color(0xFFFB923C)
                        : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        _TBtn(icon: Icons.notifications_outlined, badgeCount: unreadCount, onTap: onNotificationTap),
        _TBtn(icon: Icons.search_rounded, onTap: onSearchTap),
      ],
    ),
  );
}

class _TBtn extends StatelessWidget {
  final IconData     icon;
  final int          badgeCount;
  final VoidCallback onTap;
  const _TBtn({required this.icon, this.badgeCount = 0, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width : 42,
      height: 42,
      margin: const EdgeInsets.only(left: 6),
      decoration: BoxDecoration(
        color       : Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 22),
          if (badgeCount > 0)
            Positioned(
              top: 6, right: 6,
              child: Container(
                padding   : const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color : kRed,
                  shape : BoxShape.circle,
                  border: Border.all(color: kInk, width: 1.5),
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  badgeCount > 99 ? '99+' : '$badgeCount',
                  style: const TextStyle(
                    color     : Colors.white,
                    fontSize  : 9,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// QUOTE CAROUSEL
// ═════════════════════════════════════════════════════════════════════════════

class _QuoteCarousel extends StatefulWidget {
  const _QuoteCarousel();
  @override
  State<_QuoteCarousel> createState() => _QuoteCarouselState();
}

class _QuoteCarouselState extends State<_QuoteCarousel> {
  final _ctrl = PageController();
  int _page   = 0;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  // Dots row — reused inside each card
  Widget _dots() => Row(
    mainAxisSize: MainAxisSize.min,
    children    : List.generate(_quotes.length, (i) {
      final active = i == _page;
      return GestureDetector(
        onTap: () => _ctrl.animateToPage(i,
            duration: const Duration(milliseconds: 300),
            curve   : Curves.easeInOut),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width : active ? 20 : 6,
          height: 6,
          margin: EdgeInsets.only(left: i == 0 ? 0 : 5),
          decoration: BoxDecoration(
            color       : active
                ? kEmerald
                : Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      );
    }),
  );

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      boxShadow   : const [
        BoxShadow(color: Color(0x18000000), blurRadius: 20, offset: Offset(0, 6)),
      ],
    ),
    child: ClipRRect(
      // hard-clip so adjacent pages never bleed outside the card
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 210,
        child : PageView.builder(
          controller   : _ctrl,
          itemCount    : _quotes.length,
          onPageChanged: (i) => setState(() => _page = i),
          itemBuilder  : (_, i) {
            final q = _quotes[i];
            return Container(
              // no extra horizontal margin — one card fills 100 %
              decoration: const BoxDecoration(color: kInk),
              padding   : const EdgeInsets.fromLTRB(22, 20, 22, 18),
              child     : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── label row ──────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding  : const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color       : kEmerald.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('QUOTE OF THE DAY',
                            style: TextStyle(
                                color        : Color(0xFF6EE7B7),
                                fontSize     : 9,
                                fontWeight   : FontWeight.w700,
                                letterSpacing: 1.1)),
                      ),
                      Text('"',
                          style: TextStyle(
                              fontSize: 28,
                              color   : Colors.white.withOpacity(0.2),
                              height  : 1)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // ── quote text ─────────────────────────────────
                  Expanded(
                    child: Text(q['text']!,
                        style: const TextStyle(
                            color    : Colors.white,
                            fontSize : 14,
                            height   : 1.6,
                            fontStyle: FontStyle.italic),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(height: 10),
                  // ── author + dots on same row ──────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('— ${q['author']}',
                                style: TextStyle(
                                    color     : kEmerald.withOpacity(0.9),
                                    fontSize  : 12,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(q['book']!,
                                style: TextStyle(
                                    color  : Colors.white.withOpacity(0.3),
                                    fontSize: 11)),
                          ],
                        ),
                      ),
                      // ← dots live here, bottom-right of card
                      _dots(),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// QUICK ICONS  — shadow bg, no border
// ═════════════════════════════════════════════════════════════════════════════

class _QuickIcons extends StatelessWidget {
  const _QuickIcons();

  @override
  Widget build(BuildContext context) {
    const items = [
      _QI(emoji: '🎯', label: 'Quest',  dot: false),   // target — purposeful, no sword
      _QI(emoji: '📚', label: 'Booklist',  dot: false),
      _QI(emoji: '🛒', label: 'BookStore',  dot: false),
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: items.asMap().entries.map((e) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: e.key == 0 ? 0 : 8),
            child  : _QITile(item: e.value),
          ),
        )).toList(),
      ),
    );
  }
}

class _QI {
  final String emoji, label;
  final bool   dot;   // dark-green dot indicator instead of red badge
  const _QI({required this.emoji, required this.label, required this.dot});
}

class _QITile extends StatelessWidget {
  final _QI item;
  final VoidCallback? onTap;   // ← add this
  const _QITile({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,   // ← wire it here
    child: Stack(
      clipBehavior: Clip.none,
      children    : [
        Container(
          padding  : const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            color      : kSurface,
            borderRadius: BorderRadius.circular(14),
            boxShadow  : const [
              BoxShadow(color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, 3)),
              BoxShadow(color: Color(0x06000000), blurRadius: 3,  offset: Offset(0, 1)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(item.emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 5),
              Flexible(
                child: Text(item.label,
                    style: const TextStyle(
                        fontSize  : 12,
                        fontWeight: FontWeight.w600,
                        color     : kTextPrimary),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
        if (item.dot)
          Positioned(
            top  : -5,
            right: 0,
            child: Container(
              width : 9,
              height: 9,
              decoration: BoxDecoration(
                color : kEmerald,
                shape : BoxShape.circle,
                border: Border.all(color: kBg, width: 1.5),
              ),
            ),
          ),
      ],
    ),
  );
}
// ═════════════════════════════════════════════════════════════════════════════
// STATS HERO  (League tab)
// ═════════════════════════════════════════════════════════════════════════════

class _StatsHero extends StatelessWidget {
  final int totalXp, streak, booksRead;
  final String totalHours;
  const _StatsHero({
    required this.totalXp, required this.streak,
    required this.booksRead, required this.totalHours,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color      : kInk,
      borderRadius: BorderRadius.circular(20),
      boxShadow  : const [
        BoxShadow(color: Color(0x18000000), blurRadius: 20, offset: Offset(0, 6)),
      ],
    ),
    padding: const EdgeInsets.all(20),
    child  : Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children          : [
        Row(children: [
          const Text('📊 ', style: TextStyle(fontSize: 18)),
          const Text('Your Reading Stats',
              style: TextStyle(
                  color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color       : kEmerald.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('${totalHours}h read',
                style: TextStyle(
                    color     : kEmerald.withOpacity(0.9),
                    fontSize  : 11,
                    fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 18),
        Row(children: [
          _SP(value: '$totalXp',  label: 'XP Earned',  icon: '⭐', bg: kGoldSoft,    fg: kGold),
          const SizedBox(width: 10),
          _SP(value: '$streak',   label: 'Day Streak', icon: '🔥', bg: const Color(0xFFFFF7ED), fg: Colors.orange),
          const SizedBox(width: 10),
          _SP(value: '$booksRead',label: 'Books Read', icon: '📚', bg: kEmeraldSoft, fg: kEmerald),
        ]),
      ],
    ),
  );
}

class _SP extends StatelessWidget {
  final String value, label, icon;
  final Color bg, fg;
  const _SP({required this.value, required this.label, required this.icon, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding   : const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 5),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: fg)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: kTextSecondary)),
      ]),
    ),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// LEADERBOARD ROW
// ═════════════════════════════════════════════════════════════════════════════

class _LeaderboardRow extends StatelessWidget {
  final int rank;
  final String name, xp;
  final bool isYou;
  const _LeaderboardRow({required this.rank, required this.name, required this.xp, this.isYou = false});

  @override
  Widget build(BuildContext context) {
    final medal = rank == 1 ? '🥇' : rank == 2 ? '🥈' : rank == 3 ? '🥉' : null;
    return Container(
      margin    : const EdgeInsets.only(bottom: 8),
      padding   : const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: _card(
        radius: 14,
        color : isYou ? kEmeraldSoft : kSurface,
      ),
      child: Row(children: [
        SizedBox(
          width: 28,
          child: medal != null
              ? Text(medal, style: const TextStyle(fontSize: 18))
              : Text('$rank',
              style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 14,
                  color: isYou ? kEmerald : kTextMuted)),
        ),
        const SizedBox(width: 10),
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: isYou ? kEmerald.withOpacity(0.15) : const Color(0xFFF3F4F6),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(name[0].toUpperCase(),
              style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 14,
                  color: isYou ? kEmerald : kTextSecondary)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(isYou ? '$name (you)' : name,
              style: TextStyle(
                  fontWeight: isYou ? FontWeight.w700 : FontWeight.w500,
                  fontSize  : 14,
                  color     : isYou ? kEmerald : kTextPrimary)),
        ),
        Text('$xp XP',
            style: TextStyle(
                fontWeight: FontWeight.w700, fontSize: 13,
                color: isYou ? kEmerald : kTextSecondary)),
      ]),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// BOTTOM NAV  — charcoal background
// ═════════════════════════════════════════════════════════════════════════════

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.currentIndex, required this.onTap});

  static const _tabs = [
    (icon: Icons.home_rounded,         label: 'Home'),
    (icon: Icons.emoji_events_rounded, label: 'League'),
    (icon: Icons.menu_book_rounded,    label: 'Library'),
    (icon: Icons.chat_bubble_rounded,  label: 'Chat'),
  ];

  @override
  Widget build(BuildContext context) => Container(
    color  : kInk, // ← charcoal, matches top bar
    padding: EdgeInsets.only(
        top   : 10,
        bottom: MediaQuery.of(context).padding.bottom + 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children         : List.generate(_tabs.length, (i) {
        final active = i == currentIndex;
        return GestureDetector(
          onTap   : () => onTap(i),
          behavior: HitTestBehavior.opaque,
          child   : AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding : const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color       : active
                  ? kEmerald.withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children    : [
                Icon(_tabs[i].icon,
                    size : 24,
                    color: active ? kEmerald : Colors.white.withOpacity(0.35)),
                const SizedBox(height: 4),
                Text(_tabs[i].label,
                    style: TextStyle(
                        fontSize  : 11,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                        color     : active
                            ? kEmerald
                            : Colors.white.withOpacity(0.35))),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 4, width: active ? 4 : 0,
                  margin: const EdgeInsets.only(top: 3),
                  decoration: const BoxDecoration(color: kEmerald, shape: BoxShape.circle),
                ),
              ],
            ),
          ),
        );
      }),
    ),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// SETTINGS PAGE  — full screen, pushed via Navigator
// ═════════════════════════════════════════════════════════════════════════════

class SettingsPage extends StatelessWidget {
  final String       displayName;
  final String       email;
  final VoidCallback onLogout;

  const SettingsPage({
    super.key,
    required this.displayName,
    required this.email,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          // ── Custom header (charcoal) ────────────────────────────────
          Container(
            color  : kInk,
            padding: EdgeInsets.only(
              top   : MediaQuery.of(context).padding.top + 12,
              left  : 8,
              right : 18,
              bottom: 14,
            ),
            child: Row(
              children: [
                IconButton(
                  icon : const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Text('Settings',
                      style: TextStyle(
                          fontSize    : 18,
                          fontWeight  : FontWeight.w800,
                          color       : Colors.white,
                          letterSpacing: -0.3)),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Profile card ────────────────────────────────────
                  Container(
                    margin    : const EdgeInsets.only(bottom: 20),
                    padding   : const EdgeInsets.all(18),
                    decoration: _card(radius: 18),
                    child: Row(
                      children: [
                        Container(
                          width : 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: kEmerald.withOpacity(0.12),
                            border: Border.all(
                                color: kEmerald.withOpacity(0.3), width: 1.5),
                          ),
                          alignment: Alignment.center,
                          child: Text(displayName[0].toUpperCase(),
                              style: const TextStyle(
                                  fontSize  : 22,
                                  fontWeight: FontWeight.w800,
                                  color     : kEmerald)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(displayName,
                                  style: const TextStyle(
                                      fontSize  : 17,
                                      fontWeight: FontWeight.w800,
                                      color     : kTextPrimary)),
                              const SizedBox(height: 3),
                              Text(email,
                                  style: const TextStyle(
                                      fontSize: 13, color: kTextSecondary)),
                            ],
                          ),
                        ),
                        Icon(Icons.edit_outlined,
                            color: kTextMuted, size: 20),
                      ],
                    ),
                  ),

                  // ── Section: Preferences ───────────────────────────
                  _SectionLabel('Preferences'),
                  _SettingGroup(items: [
                    _SI(icon: Icons.notifications_outlined, label: 'Notifications & Reminders', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationPreferencesScreen()))),
                    _SI(icon: Icons.palette_outlined,       label: 'Appearance & Theme',        onTap: () {}),
                    _SI(icon: Icons.language_outlined,      label: 'Language',                  onTap: () {}),
                  ]),

                  // ── Section: Account ──────────────────────────────
                  _SectionLabel('Account'),
                  _SettingGroup(items: [
                    _SI(icon: Icons.lock_outline_rounded,   label: 'Privacy & Security',        onTap: () {}),
                    _SI(icon: Icons.sync_rounded,           label: 'Sync & Backup',             onTap: () {}),
                  ]),

                  // ── Section: Support ──────────────────────────────
                  _SectionLabel('Support'),
                  _SettingGroup(items: [
                    _SI(icon: Icons.help_outline_rounded,   label: 'Help & Support',            onTap: () {}),
                    _SI(icon: Icons.star_border_rounded,    label: 'Rate BookClub',             onTap: () {}),
                    _SI(icon: Icons.info_outline_rounded,   label: 'About',                     onTap: () {}),
                  ]),

                  const SizedBox(height: 24),

                  // ── Log out button ─────────────────────────────────
                  SizedBox(
                    width : double.infinity,
                    height: 52,
                    child : ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        onLogout();
                      },
                      icon : const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('Log Out',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize  : 15)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFEF2F2),
                        foregroundColor: kRed,
                        elevation      : 0,
                        shape          : RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 10, top: 4),
    child  : Text(text.toUpperCase(),
        style: const TextStyle(
            fontSize    : 11,
            fontWeight  : FontWeight.w700,
            color       : kTextMuted,
            letterSpacing: 0.9)),
  );
}

class _SettingGroup extends StatelessWidget {
  final List<_SI> items;
  const _SettingGroup({required this.items});

  @override
  Widget build(BuildContext context) => Container(
    margin    : const EdgeInsets.only(bottom: 20),
    decoration: _card(radius: 16),
    child     : Column(
      children: items.asMap().entries.map((e) {
        final isLast = e.key == items.length - 1;
        return Column(
          children: [
            ListTile(
              onTap  : e.value.onTap,
              dense  : true,
              leading: Container(
                width : 36,
                height: 36,
                decoration: BoxDecoration(
                    color       : kBg,
                    borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
                child: Icon(e.value.icon, size: 20, color: kTextSecondary),
              ),
              title  : Text(e.value.label,
                  style: const TextStyle(
                      fontSize  : 14,
                      fontWeight: FontWeight.w500,
                      color     : kTextPrimary)),
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: kTextMuted, size: 20),
            ),
            if (!isLast)
              Divider(
                  height: 1, indent: 62,
                  color : const Color(0xFFF3F4F6)),
          ],
        );
      }).toList(),
    ),
  );
}

class _SI {
  final IconData     icon;
  final String       label;
  final VoidCallback onTap;
  const _SI({required this.icon, required this.label, required this.onTap});
}

// ═════════════════════════════════════════════════════════════════════════════
// SEARCH BAR
// ═════════════════════════════════════════════════════════════════════════════

class _SearchBar extends StatelessWidget {
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  const _SearchBar({required this.query, required this.onChanged, required this.onClear});

  @override
  Widget build(BuildContext context) => Container(
    decoration: _card(radius: 12),
    child: TextField(
      onChanged: onChanged,
      style    : const TextStyle(fontSize: 14, color: kTextPrimary),
      decoration: InputDecoration(
        hintText     : 'Search books or authors...',
        hintStyle    : const TextStyle(fontSize: 14, color: kTextMuted),
        prefixIcon   : const Icon(Icons.search_rounded, color: kEmerald, size: 20),
        suffixIcon   : query.isNotEmpty
            ? GestureDetector(
            onTap: onClear,
            child: const Icon(Icons.clear_rounded, color: kTextMuted, size: 18))
            : null,
        filled       : true,
        fillColor    : kSurface,
        border       : OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide  : BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide  : BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide  : const BorderSide(color: kEmerald, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// READING CARD  — shadow only, no border
// ═════════════════════════════════════════════════════════════════════════════

class _ReadingCard extends StatelessWidget {
  final String title, author;
  final String? coverUrl;
  final double progress;
  final int currentPage, totalPages;

  const _ReadingCard({
    required this.title, required this.author, this.coverUrl,
    required this.progress, required this.currentPage, required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).round();
    return Container(
      margin    : const EdgeInsets.only(bottom: 14),
      padding   : const EdgeInsets.all(16),
      decoration: _card(radius: 18),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width : 54,
              height: 74,
              color : kEmeraldSoft,
              child : coverUrl != null && coverUrl!.isNotEmpty
                  ? Image.network(coverUrl!,
                  fit         : BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                  const Icon(Icons.menu_book_rounded, color: kEmerald))
                  : const Icon(Icons.menu_book_rounded,
                  color: kEmerald, size: 26),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize  : 15,
                        fontWeight: FontWeight.w700,
                        color     : kTextPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(author,
                    style: const TextStyle(fontSize: 12, color: kTextSecondary)),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value          : progress,
                    minHeight      : 5,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor     : const AlwaysStoppedAnimation(kEmerald),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Page $currentPage of $totalPages',
                        style: const TextStyle(fontSize: 11, color: kTextMuted)),
                    Text('$pct%',
                        style: const TextStyle(
                            fontSize  : 11,
                            fontWeight: FontWeight.w700,
                            color     : kEmerald)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// LIBRARY BOOK CARD
// ═════════════════════════════════════════════════════════════════════════════

class _LibraryBookCard extends StatefulWidget {
  final Map<String, dynamic> book;
  final bool isBookmarked;
  final VoidCallback onBookmarkTap;
  const _LibraryBookCard({required this.book, this.isBookmarked = false, required this.onBookmarkTap});

  @override
  State<_LibraryBookCard> createState() => _LibraryBookCardState();
}

class _LibraryBookCardState extends State<_LibraryBookCard> {
  bool _isDownloaded = false;
  
  @override
  void initState() {
    super.initState();
    _checkDownloaded();
  }
  
  Future<void> _checkDownloaded() async {
    final bookId = widget.book['id'];
    if (bookId != null) {
      final downloaded = await DownloadService.instance.fileExists(bookId);
      if (mounted) setState(() => _isDownloaded = downloaded);
    }
  }

  void _open(BuildContext context) {
    if (widget.book['file'] == null || widget.book['file'].toString().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content        : const Text('PDF not available yet'),
          backgroundColor: Colors.orange,
          behavior       : SnackBarBehavior.floating,
          margin         : const EdgeInsets.all(16),
          shape          : RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BookReaderScreen(
        bookId    : widget.book['id'],
        bookTitle : widget.book['title']    ?? 'Book',
        authors   : widget.book['author'],
        coverImage: widget.book['cover_url'],
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final title    = book['title']       ?? 'Untitled';
    final author   = book['author']      ?? '';
    final coverUrl = book['cover_url'];
    final pages    = book['total_pages'] ?? 0;
    final genres   = (book['genres'] as List?)
        ?.map((g) => g['name'].toString()).take(2).join(', ') ?? '';
    final hasPDF   = book['file'] != null;

    return GestureDetector(
      onTap: () => _open(context),
      child: Container(
        margin    : const EdgeInsets.only(bottom: 12),
        padding   : const EdgeInsets.all(14),
        decoration: _card(radius: 16),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children    : [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width : 52,
                    height: 72,
                    color : kEmeraldSoft,
                    child : coverUrl != null && coverUrl.toString().isNotEmpty
                        ? Image.network(coverUrl.toString(),
                        fit         : BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                        const Icon(Icons.menu_book_rounded, color: kEmerald))
                        : const Icon(Icons.menu_book_rounded, color: kEmerald, size: 24),
                  ),
                ),
                if (hasPDF)
                  Positioned(
                    bottom: -4, right: -4,
                    child : Container(
                      padding   : const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                          color: kEmerald, borderRadius: BorderRadius.circular(6)),
                      child: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 12),
                    ),
                  ),
                if (_isDownloaded)
                  Positioned(
                    top: -4, right: -4,
                    child : Container(
                      padding   : const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                          color: kGold, borderRadius: BorderRadius.circular(6)),
                      child: const Icon(Icons.offline_pin, color: Colors.white, size: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700, color: kTextPrimary),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(author,
                      style: const TextStyle(fontSize: 12, color: kTextSecondary),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 5),
                  if (pages > 0 || genres.isNotEmpty)
                    Text(
                      [if (pages > 0) '$pages pages', if (genres.isNotEmpty) genres].join('  •  '),
                      style: const TextStyle(fontSize: 11, color: kTextMuted),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            GestureDetector(
              onTap: widget.onBookmarkTap,
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child  : Icon(
                  widget.isBookmarked
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_outline_rounded,
                  color: widget.isBookmarked ? kEmerald : kTextMuted,
                  size : 20,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.chevron_right_rounded,
                color: hasPDF ? kEmerald : kTextMuted, size: 20),
            GestureDetector(
              onTap: (){
                if (!widget.isBookmarked) return;
                (context.findAncestorStateOfType<_DashboardState>())
                ?._markAsRead(book);
              },
              child: const Icon(Icons.check_circle_outline, color: kEmerald),
            )

          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// EMPTY STATE
// ═════════════════════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title, sub;
  final VoidCallback? onTap;

  const _EmptyState({
    required this.icon, required this.title, required this.sub, this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.all(32),
      child  : Column(
        mainAxisSize: MainAxisSize.min,
        children    : [
          Icon(icon, size: 56, color: const Color(0xFFD1D5DB)),
          const SizedBox(height: 14),
          Text(title,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: kTextSecondary),
              textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(sub,
              style: const TextStyle(fontSize: 13, color: kTextMuted),
              textAlign: TextAlign.center),
        ],
      ),
    ),
  );

}
