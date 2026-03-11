import 'package:dio/dio.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PDFReaderService {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const _accessKey = 'access_token';

  PDFReaderService() {
    // Create a dedicated Dio instance for PDF downloads with authentication
    _dio = Dio(BaseOptions(
      baseUrl: 'https://bud-ruby.vercel.app/api',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),  // Longer timeout for large files
    ));

    // Add auth header and error handling
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add authorization token
        final token = await _storage.read(key: _accessKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
          print('🔐 [PDF] Auth token attached');
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        print('❌ [PDF] Download error: ${error.message}');
        print('❌ [PDF] Status: ${error.response?.statusCode}');
        if (error.response?.data != null) {
          print('❌ [PDF] Response: ${error.response?.data}');
        }
        return handler.next(error);
      },
    ));
  }

  /// Download PDF from backend and cache it locally
  Future<File> downloadAndCachePDF(
    int bookId,
    String bookTitle,
  ) async {
    try {
      // Get app's documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final pdfDir = Directory('${appDir.path}/books');
      
      if (!pdfDir.existsSync()) {
        pdfDir.createSync(recursive: true);
        print('📁 [PDF] Created directory: ${pdfDir.path}');
      }

      // Use book ID as filename to avoid duplicates
      final filePath = '${pdfDir.path}/book_$bookId.pdf';
      final file = File(filePath);

      // Return cached file if it already exists
      if (file.existsSync()) {
        final fileSize = file.lengthSync();
        print('📄 [PDF] Using cached PDF: $filePath (${(fileSize / 1024).toStringAsFixed(1)} KB)');
        return file;
      }

      // Download PDF from backend
      print('📥 [PDF] Starting download for book $bookId: $bookTitle');
      print('📥 [PDF] Target URL: /books/$bookId/download-pdf/');
      print('📥 [PDF] Saving to: $filePath');
      
      int totalBytes = 0;
      final response = await _dio.download(
        '/books/$bookId/download-pdf/',
        filePath,
        onReceiveProgress: (received, total) {
          totalBytes = total;
          if (total != -1) {
            final percent = (received / total * 100).toStringAsFixed(1);
            final mb = (received / 1024 / 1024).toStringAsFixed(2);
            final totalMb = (total / 1024 / 1024).toStringAsFixed(2);
            print('📊 [PDF] Download: $percent% ($mb MB / $totalMb MB)');
          }
        },
      );

      print('✅ [PDF] Download complete. Status: ${response.statusCode}');
      
      // Verify file was created
      if (file.existsSync()) {
        final fileSize = file.lengthSync();
        print('✅ [PDF] File verified: ${(fileSize / 1024).toStringAsFixed(1)} KB');
        if (fileSize == 0) {
          throw Exception('Downloaded file is empty (0 bytes)');
        }
        return file;
      } else {
        throw Exception('Downloaded file not found at $filePath');
      }
    } on DioException catch (e) {
      print('❌ [PDF] Dio Error Type: ${e.type}');
      print('❌ [PDF] Error message: ${e.message}');
      print('❌ [PDF] Status code: ${e.response?.statusCode}');
      if (e.response?.data != null) {
        print('❌ [PDF] Response: ${e.response?.data}');
      }
      
      // Provide user-friendly error messages
      String errorMsg = e.message ?? 'Unknown error';
      if (e.type == DioExceptionType.connectionTimeout) {
        errorMsg = 'Connection timeout - check your internet';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMsg = 'Download timeout - file too large or slow connection';
      } else if (e.response?.statusCode == 404) {
        errorMsg = 'PDF not found on server';
      } else if (e.response?.statusCode == 401) {
        errorMsg = 'Not authenticated - please login again';
      } else if (e.response?.statusCode == 403) {
        errorMsg = 'Not authorized to download this book';
      }
      
      throw Exception(errorMsg);
    } catch (e) {
      print('❌ [PDF] Unexpected Error: $e');
      throw Exception('Failed to download PDF: $e');
    }
  }

  /// Delete cached PDF file
  Future<void> deleteCachedPDF(int bookId) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final filePath = '${appDir.path}/books/book_$bookId.pdf';
      final file = File(filePath);
      
      if (file.existsSync()) {
        await file.delete();
        print('🗑️ [PDF] Deleted cached PDF: $filePath');
      }
    } catch (e) {
      print('❌ [PDF] Delete failed: $e');
    }
  }

  /// Get cached PDF file if it exists
  Future<File?> getCachedPDF(int bookId) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final filePath = '${appDir.path}/books/book_$bookId.pdf';
      final file = File(filePath);
      
      if (file.existsSync()) {
        print('📄 [PDF] Found cached PDF: $filePath');
        return file;
      }
      return null;
    } catch (e) {
      print('❌ [PDF] Error accessing cached PDF: $e');
      return null;
    }
  }

  /// Get total size of cached books
  Future<int> getCachedBooksSize() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final pdfDir = Directory('${appDir.path}/books');
      
      if (!pdfDir.existsSync()) return 0;
      
      int totalSize = 0;
      final files = pdfDir.listSync();
      for (final file in files) {
        if (file is File) {
          totalSize += file.lengthSync();
        }
      }
      print('📊 [PDF] Total cached books size: ${(totalSize / 1024 / 1024).toStringAsFixed(2)} MB');
      return totalSize;
    } catch (e) {
      print('❌ [PDF] Error calculating cache size: $e');
      return 0;
    }
  }

  /// Clear all cached PDFs
  Future<void> clearCache() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final pdfDir = Directory('${appDir.path}/books');
      
      if (pdfDir.existsSync()) {
        pdfDir.deleteSync(recursive: true);
        print('🗑️ [PDF] Cleared all cached PDFs');
      }
    } catch (e) {
      print('❌ [PDF] Error clearing cache: $e');
    }
  }
}
