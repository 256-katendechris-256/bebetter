import 'package:flutter/material.dart';
import '../config/theme.dart';

class ReadingCard extends StatelessWidget {
  final String title;
  final String author;
  final String? coverUrl;
  final double progress;
  final int currentPage;
  final int totalPages;
  final VoidCallback? onTap;

  const ReadingCard({
    super.key,
    required this.title,
    required this.author,
    this.coverUrl,
    required this.progress,
    required this.currentPage,
    required this.totalPages,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).round();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: AppDecorations.card(radius: 18),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 54,
                height: 74,
                color: AppColors.emeraldSoft,
                child: coverUrl != null && coverUrl!.isNotEmpty
                    ? Image.network(coverUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.menu_book_rounded,
                            color: AppColors.emerald))
                    : const Icon(Icons.menu_book_rounded,
                        color: AppColors.emerald, size: 26),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(author,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 5,
                      backgroundColor: const Color(0xFFE5E7EB),
                      valueColor:
                          const AlwaysStoppedAnimation(AppColors.emerald),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Page $currentPage of $totalPages',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textMuted)),
                      Text('$pct%',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.emerald)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
