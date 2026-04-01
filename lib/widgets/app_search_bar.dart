import 'package:flutter/material.dart';
import '../config/theme.dart';

class AppSearchBar extends StatelessWidget {
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final String hintText;

  const AppSearchBar({
    super.key,
    required this.query,
    required this.onChanged,
    required this.onClear,
    this.hintText = 'Search...',
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: AppDecorations.card(radius: 12),
        child: TextField(
          onChanged: onChanged,
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle:
                const TextStyle(fontSize: 14, color: AppColors.textMuted),
            prefixIcon:
                const Icon(Icons.search_rounded, color: AppColors.emerald, size: 20),
            suffixIcon: query.isNotEmpty
                ? GestureDetector(
                    onTap: onClear,
                    child: const Icon(Icons.clear_rounded,
                        color: AppColors.textMuted, size: 18))
                : null,
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.emerald, width: 1.5)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      );
}
