class BookstoreBook {
  final int id;
  final String title;
  final String author;
  final double price;
  final double? discountPrice;
  final double effectivePrice;
  final bool onSale;
  final String coverUrl;
  final int stock;
  final bool isAvailable;
  final String categoryName;

  const BookstoreBook({
    required this.id,
    required this.title,
    required this.author,
    required this.price,
    this.discountPrice,
    required this.effectivePrice,
    required this.onSale,
    required this.coverUrl,
    required this.isAvailable,
    required this.stock,
    required this.categoryName,
});

  factory BookstoreBook.fromJson(Map<String, dynamic> json) {
    return BookstoreBook(
      id:             json['id'],
      title:          json['title'] ?? 'Untitled',
      author:         json['author'] ?? '',
      price:          double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      discountPrice:  json['discount_price'] != null
          ? double.tryParse(json['discount_price'].toString())
          : null,
      effectivePrice: double.tryParse(json['effective_price']?.toString() ?? '0') ?? 0,
      onSale:         json['on_sale'] ?? false,
      coverUrl:       json['cover_url'] ?? '',
      stock:          json['stock'] ?? 0,
      isAvailable:    json['is_available'] ?? true,
      categoryName:   json['category_name'] ?? '',
    );
  }

  String get formattedPrice =>
      'UGX ${effectivePrice.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m)=> '${m[1]},')}';
}