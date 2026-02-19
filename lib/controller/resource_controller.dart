import 'package:dama/models/resources_model.dart';
import 'package:dama/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ResourceController extends GetxController {
  var resourceList = <ResourceModel>[].obs;
  var isLoading = false.obs;
  var isLoadingMore = false.obs;
  var hasMore = true.obs;
  var currentPage = 1.obs;

  final ApiService _resourceService = ApiService();
  final int _limit = 10;

  @override
  void onInit() {
    super.onInit();
    fetchResources();
  }

  Future<void> fetchResources({bool refresh = false}) async {
    if (refresh) {
      currentPage.value = 1;
      hasMore.value = true;
    }

    isLoading.value = true;
    try {
      List<ResourceModel> fetchedResources = await _resourceService.getResources(
        page: currentPage.value,
        limit: _limit,
      );

      if (refresh) {
        resourceList.assignAll(fetchedResources);
      } else {
        resourceList.addAll(fetchedResources);
      }

      // If fewer items than limit returned, no more pages
      hasMore.value = fetchedResources.length == _limit;
    } catch (e) {
      debugPrint('Error fetching resources: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMoreResources() async {
    if (isLoadingMore.value || !hasMore.value) return;

    isLoadingMore.value = true;
    currentPage.value++;

    try {
      List<ResourceModel> fetchedResources = await _resourceService.getResources(
        page: currentPage.value,
        limit: _limit,
      );

      resourceList.addAll(fetchedResources);

      // If fewer items than limit returned, no more pages
      hasMore.value = fetchedResources.length == _limit;
    } catch (e) {
      debugPrint('Error fetching resources: $e');
      currentPage.value--; // Revert page increment on error
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> refreshResources() async {
    return fetchResources(refresh: true);
  }
}
