import 'package:dama/models/news_model.dart';
import 'package:dama/services/api_service.dart';
import 'package:dama/services/local_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

/// Model class for category with count
class CategoryWithCount {
  final String name;
  final int count;

  CategoryWithCount({required this.name, required this.count});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryWithCount &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;
}

class NewsController extends GetxController {
  final ApiService _apiService = ApiService();

  // Cache ALL news fetched from API
  final List<NewsModel> _allNews = [];
  List<NewsModel> _firstPageNews = [];
  bool _hasFetchedAll = false;
  bool _isFetching = false;
  bool _isBackgroundFetching = false;
  bool _cancelBackgroundFetch = false;

  final PagingController<int, NewsModel> pagingController = PagingController(
    firstPageKey: 1,
  );
  bool _isControllerDisposed = false;
  var filteredNews = <NewsModel>[].obs;
  var trendingNews = <NewsModel>[].obs;
  var popularNews = <NewsModel>[].obs;

  // Initialize with 'All News' only
  var categories = <String>['All News'].obs;

  var categoryCounts = <String, int>{}.obs; // Map category -> count
  var isLoadingCategories = false.obs;
  var isLoadingNews = false.obs;
  var selectedCategory = 'All News'.obs;
  var categorySearchQuery = ''.obs; // For filtering categories

  // Search within categories
  var filteredCategories = <String>[].obs;

  // Keyword mappings for content-based category inference
  final Map<String, List<String>> _categoryKeywords = {
    'TECHNOLOGY': [
      'ai',
      'software',
      'tech',
      'computer',
      'data',
      'cloud',
      'digital',
      'code',
      'coding',
      'developer',
      'app',
      'cyber',
      'robot',
      'machine learning',
      'ml',
      'database',
      'server',
      'network',
      'internet',
      'chip',
      'semiconductor',
      'ibm',
      'google',
      'microsoft',
      'apple',
      'meta',
      'openai',
      'nvidia',
      'intel',
      'amd',
      'oracle',
      'amazon',
      'aws',
      'azure',
    ],
    'HEALTH': [
      'health',
      'medical',
      'hospital',
      'doctor',
      'patient',
      'disease',
      'treatment',
      'drug',
      'pharma',
      'vaccine',
      'cancer',
      'diabetes',
      'heart',
      'mental health',
      'therapy',
      'medicine',
      'surgery',
      'clinical',
      'wellness',
      'fitness',
      'nutrition',
      'diet',
    ],
    'FOOD': [
      'food',
      'restaurant',
      'cooking',
      'recipe',
      'chef',
      'meal',
      'eat',
      'drink',
      'nutrition',
      'agriculture',
      'farm',
      'crop',
      'harvest',
      'coffee',
      'tea',
      'wine',
      'food security',
    ],
    'BUSINESS': [
      'business',
      'company',
      'startup',
      'ceo',
      'founder',
      'investor',
      'investment',
      'fund',
      'revenue',
      'profit',
      'market',
      'stock',
      'shares',
      'ipo',
      'merger',
      'acquisition',
      'billion',
      'million',
      'revenue',
      'growth',
      'economy',
      'economic',
      'financial',
      'finance',
      'bank',
      'banking',
      'trade',
      'commerce',
    ],
    'POLITICS': [
      'government',
      'president',
      'minister',
      'policy',
      'law',
      'election',
      'vote',
      'political',
      'politics',
      'congress',
      'parliament',
      'legislation',
      'bill',
      'party',
      'democrat',
      'republican',
      'ruling',
      'opposition',
      'campaign',
      'speech',
      'summit',
      'treaty',
      'diplomatic',
    ],
    'SCIENCE': [
      'science',
      'research',
      'scientist',
      'study',
      'discovery',
      'experiment',
      'laboratory',
      'lab',
      'physics',
      'chemistry',
      'biology',
      'space',
      'nasa',
      'spacex',
      'climate',
      'environment',
      'energy',
      'solar',
      'quantum',
      'genome',
      'dna',
      'mit',
      'university',
    ],
    'SPORTS': [
      'sport',
      'sports',
      'football',
      'soccer',
      'basketball',
      'tennis',
      'golf',
      'cricket',
      'rugby',
      'athlete',
      'player',
      'team',
      'match',
      'game',
      'win',
      'championship',
      'league',
      'tournament',
      'olympic',
      'medal',
      'score',
      'coach',
    ],
    'ENTERTAINMENT': [
      'movie',
      'film',
      'music',
      'song',
      'album',
      'artist',
      'actor',
      'actress',
      'celebrity',
      'Hollywood',
      'Netflix',
      'streaming',
      'series',
      'show',
      'tv',
      'television',
      'theater',
      'concert',
      'festival',
      'award',
      'Oscar',
      'Grammy',
      'Beyonce',
      'Taylor Swift',
    ],
    'EDUCATION': [
      'education',
      'school',
      'university',
      'college',
      'student',
      'teacher',
      'professor',
      'course',
      'degree',
      'learning',
      'training',
      'academic',
      'scholarship',
      'campus',
      'class',
      'curriculum',
      'exam',
      'MIT',
      'Harvard',
      'student',
      'academy',
    ],
    'TRAVEL': [
      'travel',
      'trip',
      'vacation',
      'tourism',
      'tourist',
      'hotel',
      'flight',
      'airline',
      'airport',
      'destination',
      'holiday',
      'cruise',
      'visa',
      'passport',
      'adventure',
      'explore',
      'visit',
      'guide',
    ],
  };

