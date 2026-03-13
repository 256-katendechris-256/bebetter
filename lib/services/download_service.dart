import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

// ─── Download state ───────────────────────────────────────────────────────────

enum DownloadStatus { none, downloading, done, failed }

class DownloadState {
  final DownloadStatus status;
  final double         progress; // 0.0 – 1.0
  const DownloadState(this.status, [this.progress = 0]);
}

// ═════════════════════════════════════════════════════════════════════════════
// DOWNLOAD SERVICE  — singleton
// ═════════════════════════════════════════════════════════════════════════════

class DownloadService extends ChangeNotifier {
  DownloadService._();
  static final DownloadService instance = DownloadService._();

  final _dio      = Dio();
  final _states   = <int, DownloadState>{};   // bookId → state
  CancelToken?    _cancelToken;

  // ── State accessors ────────────────────────────────────────────────────────

  DownloadState stateOf(int bookId) =>
      _states[bookId] ?? const DownloadState(DownloadStatus.none);

  bool isDownloaded(int bookId) =>
      _states[bookId]?.status == DownloadStatus.done;

  bool isDownloading(int bookId) =>
      _states[bookId]?.status == DownloadStatus.downloading;

  // ── Local file path ────────────────────────────────────────────────────────

  Future<String> _localPath(int bookId) async {
    final dir = await getApplicationDocumentsDirectory();
    final booksDir = Directory('${dir.path}/books');
    if (!await booksDir.exists()) await booksDir.create(recursive: true);
    return '${booksDir.path}/book_$bookId.pdf';
  }

  // ── Check if file exists on disk ───────────────────────────────────────────

  Future<bool> fileExists(int bookId) async {
    final path = await _localPath(bookId);
    return File(path).existsSync();
  }

  /// Call this on app start to restore downloaded state from disk.
  Future<void> restoreFromDisk(List<int> bookIds) async {
    for (final id in bookIds) {
      if (await fileExists(id)) {
        _states[id] = const DownloadState(DownloadStatus.done);
      }
    }
    notifyListeners();
  }

  // ── Get local file (null if not downloaded) ────────────────────────────────

  Future<File?> localFile(int bookId) async {
    final path = await _localPath(bookId);
    final file = File(path);
    return file.existsSync() ? file : null;
  }

  // ── Download ───────────────────────────────────────────────────────────────

  Future<void> download({
    required int    bookId,
    required String url,
    required String bookTitle,
  }) async {
    if (isDownloading(bookId)) return;

    _setState(bookId, const DownloadState(DownloadStatus.downloading, 0));

    try {
      final savePath  = await _localPath(bookId);
      _cancelToken    = CancelToken();

      await _dio.download(
        url,
        savePath,
        cancelToken   : _cancelToken,
        deleteOnError : true,
        onReceiveProgress: (received, total) {
          if (total <= 0) return;
          _setState(bookId, DownloadState(
            DownloadStatus.downloading,
            received / total,
          ));
        },
      );

      _setState(bookId, const DownloadState(DownloadStatus.done, 1));
      debugPrint('✅ Downloaded book $bookId → $savePath');
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        _setState(bookId, const DownloadState(DownloadStatus.none));
      } else {
        debugPrint('❌ Download failed: $e');
        _setState(bookId, const DownloadState(DownloadStatus.failed));
      }
    } catch (e) {
      debugPrint('❌ Download error: $e');
      _setState(bookId, const DownloadState(DownloadStatus.failed));
    }
  }

  // ── Cancel ─────────────────────────────────────────────────────────────────

  void cancel(int bookId) {
    _cancelToken?.cancel('User cancelled');
    _setState(bookId, const DownloadState(DownloadStatus.none));
  }

  // ── Delete ─────────────────────────────────────────────────────────────────

  Future<void> delete(int bookId) async {
    final path = await _localPath(bookId);
    final file = File(path);
    if (file.existsSync()) await file.delete();
    _setState(bookId, const DownloadState(DownloadStatus.none));
    debugPrint('🗑 Deleted book $bookId');
  }

  // ── All downloaded book IDs ────────────────────────────────────────────────

  Future<List<int>> allDownloadedIds() async {
    final dir     = await getApplicationDocumentsDirectory();
    final booksDir = Directory('${dir.path}/books');
    if (!await booksDir.exists()) return [];

    final files = booksDir.listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.pdf'))
        .toList();

    return files.map((f) {
      final name = f.uri.pathSegments.last; // book_42.pdf
      final idStr = name.replaceAll('book_', '').replaceAll('.pdf', '');
      return int.tryParse(idStr) ?? -1;
    }).where((id) => id != -1).toList();
  }

  // ── Storage used ───────────────────────────────────────────────────────────

  Future<String> storageUsed() async {
    final dir     = await getApplicationDocumentsDirectory();
    final booksDir = Directory('${dir.path}/books');
    if (!await booksDir.exists()) return '0 MB';

    int total = 0;
    await for (final f in booksDir.list()) {
      if (f is File) total += await f.length();
    }
    final mb = total / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  void _setState(int bookId, DownloadState state) {
    _states[bookId] = state;
    notifyListeners();
  }
}