import 'package:flutter/material.dart';
import 'package:bbeta/services/pdf_reader_service.dart';
import 'package:bbeta/services/api_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:pdfx/pdfx.dart';

const Color kTealDark = Color(0xFF0B4D40);
const Color kTealMid = Color(0xFF11755E);
const Color kTealLight = Color(0xFF1A9B7A);
const Color kAmber = Color(0xFFE8A838);

class BookReaderScreen extends StatefulWidget {
  final int bookId;
  final String bookTitle;
  final String? authors;
  final String? coverImage;
  final int initialPage;

  const BookReaderScreen({
    super.key,
    required this.bookId,
    required this.bookTitle,
    this.authors,
    this.coverImage,
    this.initialPage = 1,
  });

  @override
  State<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends State<BookReaderScreen> {
  final _pdfService = PDFReaderService();
  final _api = ApiService();
  late Future<PdfDocument> _pdfFuture;
  PdfController? _pdfController;
  
  int _currentPage = 1;
  int _startPage = 1;  // Track starting page for session logging
  int _totalPages = 0;
  bool _showControls = true;
  bool _pageJumpPending = false;  // Flag to jump to initial page once PDF loads
  
  // For reading session tracking
  late DateTime _sessionStartTime;
  int _minutesSpent = 0;

  @override
  void initState() {
    super.initState();
    _sessionStartTime = DateTime.now();
    _startPage = widget.initialPage;
    _currentPage = widget.initialPage;
    
    // Set flag if we need to jump to initial page
    if (widget.initialPage > 1) {
      _pageJumpPending = true;
    }
    
    print('========================================');
    print('📖 [Reader] SESSION STARTED');
    print('   Book ID: ${widget.bookId}');
    print('   Book Title: ${widget.bookTitle}');
    print('   Start Time: ${_sessionStartTime.toIso8601String()}');
    print('   Initial Page: ${widget.initialPage}');
    print('========================================');
    _pdfFuture = _loadPDF();
  }

  Future<PdfDocument> _loadPDF() async {
    try {
      print('📖 [Reader] Starting PDF load for book ID: ${widget.bookId}');
      
      // Check connectivity first
      final connectivity = await Connectivity().checkConnectivity();
      final isOffline = connectivity.isEmpty || 
          connectivity.every((r) => r == ConnectivityResult.none);
      
      // If offline, check if we have a cached version
      if (isOffline) {
        final cachedFile = await _pdfService.getCachedPDF(widget.bookId);
        if (cachedFile == null) {
          throw Exception('You\'re offline and this book hasn\'t been downloaded yet. '
              'Please connect to the internet or download books for offline reading.');
        }
        print('📖 [Reader] Offline mode - using cached PDF');
      }
      
      final pdfFile = await _pdfService.downloadAndCachePDF(
        widget.bookId,
        widget.bookTitle,
      );
      print('📖 [Reader] PDF downloaded/cached: ${pdfFile.path}');
      
      final document = await PdfDocument.openFile(pdfFile.path);
      if (mounted) {
        setState(() {
          _totalPages = document.pagesCount;
          _pdfController = PdfController(document: Future.value(document));
          print('✅ [Reader] PDF loaded successfully - Total pages: $_totalPages');
          print('✅ [Reader] Starting from page: $_currentPage');
        });
        
        if (_pageJumpPending && widget.initialPage > 1) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted && _pdfController != null) {
              _pdfController!.jumpToPage(widget.initialPage);
              print('📖 [Reader] Jumped to initial page: ${widget.initialPage}');
              _pageJumpPending = false;
            }
          });
        }
      }
      return document;
    } catch (e) {
      print('❌ [Reader] Error loading PDF: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    // Track reading session
    _minutesSpent = DateTime.now().difference(_sessionStartTime).inMinutes;
    print('========================================');
    print('📚 [Reader] READING SESSION SUMMARY');
    print('   Book ID: ${widget.bookId}');
    print('   Book Title: ${widget.bookTitle}');
    print('   Start Page: $_startPage');
    print('   End Page: $_currentPage');
    print('   Pages Read: ${(_currentPage - _startPage + 1)}');
    print('   Time Spent: $_minutesSpent minutes');
    print('========================================');
    
    // Log session to backend if user spent time or read pages
    if (_minutesSpent >= 1 || _currentPage != _startPage) {
      print('📖 [Reader] Sending session to backend...');
      _logReadingSession();
    } else {
      print('⏭️ [Reader] Session too short, not logging');
    }
    
    _pdfController?.dispose();
    super.dispose();
  }

  Future<void> _logReadingSession() async {
    try {
      print('📤 [Reader] POST /reading/progress/log-session/');
      print('   bookId: ${widget.bookId}');
      print('   startPage: $_startPage');
      print('   endPage: $_currentPage');
      print('   durationMinutes: $_minutesSpent');
      
      final response = await _api.logSession(
        bookId: widget.bookId,
        startPage: _startPage,
        endPage: _currentPage,
        durationMinutes: _minutesSpent,
      );
      
      print('📥 [Reader] Response ${response.statusCode}: /reading/progress/log-session/');
      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ [Reader] Session logged successfully!');
        print('   Response: ${response.data}');
      } else {
        print('⚠️ [Reader] Unexpected status code: ${response.statusCode}');
        print('   Response: ${response.data}');
      }
    } catch (e) {
      print('❌ [Reader] Error logging session: $e');
    }
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  void _goToPreviousPage() {
    if (_currentPage > 1 && _pdfController != null) {
      _pdfController!.previousPage(curve: Curves.easeInOut, duration: const Duration(milliseconds: 300));
    }
  }

  void _goToNextPage() {
    if (_currentPage < _totalPages && _pdfController != null) {
      _pdfController!.nextPage(curve: Curves.easeInOut, duration: const Duration(milliseconds: 300));
    }
  }

  void _goToPage(int page) {
    if (page > 0 && page <= _totalPages && _pdfController != null) {
      _pdfController!.jumpToPage(page);
      Navigator.pop(context);
    }
  }

  void _showPageNavigator() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Go to Page',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: kTealDark,
                  ),
            ),
            const SizedBox(height: 20),
            Slider(
              value: _currentPage.toDouble(),
              min: 1,
              max: _totalPages.toDouble(),
              divisions: _totalPages > 1 ? _totalPages - 1 : 1,
              label: '$_currentPage / $_totalPages',
              activeColor: kTealMid,
              onChanged: (value) {
                _goToPage(value.toInt());
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Enter page number',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onSubmitted: (value) {
                      final page = int.tryParse(value);
                      if (page != null) {
                        _goToPage(page);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<PdfDocument>(
        future: _pdfFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: kTealMid),
                  const SizedBox(height: 20),
                  Text(
                    'Loading "${widget.bookTitle}"...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            final error = snapshot.error.toString();
            print('❌ [Reader] Display error state: $error');
            return Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 60),
                    const SizedBox(height: 20),
                    Text(
                      'Failed to load PDF',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        error,
                        style: const TextStyle(color: Colors.orange, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            print('📖 [Reader] Retrying PDF load');
                            setState(() {
                              _pdfFuture = _loadPDF();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kTealMid,
                          ),
                          child: const Text('Retry'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade600,
                          ),
                          child: const Text('Go Back'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text('No PDF file found', style: TextStyle(color: Colors.white)),
            );
          }

          return _buildPDFViewer(snapshot.data!);
        },
      ),
    );
  }

  Widget _buildPDFViewer(PdfDocument document) {
    return GestureDetector(
      onTap: _toggleControls,
      child: Stack(
        children: [
          // PDF Viewer
          if (_pdfController != null)
            PdfView(
              controller: _pdfController!,
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page;
                  print('📖 [Reader] Page changed: $page / $_totalPages (distance: ${_currentPage - _startPage} pages)');
                });
              },
            )
          else
            const Center(
              child: CircularProgressIndicator(color: kTealMid),
            ),

          // Top bar with title and controls
          if (_showControls)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
                padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 8, 16, 20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.bookTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Page $_currentPage / $_totalPages',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Bottom controls
          if (_showControls)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _totalPages > 0 ? _currentPage / _totalPages : 0,
                        minHeight: 4,
                        backgroundColor: Colors.grey.shade700,
                        valueColor: const AlwaysStoppedAnimation<Color>(kTealMid),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Control buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Previous page
                        IconButton(
                          icon: const Icon(Icons.chevron_left, color: Colors.white),
                          iconSize: 32,
                          onPressed: _goToPreviousPage,
                        ),

                        // Page selector
                        GestureDetector(
                          onTap: _showPageNavigator,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$_currentPage / $_totalPages',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        // Next page
                        IconButton(
                          icon: const Icon(Icons.chevron_right, color: Colors.white),
                          iconSize: 32,
                          onPressed: _goToNextPage,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
