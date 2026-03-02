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
  // Track seen news IDs to prevent duplicates
  final Set<String> _seenNewsIds = {};
  List<NewsModel> _firstPageNews = [];
  bool _hasFetchedAll = false;
  bool _isFetching = false;
  bool _isBackgroundFetching = false;

  // ✅ Generation counter replaces the fragile boolean cancel flag
  int _fetchGeneration = 0;

  final PagingController<int, NewsModel> pagingController = PagingController(
    firstPageKey: 1,
  );
  bool _isControllerDisposed = false;
  var filteredNews = <NewsModel>[].obs;
  var trendingNews = <NewsModel>[].obs;
  var popularNews = <NewsModel>[].obs;

  // Initialize with 'All News' only
  var categories = <String>['All News'].obs;

  var categoryCounts = <String, int>{}.obs;
  var isLoadingCategories = false.obs;
  var isLoadingNews = false.obs;
  var selectedCategory = 'All News'.obs;
  var categorySearchQuery = ''.obs;

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
    final apiCategory = (news.category ?? '').trim().toUpperCase();
    if (apiCategory.isNotEmpty &&
        apiCategory != 'NULL' &&
        apiCategory != 'UNCATEGORIZED') {
      return apiCategory;
    }
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
      if (_allNews.isEmpty && filteredNews.isEmpty) {
        await _fetchNewsProgressively();
      }
      fetchPopularNews();
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
      var news = await _apiService.getNews(page: pageKey, limit: 50);
      news.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _addNewsWithDeduplication(news);
      _computeTrendingNews();
      _updateCategoryCounts();
      _applyFilter();

      if (_isControllerDisposed) return;

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

  String _normalizeCategory(String category) {
    return category.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  String _extractCategory(dynamic categoryData) {
    if (categoryData == null) return '';
    if (categoryData is String) return _normalizeCategory(categoryData);
    if (categoryData is Map<String, dynamic>) {
      return _normalizeCategory(categoryData['name']?.toString() ?? '');
    }
    return _normalizeCategory(categoryData.toString());
  }

  void _updateCategoryCounts() {
    final counts = <String, int>{};
    counts['All News'] = _allNews.length;

    for (final news in _allNews) {
      final category = _getCategoryForNews(news);
      final normalized = category.toUpperCase();
      final displayName =
          normalized[0].toUpperCase() + normalized.substring(1).toLowerCase();
      counts[displayName] = (counts[displayName] ?? 0) + 1;
    }

    categoryCounts.value = counts;
    _filterCategories();
  }

  void _filterCategories() {
    final query = categorySearchQuery.value.trim().toLowerCase();
    if (query.isEmpty) {
      filteredCategories.value = categories.toList();
    } else {
      filteredCategories.value =
          categories.where((cat) => cat.toLowerCase().contains(query)).toList();
    }
  }

  void searchCategories(String query) {
    categorySearchQuery.value = query;
    _filterCategories();
  }

  void clearCategorySearch() {
    categorySearchQuery.value = '';
    _filterCategories();
  }

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
      categories.value =
          filtered.isNotEmpty ? ['All News', ...filtered] : ['All News'];
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
      final category =
          selectedCategory.value == 'All News'
              ? null
              : selectedCategory.value;
      final popular =
          await _apiService.getPopularNews(limit: 10, category: category);
      debugPrint('Popular news fetched: ${popular.length} items');

      if (popular.isEmpty && category != null) {
        debugPrint(
          'API returned empty for category $category, fetching all and filtering client-side',
        );
        final allPopular = await _apiService.getPopularNews(limit: 50);
        popularNews.value = allPopular;
      } else {
        popularNews.value = popular;
      }
    } catch (e) {
      debugPrint('Error fetching popular news: $e');
      if (trendingNews.isNotEmpty) {
        popularNews.value = trendingNews;
        debugPrint(
          'Using trending news as fallback for popular news: ${trendingNews.length} items',
        );
      } else if (_allNews.isNotEmpty) {
        _computeTrendingNews();
        popularNews.value = trendingNews;
        debugPrint(
          'Computed trending as fallback for popular news: ${trendingNews.length} items',
        );
      } else {
        debugPrint('No news available for popular news fallback');
      }
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

  /// Add news to _allNews with deduplication
  void _addNewsWithDeduplication(List<NewsModel> newNews) {
    for (final news in newNews) {
      if (!_seenNewsIds.contains(news.id)) {
        _seenNewsIds.add(news.id);
        _allNews.add(news);
      }
    }
  }

  Future<void> _fetchNewsProgressively() async {
    if (_isFetching) return;
    if (_hasFetchedAll && _allNews.isNotEmpty) {
      _applyFilter();
      return;
    }

    _isFetching = true;

    // ✅ Increment generation — invalidates any running background fetch
    final int myGeneration = ++_fetchGeneration;
    _isBackgroundFetching = false;

    try {
      isLoadingNews.value = true;
      _allNews.clear();
      _seenNewsIds.clear(); // Clear deduplication set too
      _firstPageNews = [];
      pagingController.value = PagingState(nextPageKey: 1, itemList: []);

      final firstPageNews = await _apiService.getNews(page: 1, limit: 10);

      // ✅ Bail out if a newer fetch has already started
      if (myGeneration != _fetchGeneration) return;

      _addNewsWithDeduplication(firstPageNews);
      _firstPageNews = List.from(firstPageNews);
      _computeTrendingNews();
      _updateCategoryCounts();
      _applyFilter();
      isLoadingNews.value = false;

      if (!_isControllerDisposed) {
        if (_firstPageNews.length >= 10) {
          pagingController.appendPage(_firstPageNews, 2);
        } else {
          pagingController.appendLastPage(_firstPageNews);
        }
      }

      if (firstPageNews.length >= 10) {
        _fetchRemainingPagesInBackground(myGeneration);
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

  Future<void> _fetchRemainingPagesInBackground(int generation) async {
    if (_isBackgroundFetching) return;
    _isBackgroundFetching = true;
    int page = 2;
    const int limit = 10;
    bool hasMore = true;

    while (hasMore) {
      // ✅ Stop if a newer fetch has started
      if (generation != _fetchGeneration) {
        _isBackgroundFetching = false;
        return;
      }

      try {
        final news = await _apiService.getNews(page: page, limit: limit);

        // ✅ Check AGAIN after the await — prevents stale data being added
        if (generation != _fetchGeneration) {
          _isBackgroundFetching = false;
          return;
        }

        _addNewsWithDeduplication(news);

        if (page % 3 == 0) {
          _computeTrendingNews();
          _applyFilter();
        }

        hasMore = news.length >= limit;
        if (hasMore) page++;
      } catch (e) {
        hasMore = false;
      }
    }

    _hasFetchedAll = true;
    _isBackgroundFetching = false;
    _computeTrendingNews();
    _updateCategoryCounts();
    _applyFilter();
  }

  void _computeTrendingNews() {
    final selected = selectedCategory.value.trim().toUpperCase();

    final filtered =
        selected == 'ALL NEWS'
            ? _allNews
            : _allNews.where((news) {
                final newsCat = _getCategoryForNews(news);
                return newsCat == selected;
              }).toList();

    final sortedByDate = List<NewsModel>.from(filtered);
    sortedByDate.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final sorted = List<NewsModel>.from(sortedByDate);
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

    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // ✅ assignAll replaces the list — no duplicates
    filteredNews.assignAll(filtered);
    pagingController.value = PagingState(nextPageKey: null, itemList: filtered);
  }

  void selectCategory(String category) {
    if (selectedCategory.value == category) return;
    selectedCategory.value = category;
    _applyFilter();
    _computeTrendingNews();
    fetchPopularNews();
  }

  Future<void> refreshNews() async {
    // ✅ Incrementing generation cancels any in-flight background fetch
    _fetchGeneration++;
    _hasFetchedAll = false;
    _isBackgroundFetching = false;
    _isFetching = false; // Reset fetch flag to allow refresh
    _allNews.clear();
    _seenNewsIds.clear(); // Clear deduplication set too
    pagingController.value = PagingState(nextPageKey: 1, itemList: []);
    await _fetchNewsProgressively();
    fetchPopularNews();
  }
}