import 'package:flutter/material.dart';
import '../services/download_service.dart';

const Color kEmerald = Color(0xFF059669);
const Color kRed     = Color(0xFFEF4444);
const Color kInk     = Color(0xFF0D1B2A);

// ═════════════════════════════════════════════════════════════════════════════
// DOWNLOAD BUTTON  — shows idle / progress / done / failed states
// ═════════════════════════════════════════════════════════════════════════════

class DownloadButton extends StatelessWidget {
  final int    bookId;
  final String fileUrl;
  final String bookTitle;
  final double size;

  const DownloadButton({
    super.key,
    required this.bookId,
    required this.fileUrl,
    required this.bookTitle,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: DownloadService.instance,
      builder   : (_, __) {
        final state = DownloadService.instance.stateOf(bookId);

        switch (state.status) {

        // ── Not downloaded ──────────────────────────────────────
          case DownloadStatus.none:
          case DownloadStatus.failed:
            return GestureDetector(
              onTap: () => DownloadService.instance.download(
                bookId   : bookId,
                url      : fileUrl,
                bookTitle: bookTitle,
              ),
              child: Container(
                width : size,
                height: size,
                decoration: BoxDecoration(
                  color       : kEmerald.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(
                  state.status == DownloadStatus.failed
                      ? Icons.refresh_rounded
                      : Icons.download_outlined,
                  color: kEmerald,
                  size : size * 0.55,
                ),
              ),
            );

        // ── Downloading ─────────────────────────────────────────
          case DownloadStatus.downloading:
            return GestureDetector(
              onTap: () => DownloadService.instance.cancel(bookId),
              child: SizedBox(
                width : size,
                height: size,
                child : Stack(
                  alignment: Alignment.center,
                  children  : [
                    SizedBox(
                      width : size,
                      height: size,
                      child : CircularProgressIndicator(
                        value      : state.progress,
                        strokeWidth: 2.5,
                        color      : kEmerald,
                        backgroundColor: kEmerald.withValues(alpha: 0.15),
                      ),
                    ),
                    Icon(Icons.close_rounded,
                        size: size * 0.4, color: kEmerald),
                  ],
                ),
              ),
            );

        // ── Downloaded ──────────────────────────────────────────
          case DownloadStatus.done:
            return GestureDetector(
              onTap: () => _confirmDelete(context),
              child: Container(
                width : size,
                height: size,
                decoration: BoxDecoration(
                  color       : kEmerald.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.download_done_rounded,
                    color: kEmerald, size: size * 0.55),
              ),
            );
        }
      },
    );
  }

  void _confirmDelete(BuildContext context) {
    showModalBottomSheet(
      context      : context,
      shape        : const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder      : (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child  : Column(
          mainAxisSize: MainAxisSize.min,
          children    : [
            Container(
              width : 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color       : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Icon(Icons.download_done_rounded,
                color: kEmerald, size: 36),
            const SizedBox(height: 12),
            Text(bookTitle,
                style: const TextStyle(
                    fontSize  : 16,
                    fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
                maxLines : 2,
                overflow : TextOverflow.ellipsis),
            const SizedBox(height: 6),
            const Text('This book is saved on your device.',
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
            const SizedBox(height: 24),
            SizedBox(
              width : double.infinity,
              child : OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await DownloadService.instance.delete(bookId);
                },
                icon : const Icon(Icons.delete_outline_rounded,
                    color: kRed, size: 18),
                label: const Text('Remove from device',
                    style: TextStyle(color: kRed, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  side  : const BorderSide(color: kRed),
                  shape : RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}