# Mobile PDF Book Reader - Setup Guide

## ✅ What's Been Implemented

### Flutter Side (Mobile App)

1. **PDF Reader Service** (`lib/services/pdf_reader_service.dart`)
   - Downloads PDFs from Django backend
   - Caches PDFs locally on device
   - Tracks download progress
   - Manages cache cleanup

2. **Book Reader Screen** (`lib/screens/book_reader_screen.dart`)
   - Full-screen PDF viewing using `pdfx` package
   - Interactive page navigation (next/previous buttons)
   - Page jump functionality with slider
   - Reading session tracking (logs minutes spent)
   - Top/bottom controls (can hide by tapping screen)
   - Progress bar showing current position in book

3. **Updated Dependencies** (`pubspec.yaml`)
   - Added `pdfx: ^2.4.2` for PDF viewing
   - Added `path_provider: ^2.1.4` for local file caching

## 🚀 Next Steps

### Step 1: Add Django Backend Endpoint

Your Django backend needs a PDF download endpoint. Add this to `apps/books/views.py`:

```python
from django.http import FileResponse
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from .models import Book

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def download_pdf(request, book_id):
    """Download PDF file for a book"""
    try:
        book = Book.objects.get(id=book_id)
        # Assuming you have a pdf_file field in your Book model
        if not book.pdf_file:
            return Response(
                {'error': 'No PDF available for this book'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        response = FileResponse(book.pdf_file.open('rb'))
        response['Content-Type'] = 'application/pdf'
        response['Content-Disposition'] = f'attachment; filename="{book.title}.pdf"'
        return response
    except Book.DoesNotExist:
        return Response(
            {'error': 'Book not found'},
            status=status.HTTP_404_NOT_FOUND
        )
```

Add URL to `apps/books/urls.py`:

```python
from django.urls import path
from .views import download_pdf

urlpatterns = [
    # ... existing patterns
    path('books/<int:book_id>/download-pdf/', download_pdf, name='download-pdf'),
]
```

### Step 2: Update Dashboard to Show Books with "Read" Button

Modify the books in your dashboard to include a read button that navigates to the reader:

```dart
// In dashboard.dart Library tab
GestureDetector(
  onTap: () {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookReaderScreen(
          bookId: book['id'],
          bookTitle: book['title'],
          authors: book['authors'],
          coverImage: book['cover_image'],
        ),
      ),
    );
  },
  child: // your book card UI
)
```

### Step 3: Install Dependencies

```bash
cd c:\Users\DevOps\Desktop\bbeta
flutter clean
flutter pub get
```

### Step 4: Run the App

```bash
flutter run
```

## 📱 Features

### User Experience
- **Responsive PDF Viewing**: Zoom, pan, scroll naturally
- **Page Navigation**: 
  - Next/Previous buttons
  - Jump to specific page via slider
  - Direct page number entry
- **Session Tracking**: Logs reading time and current page
- **Progress Indicator**: Visual progress bar showing position in book
- **Immersive Mode**: Tap screen to show/hide controls
- **Offline Support**: PDFs cached locally after first download

### Performance
- **Smart Caching**: PDFs cached after download (no re-downloading)
- **Lazy Loading**: PDF loaded in background while user sees loading indicator
- **Memory Efficient**: Only one page rendered at a time (pdfx package optimization)

## 🔧 Configuration

### Backend URL
Update the baseUrl in `pdf_reader_service.dart` if your backend IP changes:

```dart
// Currently configured to your PC IP
'http://192.168.1.7:8000/api/books/$bookId/download-pdf/'
```

### Cache Management
```dart
// Clear all cached PDFs
PDFReaderService().clearCache();

// Delete specific book PDF
PDFReaderService().deleteCachedPDF(bookId);

// Get cache size
int sizeInBytes = await PDFReaderService().getCachedBooksSize();
```

## 📊 Reading Statistics

The reader automatically tracks:
- **Current Page**: Logged every time page changes
- **Session Time**: Minutes spent reading (logged on exit)
- **Total Reading Time**: Can be summed from sessions

You can integrate this with your `/api/reading/progress/log-session/` endpoint:

```dart
// In _BookReaderScreenState.dispose()
if (_minutesSpent > 0) {
  await _api.logSession(
    bookId: widget.bookId,
    startPage: _firstPageRead,
    endPage: _currentPage,
    durationMinutes: _minutesSpent,
  );
}
```

## 📝 File Structure

```
lib/
├── screens/
│   └── book_reader_screen.dart          ← New book reader UI
├── services/
│   ├── api_service.dart                 (existing)
│   └── pdf_reader_service.dart          ← New PDF download/cache service
└── ...
```

## 🐛 Troubleshooting

### PDFs Won't Download
- Check backend URL in `pdf_reader_service.dart` matches your PC IP
- Verify Django is running: `python manage.py runserver 0.0.0.0:8000`
- Check `/api/books/{id}/download-pdf/` endpoint exists
- Ensure user is authenticated (JWT token saved)

### PDF Won't Display
- Check `pdfx` package is installed: `flutter pub get`
- Verify PDF file is valid (not corrupted)
- Check device has enough storage space

### Cache Issues
Clear the cache:
```bash
# In your app, call:
await PDFReaderService().clearCache();
```

## 📚 Integration Checklist

- [ ] Add PDF download endpoint to Django backend
- [ ] Update Book model to include `pdf_file` field (if not already)
- [ ] Run `python manage.py migrate` on backend
- [ ] Update Dashboard to show books with "Read" button
- [ ] Run `flutter clean && flutter pub get` on Flutter
- [ ] Test PDF download on physical device
- [ ] Test page navigation
- [ ] Verify reading session tracking works

## 🎯 Future Enhancements

Possible improvements:
- Bookmarks/highlights (save to `flutter_secure_storage`)
- Search within PDF
- Adjust font size (if using text-based PDFs)
- Night mode for reading
- Sync reading progress to backend
- Reading goals and streaks
- Export reading statistics

---

**Status**: Implementation complete, ready for backend integration
