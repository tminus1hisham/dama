import 'package:dama/models/blogs_model.dart';
import 'package:dama/services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

class BlogController extends GetxController {
  final ApiService _apiService = ApiService();

  // No caching all blogs, use paging per category
  final bool _hasFetchedCategories = false;

  // Paging controller for infinite scroll per category
  final PagingController<int, BlogPostModel> pagingController =
      PagingController(firstPageKey: 1);
  bool _isControllerDisposed = false;

  // Filtered blogs to display (for backward compatibility)
  var filteredBlogs = <BlogPostModel>[].obs;

  // Observables
  var categories = <String>[].obs;
  var isLoadingCategories = false.obs;
  var isLoadingBlogs = false.obs;
  var selectedCategory = 'All Blogs'.obs;
  var trendingBlogs = <BlogPostModel>[].obs;
  var categoryCounts = <String, int>{}.obs; // Map category -> count

  // Additional fields for compatibility
  bool _hasFetchedAllCategories = false;
  final _categoryBlogs = <BlogPostModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    // Set up paging controller for initial 'All Blogs'
    pagingController.addPageRequestListener((pageKey) {
      _fetchBlogsPage(pageKey);
    });
    fetchCategories();
  }

  @override
  void onClose() {
    _isControllerDisposed = true;
    pagingController.dispose();
    super.onClose();
  }

  Future<void> fetchCategories() async {
    try {
      isLoadingCategories.value = true;
      final fetchedCategories = await _apiService.getCategories();
      final filtered =
          fetchedCategories
              .where((cat) => cat.toLowerCase() != 'uncategorized')
              .map(
                (cat) => cat[0].toUpperCase() + cat.substring(1).toLowerCase(),
              )
              .toList();
      if (filtered.isNotEmpty) {
        categories.value = ['All Blogs', ...filtered];
      } else {
        categories.value = ['All Blogs'];
      }
    } catch (e) {
      categories.value = ['All Blogs'];
    } finally {
      isLoadingCategories.value = false;
    }
  }

  void _setFallbackCategories() {
    categories.value = ['All Blogs'];
  }

  /// Fetch a page of blogs for the current selected category
  Future<void> _fetchBlogsPage(int pageKey) async {
    try {
      isLoadingBlogs.value = true;
      final category =
          selectedCategory.value == 'All Blogs' ? null : selectedCategory.value;
      final blogs = await _apiService.getBlogs(
        page: pageKey,
        limit: 10,
        category: category,
      );

      final isLastPage = blogs.length < 10;

      // Check if controller is disposed before updating paging controller
      if (_isControllerDisposed) {
        return;
      }

      if (isLastPage) {
        pagingController.appendLastPage(blogs);
      } else {
        final nextPageKey = pageKey + 1;
        pagingController.appendPage(blogs, nextPageKey);
      }

      // Update filtered blogs for backward compatibility
      filteredBlogs.addAll(blogs);

      // Compute trending if first page
      if (pageKey == 1 && selectedCategory.value == 'All Blogs') {
        _computeTrendingBlogs(blogs);
      }
    } catch (error) {
      if (!_isControllerDisposed) {
        pagingController.error = error;
      }
    } finally {
      isLoadingBlogs.value = false;
    }
  }

  /// Compute trending blogs (simplified, using current page)
  void _computeTrendingBlogs(List<BlogPostModel> blogs) {
    final sorted = List<BlogPostModel>.from(blogs);
    sorted.sort((a, b) {
      final engagementA = a.likes.length + a.comments.length;
      final engagementB = b.likes.length + b.comments.length;
      return engagementB.compareTo(engagementA);
    });
    trendingBlogs.assignAll(sorted.take(10).toList());
  }

  void selectCategory(String category) {
    if (selectedCategory.value == category) return;
    selectedCategory.value = category;
    _applyFilter();
  }

  void _applyFilter() {
    pagingController.refresh();
  }

  Future<void> refreshBlogs() async {
    _hasFetchedAllCategories = false;
    _categoryBlogs.clear();
    await _fetchBlogsForCategories();
  }

  Future<void> fetchBlogs() async {
    if (!_hasFetchedAllCategories) {
      await _fetchBlogsForCategories();
    }
  }

  Future<void> fetchAllBlogs() async {
    await _fetchBlogsForCategories();
  }

  Future<void> _fetchBlogsForCategories() async {
    try {
      isLoadingBlogs.value = true;
      // Fetch all blogs with a large limit, starting from page 1
      final blogs = await _apiService.getBlogs(page: 1, limit: 1000);
      _categoryBlogs.assignAll(blogs);
      _hasFetchedAllCategories = true;
    } catch (error) {
    } finally {
      isLoadingBlogs.value = false;
    }
  }
}
