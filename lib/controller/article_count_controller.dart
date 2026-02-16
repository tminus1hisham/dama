import 'package:dama/models/article_count_model.dart';
import 'package:dama/services/api_service.dart';
import 'package:dama/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ArticleCountController extends GetxController {
  var articleCount = Rx<ArticleCountModel?>(null);
  var isLoading = false.obs;

  final ApiService _apiService = ApiService();

  Future<bool> checkArticleLimitBeforeReading() async {
    isLoading.value = true;
    try {
      ArticleCountModel fetchedCount = await _apiService.getArticleCount();
      articleCount.value = fetchedCount;

      // Simply return whether user can read or not
      return !fetchedCount.hasExceededLimit;
    } catch (e) {
      Get.snackbar(
        margin: EdgeInsets.only(top: 15, left: 15, right: 15),
        "Error",
        "Failed to check article limit",
        colorText: kWhite,
        backgroundColor: kRed.withOpacity(0.9),
      );
      return true; // Allow reading if there's an error (fail gracefully)
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchArticleCount() async {
    isLoading.value = true;
    try {
      ArticleCountModel fetchedCount = await _apiService.getArticleCount();
      articleCount.value = fetchedCount;
    } catch (e) {
      Get.snackbar(
        margin: EdgeInsets.only(top: 15, left: 15, right: 15),
        "Error",
        "Failed to fetch article count",
        colorText: kWhite,
        backgroundColor: kRed.withOpacity(0.9),
      );
    } finally {
      isLoading.value = false;
    }
  }

  bool get hasExceededLimit {
    return articleCount.value?.hasExceededLimit ?? false;
  }

  int get articlesSeenCount {
    return articleCount.value?.articlesSeenCount ?? 0;
  }

  int get articlesAssignedCount {
    return articleCount.value?.articlesAssignedCount ?? 0;
  }
}
