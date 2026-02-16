import 'package:dama/models/blogs_model.dart';
import 'package:dama/models/news_model.dart';
import 'package:dama/services/api_service.dart';
import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

class FeedController extends GetxController {
  static const int _pageSize = 10;
  final PagingController<int, dynamic> pagingController = PagingController(
    firstPageKey: 1,
  );
  bool _isControllerDisposed = false;

  final ApiService _apiService = ApiService();

  // Keep these for backward compatibility if needed elsewhere
  var isLoading = false.obs;
  var blogs = <BlogPostModel>[].obs;
  var news = <NewsModel>[].obs;

  @override
  void onInit() {
    pagingController.addPageRequestListener((pageKey) {
      fetchPagedFeed(pageKey);
    });
    super.onInit();
  }

  Future<void> fetchPagedFeed(int pageKey) async {
    try {
      // Fetch both blogs and news
      final fetchedBlogs = await _apiService.getBlogs(
        page: pageKey,
        limit: _pageSize,
      );
      final fetchedNews = await _apiService.getNews(
        page: pageKey,
        limit: _pageSize,
      );

      // Combine blogs and news into a single list
      final List<dynamic> combinedFeed = [];

      // Add blogs to combined feed
      combinedFeed.addAll(fetchedBlogs);

      // Add news to combined feed
      combinedFeed.addAll(fetchedNews);

      // Sort by creation date (most recent first)
      combinedFeed.sort((a, b) {
        // Handle both DateTime objects and String dates
        DateTime dateA;
        DateTime dateB;

        if (a.createdAt is String) {
          dateA = DateTime.parse(a.createdAt);
        } else {
          dateA = a.createdAt;
        }

        if (b.createdAt is String) {
          dateB = DateTime.parse(b.createdAt);
        } else {
          dateB = b.createdAt;
        }

        return dateB.compareTo(dateA);
      });

      // Update the observable lists for backward compatibility
      if (pageKey == 1) {
        blogs.assignAll(fetchedBlogs);
        news.assignAll(fetchedNews);
      } else {
        blogs.addAll(fetchedBlogs);
        news.addAll(fetchedNews);
      }

      // Check if controller is disposed before updating paging controller
      if (_isControllerDisposed) {
        return;
      }

      // Check if this is the last page based on the combined feed size
      final totalItems = fetchedBlogs.length + fetchedNews.length;
      final isLastPage = totalItems < _pageSize;

      if (isLastPage) {
        pagingController.appendLastPage(combinedFeed);
      } else {
        final nextPageKey = pageKey + 1;
        pagingController.appendPage(combinedFeed, nextPageKey);
      }
    } catch (error) {
      print('Error fetching feed: $error');
      if (!_isControllerDisposed) {
        pagingController.error = error;
      }
    }
  }

  // Keep the old method for backward compatibility
  Future<void> fetchFeed() async {
    isLoading.value = true;
    try {
      final fetchedBlogs = await _apiService.getBlogs(
        page: 1,
        limit: _pageSize,
      );
      final fetchedNews = await _apiService.getNews(page: 1, limit: _pageSize);

      blogs.assignAll(fetchedBlogs);
      news.assignAll(fetchedNews);
    } catch (e) {
      print(e);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    _isControllerDisposed = true;
    pagingController.dispose();
    super.onClose();
  }
}
