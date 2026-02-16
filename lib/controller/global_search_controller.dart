import 'dart:async';

import 'package:dama/services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class GlobalSearchController extends GetxController {
  final ApiService _searchService = ApiService();
  final RxBool isLoading = false.obs;
  final RxMap<String, dynamic> searchResults = <String, dynamic>{}.obs;
  final RxString searchQuery = ''.obs;

  Timer? _debounceTimer;

  Future<void> performSearch(String query) async {
    // Cancel any pending search
    _debounceTimer?.cancel();

    if (query.isEmpty) {
      clearSearch();
      return;
    }

    // Clear previous results immediately when query changes significantly
    if (query != searchQuery.value &&
        query.length < searchQuery.value.length - 1) {
      searchResults.value = {};
    }

    searchQuery.value = query;

    // Debounce: wait 300ms before actually searching
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      // Only set loading after debounce to avoid UI flicker
      if (query == searchQuery.value) {
        isLoading.value = true;
      }

      try {
        final results = await _searchService.search(query);
        // Only update if the query hasn't changed while waiting
        if (query == searchQuery.value) {
          searchResults.value = results['searchResult'] ?? {};
        }
      } catch (e) {
      } finally {
        if (query == searchQuery.value) {
          isLoading.value = false;
        }
      }
    });
  }

  void clearSearch() {
    _debounceTimer?.cancel();
    searchResults.value = {};
    searchQuery.value = '';
    isLoading.value = false;
  }

  @override
  void onClose() {
    _debounceTimer?.cancel();
    super.onClose();
  }
}
