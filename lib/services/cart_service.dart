import '../models/bookstore_book.dart';
import '../models/store.dart';

class CartItem{
  final BookstoreBook book;
  int quantity;
  CartItem({required this.book, this.quantity=1});

  double get subtotal => book.effectivePrice * quantity;
}

class CartService {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  BookStore?currentStore;
  final List<CartItem> items =[];

  int get itemCount => items.fold(0, (sum, i)=> sum + i.quantity);
  double get total => items.fold(0, (sum, i)=> sum + i.subtotal);

  //Returns false if trying to mix stores
  bool addBook(BookstoreBook book, BookStore store){
    if (currentStore !=null && currentStore!.slug !=store.slug){
      return false;
    }
    currentStore = store;
    final existing = items.where((i)=> i.book.id == book.id);
    if (existing.isNotEmpty){
      existing.first.quantity++;
    }else{
      items.add(CartItem(book: book));
    }
    return true;
  }

  void removeBook(int bookId){
    items.removeWhere((i)=> i.book.id ==bookId);
    if (items.isEmpty) currentStore = null;
  }

  void updateQty(int bookId, int qty){
    if (qty<=0){
      removeBook(bookId); return;
    }
    final item = items.firstWhere((i)=> i.book.id ==bookId);
    item.quantity =qty;
  }
  void clear(){
    items.clear();
    currentStore = null;
  }
}