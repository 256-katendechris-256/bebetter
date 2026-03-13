import 'dart:io';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/download_service.dart';

// ═════════════════════════════════════════════════════════════════════════════
// OFFLINE READER WRAPPER
// Checks if book is downloaded locally before deciding how to open it.
// Wrap your existing BookReaderScreen with this logic.
// ═════════════════════════════════════════════════════════════════════════════

const Color kEmerald = Color(0xFF059669);
const Color kInk     = Color(0xFF0D1B2A);
const Color kRed     = Color(0xFFEF4444);

class OfflineAwareReader extends StatefulWidget {
  final int     bookId;
  final String  bookTitle;
  final String  authors;
  final String? coverImage;
  final String? remoteUrl;   // PDF URL from server
  final int     initialPage;

  const OfflineAwareReader({
    super.key,
    required this.bookId,
    required this.bookTitle,
    required this.authors,
    this.coverImage,
    this.remoteUrl,
    this.initialPage = 1,
  });

  @override
  State<OfflineAwareReader> createState() => _OfflineAwareReaderState();
}

class _OfflineAwareReaderState extends State<OfflineAwareReader> {
  File?   _localFile;
  bool    _checking  = true;
  bool    _isOnline  = true;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    // Check local file
    final file = await DownloadService.instance.localFile(widget.bookId);

    // Check connectivity
    final results = await Connectivity().checkConnectivity();
    final online = results.any((r) => r != ConnectivityResult.none);

    if (mounted) {
      setState(() {
        _localFile = file;
        _isOnline  = online;
        _checking  = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D1B2A),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF059669))),
      );
    }

    // Has local file → open offline
    if (_localFile != null) {
      return _LocalPdfReader(
        file      : _localFile!,
        bookTitle : widget.bookTitle,
        initialPage: widget.initialPage,
        isOffline : !_isOnline,
      );
    }

    // No local file + offline → show error
    if (!_isOnline) {
      return _OfflineError(bookTitle: widget.bookTitle);
    }

    // Online, no local → open remote (hand off to existing BookReaderScreen)
    // This widget returns null so the caller uses its own BookReaderScreen.
    // We signal via callback. For now show a message.
    return _OnlineOnlyMessage(
      bookTitle: widget.bookTitle,
      onBack   : () => Navigator.pop(context),
    );
  }
}

// ─── Local PDF reader ─────────────────────────────────────────────────────────
// Uses flutter_pdfview to render a local File.

class _LocalPdfReader extends StatelessWidget {
  final File   file;
  final String bookTitle;
  final int    initialPage;
  final bool   isOffline;

  const _LocalPdfReader({
    required this.file,
    required this.bookTitle,
    required this.initialPage,
    required this.isOffline,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        backgroundColor: kInk,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(bookTitle,
                style: const TextStyle(
                    fontSize  : 14,
                    fontWeight: FontWeight.w700,
                    color     : Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            if (isOffline)
              const Text('Reading offline',
                  style: TextStyle(
                      fontSize: 10,
                      color   : Color(0xFF6EE7B7))),
          ],
        ),
        actions: [
          if (isOffline)
            Container(
              margin : const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color       : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.wifi_off_rounded,
                      size: 12, color: Color(0xFF6EE7B7)),
                  SizedBox(width: 4),
                  Text('Offline',
                      style: TextStyle(
                          fontSize: 11, color: Color(0xFF6EE7B7))),
                ],
              ),
            ),
        ],
      ),
      body: _PdfViewerBody(file: file, initialPage: initialPage),
    );
  }
}

// ─── PDF viewer body ──────────────────────────────────────────────────────────
// Wraps flutter_pdfview. If you already have a PDF viewer widget, replace this.

class _PdfViewerBody extends StatefulWidget {
  final File file;
  final int  initialPage;
  const _PdfViewerBody({required this.file, required this.initialPage});

  @override
  State<_PdfViewerBody> createState() => _PdfViewerBodyState();
}

class _PdfViewerBodyState extends State<_PdfViewerBody> {
  int _currentPage = 0;
  int _totalPages  = 0;

