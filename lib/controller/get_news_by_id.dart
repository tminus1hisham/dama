import 'package:dama/models/news_model.dart';
import 'package:dama/services/api_service.dart';
import 'package:dama/utils/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

class FetchNewsByIdController extends GetxController {
  final ApiService _apiService = ApiService();

  var news = Rxn<NewsModel>();

  var isLoading = false.obs;
  var error = ''.obs;

  Future<void> fetchNews(String newsId) async {
    try {
      isLoading.value = true;
      error.value = '';
      final newsData = await _apiService.getNewsById(newsId);
      news.value = newsData;
    } catch (e) {
      error.value = 'Failed to fetch news: ${e.toString()}';
      Get.snackbar(
        margin: EdgeInsets.only(top: 15, left: 15, right: 15),
        "Error",
        "Failed to fetch news by ID",
        colorText: kWhite,
        backgroundColor: kRed.withOpacity(0.9),
      );
    } finally {
      isLoading.value = false;
    }
  }
}
