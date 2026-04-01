import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/book.dart';

class LibraryBookCard extends StatelessWidget {
  final Book book;
  final bool isBookmarked;
  final VoidCallback onBookmarkTap;
  final VoidCallback onTap;
  final VoidCallback? onMarkAsRead;

  const LibraryBookCard({
    super.key,
    required this.book,
    this.isBookmarked = false,
    required this.onBookmarkTap,
    required this.onTap,
    this.onMarkAsRead,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: AppDecorations.card(radius: 16),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 52,
                    height: 72,
                    color: AppColors.emeraldSoft,
                    child: book.coverUrl != null && book.coverUrl!.isNotEmpty
                        ? Image.network(book.coverUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.menu_book_rounded,
                                color: AppColors.emerald))
                        : const Icon(Icons.menu_book_rounded,
                            color: AppColors.emerald, size: 24),
                  ),
                ),
                if (book.hasPdf)
                  Positioned(
                    bottom: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                          color: AppColors.emerald,
                          borderRadius: BorderRadius.circular(6)),
                      child: const Icon(Icons.picture_as_pdf,
                          color: Colors.white, size: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(book.title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(book.author ?? '',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 5),
                  if ((book.totalPages ?? 0) > 0 || book.genreNames.isNotEmpty)
                    Text(
                      [
                        if ((book.totalPages ?? 0) > 0)
                          '${book.totalPages} pages',
                        if (book.genreNames.isNotEmpty) book.genreNames
                      ].join('  •  '),
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onBookmarkTap,
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  isBookmarked
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_outline_rounded,
                  color: isBookmarked ? AppColors.emerald : AppColors.textMuted,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.chevron_right_rounded,
                color: book.hasPdf ? AppColors.emerald : AppColors.textMuted,
                size: 20),
            if (onMarkAsRead != null && isBookmarked)
              GestureDetector(
                onTap: onMarkAsRead,
                child: const Icon(Icons.check_circle_outline,
                    color: AppColors.emerald),
              ),
          ],
        ),
      ),
    );
  }
}

class LibraryBookCardLegacy extends StatelessWidget {
  final Map<String, dynamic> book;
  final bool isBookmarked;
  final VoidCallback onBookmarkTap;
  final VoidCallback onTap;
  final VoidCallback? onMarkAsRead;

  const LibraryBookCardLegacy({
    super.key,
    required this.book,
    this.isBookmarked = false,
    required this.onBookmarkTap,
    required this.onTap,
    this.onMarkAsRead,
  });

  @override
  Widget build(BuildContext context) {
    final title = book['title'] ?? 'Untitled';
    final author = book['author'] ?? '';
    final coverUrl = book['cover_url'];
    final pages = book['total_pages'] ?? 0;
    final genres = (book['genres'] as List?)
            ?.map((g) => g['name'].toString())
            .take(2)
            .join(', ') ??
        '';
    final hasPDF = book['file'] != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: AppDecorations.card(radius: 16),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 52,
                    height: 72,
                    color: AppColors.emeraldSoft,
                    child: coverUrl != null && coverUrl.toString().isNotEmpty
                        ? Image.network(coverUrl.toString(),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.menu_book_rounded,
                                color: AppColors.emerald))
                        : const Icon(Icons.menu_book_rounded,
                            color: AppColors.emerald, size: 24),
                  ),
                ),
                if (hasPDF)
                  Positioned(
                    bottom: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                          color: AppColors.emerald,
                          borderRadius: BorderRadius.circular(6)),
                      child: const Icon(Icons.picture_as_pdf,
                          color: Colors.white, size: 12),
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
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(author,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 5),
                  if (pages > 0 || genres.isNotEmpty)
                    Text(
                      [
                        if (pages > 0) '$pages pages',
                        if (genres.isNotEmpty) genres
                      ].join('  •  '),
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onBookmarkTap,
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  isBookmarked
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_outline_rounded,
                  color: isBookmarked ? AppColors.emerald : AppColors.textMuted,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.chevron_right_rounded,
                color: hasPDF ? AppColors.emerald : AppColors.textMuted,
                size: 20),
            if (onMarkAsRead != null && isBookmarked)
              GestureDetector(
                onTap: onMarkAsRead,
                child: const Icon(Icons.check_circle_outline,
                    color: AppColors.emerald),
              ),
          ],
        ),
      ),
    );
  }
}
