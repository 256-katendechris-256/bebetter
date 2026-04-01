import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/theme.dart';
import '../services/download_service.dart';
import '../services/api_service.dart';
import 'book_reader_screen.dart';

// ═════════════════════════════════════════════════════════════════════════════
// DOWNLOADS SCREEN
// ═════════════════════════════════════════════════════════════════════════════

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  final _dl  = DownloadService.instance;
  final _api = ApiService();

  List<Map<String, dynamic>> _downloadedBooks = [];
  String  _storageUsed = '0 MB';
  bool    _loading     = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final ids = await _dl.allDownloadedIds();
      if (ids.isEmpty) {
        if (mounted) setState(() { _downloadedBooks = []; _loading = false; });
        return;
      }

      // Fetch book details for each downloaded ID
      final books = <Map<String, dynamic>>[];
      for (final id in ids) {
        try {
          final res = await _api.getBookDetail(id);
          if (res.statusCode == 200) {
            books.add(Map<String, dynamic>.from(res.data));
          }
        } catch (_) {
          // Book deleted from server but still local — add placeholder
          books.add({'id': id, 'title': 'Book #$id', 'author': 'Unknown'});
        }
      }

      final storage = await _dl.storageUsed();
      if (mounted) {
        setState(() {
          _downloadedBooks = books;
          _storageUsed     = storage;
          _loading         = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete(int bookId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete download?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('The book will be removed from your device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _dl.delete(bookId);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor         : AppColors.ink,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────
          Container(
            color  : AppColors.ink,
            padding: EdgeInsets.only(
              top   : MediaQuery.of(context).padding.top + 12,
              left  : 8,
              right : 16,
              bottom: 14,
            ),
            child: Row(
              children: [
                IconButton(
                  icon     : const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Text('Downloads',
                      style: TextStyle(
                          fontSize    : 18,
                          fontWeight  : FontWeight.w800,
                          color       : Colors.white,
                          letterSpacing: -0.3)),
                ),
                if (_storageUsed != '0 MB')
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color       : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(_storageUsed,
                        style: TextStyle(
                            fontSize  : 12,
                            color     : Colors.white.withOpacity(0.8),
                            fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ),

          // ── Body ────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(
                child: CircularProgressIndicator(color: AppColors.emerald))
                : _downloadedBooks.isEmpty
                ? _buildEmpty()
                : RefreshIndicator(
              color    : AppColors.emerald,
              onRefresh: _load,
              child    : ListView.builder(
                padding    : const EdgeInsets.fromLTRB(16, 16, 16, 24),
                itemCount  : _downloadedBooks.length,
                itemBuilder: (_, i) {
                  final book = _downloadedBooks[i];
                  return _DownloadedBookCard(
                    book    : book,
                    onOpen  : () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) =>
                            BookReaderScreen(
                              bookId    : book['id'],
                              bookTitle : book['title'] ?? 'Book',
                              authors   : book['author'] ?? '',
                              coverImage: book['cover_url'],
                            ))),
                    onDelete: () => _delete(book['id']),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children    : [
        Icon(Icons.download_outlined,
            size: 60, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        const Text('No downloads yet',
            style: TextStyle(
                fontSize  : 17,
                fontWeight: FontWeight.w700,
                color     : AppColors.textSecondary)),
        const SizedBox(height: 6),
        const Text('Download books to read offline.',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
      ],
    ),
  );
}

// ─── Downloaded book card ─────────────────────────────────────────────────────

class _DownloadedBookCard extends StatelessWidget {
  final Map<String, dynamic> book;
  final VoidCallback          onOpen;
  final VoidCallback          onDelete;

  const _DownloadedBookCard({
    required this.book,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final title    = book['title']    ?? 'Untitled';
    final author   = book['author']   ?? '';
    final coverUrl = book['cover_url'];
    final pages    = book['total_pages'] ?? 0;

    return Container(
      margin    : const EdgeInsets.only(bottom: 12),
      padding   : const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color      : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow  : const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          // Cover
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width : 52,
              height: 72,
              color : AppColors.emeraldSoft,
              child : coverUrl != null && coverUrl.toString().isNotEmpty
                  ? Image.network(coverUrl.toString(),
                  fit         : BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                  const Icon(Icons.menu_book_rounded, color: AppColors.emerald))
                  : const Icon(Icons.menu_book_rounded, color: AppColors.emerald, size: 24),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize  : 14,
                        fontWeight: FontWeight.w700,
                        color     : AppColors.textPrimary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(author,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.download_done_rounded,
                        size: 13, color: AppColors.emerald),
                    const SizedBox(width: 4),
                    Text(pages > 0 ? '$pages pages • Available offline'
                        : 'Available offline',
                        style: const TextStyle(
                            fontSize  : 11,
                            color     : AppColors.emerald,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),

          // Actions
          Column(
            children: [
              GestureDetector(
                onTap: onOpen,
                child: Container(
                  padding   : const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color       : AppColors.emerald,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('Read',
                      style: TextStyle(
                          color     : Colors.white,
                          fontSize  : 12,
                          fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding   : const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color       : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('Delete',
                      style: TextStyle(
                          color     : AppColors.red,
                          fontSize  : 12,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}