  @override
  Widget build(BuildContext context) {
    // ── Replace the placeholder below with your actual PDF viewer widget ──
    // Example using flutter_pdfview:
    //
    // return PDFView(
    //   filePath   : widget.file.path,
    //   enableSwipe: true,
    //   defaultPage: widget.initialPage - 1,
    //   onRender   : (pages) => setState(() => _totalPages = pages ?? 0),
    //   onPageChanged: (page, _) => setState(() => _currentPage = (page ?? 0) + 1),
    // );
    //
    // For now, show a placeholder:
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children    : [
          const Icon(Icons.picture_as_pdf_rounded,
              size: 64, color: Color(0xFF059669)),
          const SizedBox(height: 16),
          const Text('PDF ready to read',
              style: TextStyle(color: Colors.white, fontSize: 16)),
          const SizedBox(height: 8),
          Text(widget.file.path.split('/').last,
              style: const TextStyle(
                  color   : Color(0xFF6B7280),
                  fontSize: 12)),
          const SizedBox(height: 24),
          Text('File size: ${(widget.file.lengthSync() / 1024 / 1024).toStringAsFixed(1)} MB',
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
        ],
      ),
    );
  }
}

// ─── Offline error ─────────────────────────────────────────────────────────────

class _OfflineError extends StatelessWidget {
  final String bookTitle;
  const _OfflineError({required this.bookTitle});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: kInk,
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child  : Column(
          mainAxisSize: MainAxisSize.min,
          children    : [
            const Icon(Icons.wifi_off_rounded,
                size: 56, color: Color(0xFF6B7280)),
            const SizedBox(height: 20),
            const Text("You're offline",
                style: TextStyle(
                    color     : Colors.white,
                    fontSize  : 20,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Text('"$bookTitle" hasn\'t been downloaded.',
                style: const TextStyle(
                    color  : Color(0xFF6B7280),
                    fontSize: 14),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text('Download it while online to read offline.',
                style: TextStyle(
                    color  : Color(0xFF6B7280),
                    fontSize: 13),
                textAlign: TextAlign.center),
            const SizedBox(height: 32),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child    : const Text('Go back',
                  style: TextStyle(color: Color(0xFF059669),
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    ),
  );
}

// ─── Online only message ───────────────────────────────────────────────────────

class _OnlineOnlyMessage extends StatelessWidget {
  final String       bookTitle;
  final VoidCallback onBack;
  const _OnlineOnlyMessage({required this.bookTitle, required this.onBack});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: kInk,
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children    : [
          const Icon(Icons.cloud_outlined,
              size: 56, color: Color(0xFF6B7280)),
          const SizedBox(height: 20),
          const Text('Online reading',
              style: TextStyle(
                  color     : Colors.white,
                  fontSize  : 20,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          const Text('Opening in your book reader...',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
          const SizedBox(height: 32),
          TextButton(
            onPressed: onBack,
            child    : const Text('Go back',
                style: TextStyle(color: Color(0xFF059669),
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    ),
  );
}

// ─── Connectivity banner ──────────────────────────────────────────────────────
// Add this to the top of any screen to show offline status.

class ConnectivityBanner extends StatefulWidget {
  const ConnectivityBanner({super.key});

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    Connectivity().onConnectivityChanged.listen((results) {
      if (mounted) {
        setState(() => _isOffline = results.every(
                (r) => r == ConnectivityResult.none));
      }
    });
    _checkInitial();
  }

  Future<void> _checkInitial() async {
    final results = await Connectivity().checkConnectivity();
    if (mounted) {
      setState(() => _isOffline = results.every(
              (r) => r == ConnectivityResult.none));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isOffline) return const SizedBox.shrink();

    return Container(
      width  : double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color  : const Color(0xFF1F2937),
      child  : const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, size: 14, color: Color(0xFFFBBF24)),
          SizedBox(width: 6),
          Text("You're offline — showing downloaded books only",
              style: TextStyle(
                  color    : Color(0xFFFBBF24),
                  fontSize : 12,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}