  /// Infer category from news title using keywords
  String _inferCategory(String title) {
    final lowerTitle = title.toLowerCase();

    for (final entry in _categoryKeywords.entries) {
      for (final keyword in entry.value) {
        if (lowerTitle.contains(keyword)) {
          return entry.key;
        }
      }
    }
    return 'UNCATEGORIZED';
  }

  /// Get category for a news item (from API or inferred)
  String _getCategoryForNews(NewsModel news) {
    // First try API category
    final apiCategory = (news.category ?? '').trim().toUpperCase();
    if (apiCategory.isNotEmpty &&
        apiCategory != 'NULL' &&
        apiCategory != 'UNCATEGORIZED') {
      return apiCategory;
    }
    // Fall back to content-based inference
    return _inferCategory(news.title);
  }

  @override
  void onInit() {
    super.onInit();
    _initData();
  }

  Future<void> _initData() async {
    final token = await StorageService.getData('access_token');
    if (token != null && token.isNotEmpty) {
      fetchCategories();
      fetchPopularNews();
      _fetchNewsProgressively(); // Load all news progressively like blogs
    }
  }

  @override
  void onClose() {
    _isControllerDisposed = true;
    pagingController.dispose();
    super.onClose();
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final news = await _apiService.getNews(page: pageKey, limit: 50);
      _allNews.addAll(news);
      _computeTrendingNews();
      _updateCategoryCounts();
      _applyFilter();

      // Check if controller is disposed before updating paging controller
      if (_isControllerDisposed) {
        return;
      }

      final isLastPage = news.length < 10;
      if (isLastPage) {
        pagingController.appendLastPage(news);
      } else {
        pagingController.appendPage(news, pageKey + 1);
      }
    } catch (e) {
      if (!_isControllerDisposed) {
        pagingController.error = e;
      }
    }
  }

  /// Normalize category name for consistent matching
  String _normalizeCategory(String category) {
    return category.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Extract category from various API response formats
  String _extractCategory(dynamic categoryData) {
    if (categoryData == null) return '';
    if (categoryData is String) return _normalizeCategory(categoryData);
    if (categoryData is Map<String, dynamic>) {
      return _normalizeCategory(categoryData['name']?.toString() ?? '');
    }
    return _normalizeCategory(categoryData.toString());
  }

  /// Update category counts after news is loaded
  void _updateCategoryCounts() {
    final counts = <String, int>{};

    // Count for "All News"
    counts['All News'] = _allNews.length;

    for (final news in _allNews) {
      final category = _getCategoryForNews(news);
      // Store counts with proper casing (first letter uppercase)
      final normalized = category.toUpperCase();
      final displayName =
          normalized[0].toUpperCase() + normalized.substring(1).toLowerCase();
      counts[displayName] = (counts[displayName] ?? 0) + 1;
    }

    categoryCounts.value = counts;

    // Update filtered categories based on search
    _filterCategories();
  }

  /// Filter categories based on search query
  void _filterCategories() {
    final query = categorySearchQuery.value.trim().toLowerCase();
    if (query.isEmpty) {
      filteredCategories.value = categories.toList();
    } else {
      filteredCategories.value =
          categories.where((cat) {
            return cat.toLowerCase().contains(query);
          }).toList();
    }
  }

  /// Search categories
  void searchCategories(String query) {
    categorySearchQuery.value = query;
    _filterCategories();
  }

  /// Clear category search
  void clearCategorySearch() {
    categorySearchQuery.value = '';
    _filterCategories();
  }

  /// Get count for a specific category
  int getCategoryCount(String category) {
    return categoryCounts[category] ?? 0;
  }

  Future<void> fetchCategories() async {
    try {
      isLoadingCategories.value = true;
      final fetchedCategories = await _apiService.getCategories();
      final filtered =
          fetchedCategories
              .where((cat) => _normalizeCategory(cat) != 'uncategorized')
              .map(
                (cat) => cat[0].toUpperCase() + cat.substring(1).toLowerCase(),
              )
              .toList();
      if (filtered.isNotEmpty) {
        categories.value = ['All News', ...filtered];
      } else {
        categories.value = ['All News'];
      }
      _filterCategories();
    } catch (e) {
      categories.value = ['All News'];
      _filterCategories();
    } finally {
      isLoadingCategories.value = false;
    }
  }

  Future<void> fetchPopularNews() async {
    try {
      debugPrint('Fetching popular news...');
      final category = selectedCategory.value == 'All News' 
          ? null 
          : selectedCategory.value;
      final popular = await _apiService.getPopularNews(limit: 10, category: category);
      debugPrint('Popular news fetched: ${popular.length} items');
      
      // If API returns empty for a specific category, try fetching all and filter client-side
      if (popular.isEmpty && category != null) {
        debugPrint('API returned empty for category $category, fetching all and filtering client-side');
        final allPopular = await _apiService.getPopularNews(limit: 50);
        popularNews.value = allPopular;
      } else {
        popularNews.value = popular;
      }
    } catch (e) {
      debugPrint('Error fetching popular news: $e');
      // Fallback: compute from all news if API fails
      _computeTrendingNews();
    }
  }
  
  /// Get filtered popular news based on selected category
  List<NewsModel> get filteredPopularNews {
    final selected = selectedCategory.value.trim().toUpperCase();
    if (selected == 'ALL NEWS') return popularNews;
    
    return popularNews.where((news) {
      final newsCat = _getCategoryForNews(news);
      return newsCat == selected;
    }).toList();
  }

  Future<void> _fetchNewsProgressively() async {
    if (_isFetching) return;
    if (_hasFetchedAll && _allNews.isNotEmpty) {
      _applyFilter();
      return;
    }
    _isFetching = true;
    try {
      isLoadingNews.value = true;
      _allNews.clear();
      // Fetch first page and show immediately
      final firstPageNews = await _apiService.getNews(page: 1, limit: 10);
      _allNews.addAll(firstPageNews);
      _firstPageNews = firstPageNews;
      _computeTrendingNews();
      _updateCategoryCounts(); // Update category counts
      _applyFilter();
      isLoadingNews.value = false;

      // Append to paging controller
      if (_isControllerDisposed) {
        return;
      }
      if (_firstPageNews.length >= 10) {
        pagingController.appendPage(_firstPageNews, 2);
      } else {
        pagingController.appendLastPage(_firstPageNews);
      }

      // Continue fetching remaining pages in background
      if (firstPageNews.length >= 10) {
        _fetchRemainingPagesInBackground();
      } else {
        _hasFetchedAll = true;
      }
    } catch (e) {
      if (!_isControllerDisposed) {
        pagingController.error = e;
      }
      isLoadingNews.value = false;
    } finally {
      _isFetching = false;
    }
  }

  Future<void> _fetchRemainingPagesInBackground() async {
    if (_isBackgroundFetching) return;
    _isBackgroundFetching = true;
    int page = 2;
    const int limit = 10;
    bool hasMore = true;
    while (hasMore) {
      if (_cancelBackgroundFetch) {
        _isBackgroundFetching = false;
        break;
      }
      try {
        final news = await _apiService.getNews(page: page, limit: limit);
        _allNews.addAll(news);
        // Update trending and filtered list periodically (every 3 pages)
        if (page % 3 == 0) {
          _computeTrendingNews();
          _applyFilter();
        }
        if (news.length < limit) {
          hasMore = false;
        } else {
          page++;
        }
      } catch (e) {
        hasMore = false;
      }
    }
    _hasFetchedAll = true;
    _isBackgroundFetching = false;

    // Append remaining news to paging controller
    if (_firstPageNews.length >= 50) {
      pagingController.appendLastPage(_allNews.sublist(_firstPageNews.length));
    }

    _computeTrendingNews();
    _updateCategoryCounts(); // Update category counts after all news loaded
    _applyFilter();
  }

  void _computeTrendingNews() {
    final selected = selectedCategory.value.trim().toUpperCase();
    
    // Filter by category if not "All News"
    final filtered = selected == 'ALL NEWS'
        ? _allNews
        : _allNews.where((news) {
            final newsCat = _getCategoryForNews(news);
            return newsCat == selected;
          }).toList();
    
    final sorted = List<NewsModel>.from(filtered);
    sorted.sort((a, b) {
      final engagementA = a.likes.length + a.comments.length;
      final engagementB = b.likes.length + b.comments.length;
      return engagementB.compareTo(engagementA);
    });
    trendingNews.assignAll(sorted.take(10).toList());
  }

  void _applyFilter() {
    List<NewsModel> filtered;
    final selected = selectedCategory.value.trim().toUpperCase();

    // Debug logging
    debugPrint('_applyFilter called with category: $selected');
    debugPrint('_allNews count: ${_allNews.length}');

    if (selected == 'ALL NEWS') {
      filtered = List.from(_allNews);
    } else {
      filtered =
          _allNews.where((news) {
            final newsCat = _getCategoryForNews(news);
            return newsCat == selected;
          }).toList();
    }

    filteredNews.assignAll(filtered);
    pagingController.value = PagingState(nextPageKey: null, itemList: filtered);
  }

  void selectCategory(String category) {
    if (selectedCategory.value == category) return;
    selectedCategory.value = category;
    
    // Refetch popular news for the new category
    fetchPopularNews();
    
    _applyFilter();
  }

  Future<void> refreshNews() async {
    _cancelBackgroundFetch = true;
    _isBackgroundFetching = false;
    _hasFetchedAll = false;
    _allNews.clear();
    pagingController.value = PagingState(nextPageKey: 1, itemList: []);
    _cancelBackgroundFetch = false;
    await _fetchNewsProgressively();
  }
}
