// ─── Drop-in replacement for _QuoteCarousel in dashboard.dart ────────────────
// Uses ZenQuotes API for daily quotes, caches locally, works offline.
// Add to pubspec.yaml if not already there:
//   shared_preferences: ^2.2.3
//   http: ^1.2.0

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ─── Fallback quotes (used offline or if API fails) ──────────────────────────
const _fallbackQuotes = [
  {'text': 'A reader lives a thousand lives before he dies. The man who never reads lives only one.', 'author': 'George R.R. Martin'},
  {'text': 'Not all those who wander are lost.', 'author': 'J.R.R. Tolkien'},
  {'text': 'It is our choices, far more than our abilities, that show what we truly are.', 'author': 'J.K. Rowling'},
  {'text': 'Until I feared I would lose it, I never loved to read. One does not love breathing.', 'author': 'Harper Lee'},
  {'text': 'There is no friend as loyal as a book.', 'author': 'Ernest Hemingway'},
  {'text': 'A book is a dream that you hold in your hand.', 'author': 'Neil Gaiman'},
  {'text': 'Reading gives us someplace to go when we have to stay where we are.', 'author': 'Mason Cooley'},
  {'text': 'Once you learn to read, you will be forever free.', 'author': 'Frederick Douglass'},
  {'text': 'I do believe something very magical can happen when you read a good book.', 'author': 'J.K. Rowling'},
  {'text': 'The more that you read, the more things you will know.', 'author': 'Dr. Seuss'},
  {'text': 'A book is a gift you can open again and again.', 'author': 'Garrison Keillor'},
  {'text': 'Reading is to the mind what exercise is to the body.', 'author': 'Joseph Addison'},
  {'text': 'Books are a uniquely portable magic.', 'author': 'Stephen King'},
  {'text': 'One must always be careful of books, and what is inside them.', 'author': 'Cassandra Clare'},
  {'text': 'A book is a loaded gun in the house next door.', 'author': 'Ray Bradbury'},
  {'text': 'If you only read the books that everyone else is reading, you can only think what everyone else is thinking.', 'author': 'Haruki Murakami'},
  {'text': 'We read to know we are not alone.', 'author': 'C.S. Lewis'},
  {'text': 'Today a reader, tomorrow a leader.', 'author': 'Margaret Fuller'},
  {'text': 'The world belongs to those who read.', 'author': 'Rick Holland'},
  {'text': 'A great book should leave you with many experiences, and slightly exhausted at the end.', 'author': 'William Styron'},
  {'text': 'Reading is the sole means by which we slip, involuntarily, often helplessly, into another\'s skin.', 'author': 'Joyce Carol Oates'},
  {'text': 'You can never get a cup of tea large enough or a book long enough to suit me.', 'author': 'C.S. Lewis'},
  {'text': 'Think before you speak. Read before you think.', 'author': 'Fran Lebowitz'},
  {'text': 'A book is a mirror: if an ass peers into it, you can\'t expect an apostle to look out.', 'author': 'Georg Lichtenberg'},
  {'text': 'Sleep is good, he said, and books are better.', 'author': 'George R.R. Martin'},
  {'text': 'I find television very educational. Every time someone switches it on, I go into another room and read a book.', 'author': 'Groucho Marx'},
  {'text': 'Show me a family of readers, and I will show you the people who move the world.', 'author': 'Napoleon Bonaparte'},
  {'text': 'Good friends, good books, and a sleepy conscience: this is the ideal life.', 'author': 'Mark Twain'},
  {'text': 'Never trust anyone who has not brought a book with them.', 'author': 'Lemony Snicket'},
  {'text': 'I cannot live without books.', 'author': 'Thomas Jefferson'},
  {'text': 'Literature is the most agreeable way of ignoring life.', 'author': 'Fernando Pessoa'},
  {'text': 'A reader lives a thousand lives. The man who never reads lives only one.', 'author': 'George R.R. Martin'},
  {'text': 'The reading of all good books is like conversation with the finest people of past centuries.', 'author': 'René Descartes'},
  {'text': 'There is no such thing as a child who hates to read; there are only children who have not found the right book.', 'author': 'Frank Serafini'},
  {'text': 'Books are the quietest and most constant of friends.', 'author': 'Charles W. Eliot'},
  {'text': 'A book is a device to ignite the imagination.', 'author': 'Alan Bennett'},
  {'text': 'To learn to read is to light a fire.', 'author': 'Victor Hugo'},
];

// ─── Quote service ─────────────────────────────────────────────────────────

class _QuoteService {
  static const _cacheKey    = 'daily_quotes_v1';
  static const _cacheDateKey = 'daily_quotes_date_v1';
  static const _usedKey     = 'used_quote_indices';

