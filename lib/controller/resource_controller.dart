import 'package:dama/models/resources_model.dart';
import 'package:dama/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ResourceController extends GetxController {
  var resourceList = <ResourceModel>[].obs;
  var relatedResources = <ResourceModel>[].obs;
  var isLoading = false.obs;
  var isLoadingMore = false.obs;
  var isLoadingRelated = false.obs;
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

  /// Fetch related resources (same category, excluding current resource)
  Future<void> fetchRelatedResources(String currentResourceId) async {
    debugPrint('=== fetchRelatedResources called ===');
    debugPrint('Current resource ID: $currentResourceId');
    isLoadingRelated.value = true;
    try {
      List<ResourceModel> allResources = await _resourceService.getResources(
        page: 1,
        limit: 50, // Get more to have variety for related items
      );

      debugPrint('Fetched ${allResources.length} total resources');
      
      // Filter out current resource and get 3-4 similar ones
      final filtered = allResources
          .where((r) => r.id != currentResourceId)
          .take(4)
          .toList();
      
      debugPrint('Filtered to ${filtered.length} related resources');
      for (var r in filtered) {
        debugPrint('  - ${r.title} (${r.id})');
      }
      
      relatedResources.assignAll(filtered);
      debugPrint('relatedResources.length: ${relatedResources.length}');
      update(); // Notify GetBuilder listeners
    } catch (e) {
      debugPrint('Error fetching related resources: $e');
      relatedResources.clear();
      update(); // Notify GetBuilder listeners
    } finally {
      isLoadingRelated.value = false;
    }
  }

  /// Update a resource's rating locally after user submits a rating
  void updateResourceRating(String resourceId, double newAverageRating) {
    // Update in main resource list
    final index = resourceList.indexWhere((r) => r.id == resourceId);
    if (index != -1) {
      final oldResource = resourceList[index];
      resourceList[index] = ResourceModel(
        id: oldResource.id,
        title: oldResource.title,
        price: oldResource.price,
        description: oldResource.description,
        resourceLink: oldResource.resourceLink,
        ratings: oldResource.ratings,
        resourceImageUrl: oldResource.resourceImageUrl,
        createdAt: oldResource.createdAt,
        averageRating: newAverageRating,
      );
      debugPrint('[ResourceController] Updated rating for resource $resourceId to $newAverageRating');
    }

    // Also update in related resources if present
    final relatedIndex = relatedResources.indexWhere((r) => r.id == resourceId);
    if (relatedIndex != -1) {
      final oldResource = relatedResources[relatedIndex];
      relatedResources[relatedIndex] = ResourceModel(
        id: oldResource.id,
        title: oldResource.title,
        price: oldResource.price,
        description: oldResource.description,
        resourceLink: oldResource.resourceLink,
        ratings: oldResource.ratings,
        resourceImageUrl: oldResource.resourceImageUrl,
        createdAt: oldResource.createdAt,
        averageRating: newAverageRating,
      );
    }
    update();
  }
}
