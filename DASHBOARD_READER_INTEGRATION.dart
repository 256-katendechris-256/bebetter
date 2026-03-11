// Example: How to Add PDF Reader to Dashboard Library

// In lib/dashboard.dart, find the _buildLibrary() method
// Replace or update it with this implementation:

Widget _buildLibrary() {
  return RefreshIndicator(
    color: kTealMid,
    onRefresh: _loadLibraryData,
    child: _books.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.menu_book_outlined, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  'No books yet',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loadLibraryData,
                  style: ElevatedButton.styleFrom(backgroundColor: kTealMid),
                  child: const Text('Refresh Library'),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _books.length,
            itemBuilder: (context, index) {
              final book = _books[index];
              return BookCard(
                book: book,
                onTap: () => _goToBookReader(book),
              );
            },
          ),
  );
}

// Handler for opening book reader
void _goToBookReader(Map<String, dynamic> book) {
  // Check if book has a PDF file
  if (book['file'] == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('This book does not have a PDF file'),
        backgroundColor: Colors.orange.shade600,
      ),
    );
    return;
  }

  // Navigate to book reader
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => BookReaderScreen(
        bookId: book['id'],
        bookTitle: book['title'],
        authors: book['author'],
        coverImage: book['cover_url'],
      ),
    ),
  );
}

// Reusable Book Card Widget
class BookCard extends StatelessWidget {
  final Map<String, dynamic> book;
  final VoidCallback onTap;

  const BookCard({
    super.key,
    required this.book,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color kTealMid = Color(0xFF11755E);
    const Color kTealDark = Color(0xFF0B4D40);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Cover Image
              Container(
                width: 80,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade200,
                  image: book['cover_url'] != null && book['cover_url'].isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(book['cover_url']),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: book['cover_url'] == null || book['cover_url'].isEmpty
                    ? const Icon(Icons.book, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 12),

              // Book Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      book['title'] ?? 'Unknown Title',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: kTealDark,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Author
                    Text(
                      book['author'] ?? 'Unknown Author',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Pages and PDF indicator
                    Row(
                      children: [
                        if (book['total_pages'] != null && book['total_pages'] > 0)
                          Expanded(
                            child: Text(
                              '${book['total_pages']} pages',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ),
                        if (book['file'] != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: kTealMid.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.picture_as_pdf,
                                  size: 12,
                                  color: kTealMid,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'PDF',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: kTealMid,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Read Button
              const SizedBox(width: 8),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: kTealMid,
                  shape: BoxShape.circle,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(24),
                    child: const Icon(
                      Icons.chevron_right,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Don't forget to import at the top of dashboard.dart:
// import 'package:bbeta/screens/book_reader_screen.dart';