  /// Returns 4 quotes for today — fetched fresh daily, no repeats for 30 days.
  static Future<List<Map<String, String>>> getTodayQuotes() async {
    final prefs   = await SharedPreferences.getInstance();
    final today   = DateTime.now().toIso8601String().substring(0, 10); // YYYY-MM-DD
    final cached  = prefs.getString(_cacheKey);
    final cachedDate = prefs.getString(_cacheDateKey);

    // Return cached quotes if same day
    if (cached != null && cachedDate == today) {
      try {
        final list = jsonDecode(cached) as List;
        return list.map((q) => Map<String, String>.from(q)).toList();
      } catch (_) {}
    }

    // Try fetching from API
    List<Map<String, String>> quotes = [];
    try {
      // ZenQuotes returns 50 random quotes — we pick 4 unused ones
      final res = await http.get(
        Uri.parse('https://zenquotes.io/api/quotes'),
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        final apiQuotes = data
            .map((q) => {
          'text'  : (q['q'] ?? '').toString(),
          'author': (q['a'] ?? '').toString(),
        })
            .where((q) => q['text']!.length > 20 && q['text']!.length < 200)
            .toList();

        // Pick 4 non-repeated quotes
        quotes = _pickUnused(apiQuotes, prefs, 4);
      }
    } catch (_) {
      // API failed — fall back to local list
    }

    // Fallback to local list if API failed or returned nothing
    if (quotes.isEmpty) {
      quotes = _pickUnused(
        _fallbackQuotes.map((q) => Map<String, String>.from(q)).toList(),
        prefs,
        4,
      );
    }

    // Cache for today
    await prefs.setString(_cacheKey, jsonEncode(quotes));
    await prefs.setString(_cacheDateKey, today);

    return quotes;
  }

  /// Picks `count` quotes not used in the last 30 days.
  static List<Map<String, String>> _pickUnused(
      List<Map<String, String>> pool,
      SharedPreferences prefs,
      int count,
      ) {
    final usedRaw = prefs.getStringList(_usedKey) ?? [];
    // Keep only last 30 entries to avoid depleting the pool
    final used = usedRaw.length > 30 ? usedRaw.sublist(usedRaw.length - 30) : usedRaw;

    final available = pool
        .where((q) => !used.contains(q['text']))
        .toList()
      ..shuffle();

    if (available.length < count) {
      // Pool exhausted — reset used list and use full pool
      prefs.setStringList(_usedKey, []);
      pool.shuffle();
      return pool.take(count).toList();
    }

    final picked = available.take(count).toList();

    // Mark as used
    final newUsed = [...used, ...picked.map((q) => q['text']!)];
    prefs.setStringList(_usedKey, newUsed);

    return picked;
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// QUOTE CAROUSEL  — drop-in replacement
// ═════════════════════════════════════════════════════════════════════════════

const Color kInk     = Color(0xFF0D1B2A);
const Color kEmerald = Color(0xFF059669);

class QuoteCarousel extends StatefulWidget {
  const QuoteCarousel({super.key});

  @override
  State<QuoteCarousel> createState() => _QuoteCarouselState();
}

class _QuoteCarouselState extends State<QuoteCarousel> {
  final _ctrl = PageController();
  int  _page  = 0;

  List<Map<String, String>> _quotes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final quotes = await _QuoteService.getTodayQuotes();
    if (mounted) setState(() { _quotes = quotes; _loading = false; });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

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
                : Colors.white.withValues(alpha: 0.3),
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
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 210,
        child : _loading
            ? _buildSkeleton()
            : PageView.builder(
          controller   : _ctrl,
          itemCount    : _quotes.length,
          onPageChanged: (i) => setState(() => _page = i),
          itemBuilder  : (_, i) => _buildCard(_quotes[i]),
        ),
      ),
    ),
  );

  Widget _buildCard(Map<String, String> q) => Container(
    decoration: const BoxDecoration(color: kInk),
    padding   : const EdgeInsets.fromLTRB(22, 20, 22, 18),
    child     : Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding  : const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color       : kEmerald.withValues(alpha: 0.18),
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
                    color   : Colors.white.withValues(alpha: 0.2),
                    height  : 1)),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Text(q['text'] ?? '',
              style: const TextStyle(
                  color    : Colors.white,
                  fontSize : 14,
                  height   : 1.6,
                  fontStyle: FontStyle.italic),
              maxLines: 4,
              overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text('— ${q['author']}',
                  style: TextStyle(
                      color     : kEmerald.withValues(alpha: 0.9),
                      fontSize  : 12,
                      fontWeight: FontWeight.w700)),
            ),
            _dots(),
          ],
        ),
      ],
    ),
  );

  Widget _buildSkeleton() => Container(
    color  : kInk,
    padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
    child  : Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width : 120, height: 18,
          decoration: BoxDecoration(
            color       : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(9),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width : double.infinity, height: 12,
          decoration: BoxDecoration(
            color       : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width : 240, height: 12,
          decoration: BoxDecoration(
            color       : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const Spacer(),
        Container(
          width : 100, height: 10,
          decoration: BoxDecoration(
            color       : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ],
    ),
  );
}