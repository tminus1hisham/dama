import 'package:dama/services/api_service.dart';
import 'package:dama/services/local_storage_service.dart';
import 'package:dama/utils/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

class NewsLikeController extends GetxController {
  final ApiService _likeService = ApiService();

  final likedStatus = <String, bool>{}.obs;
  final likeCount = <String, int>{}.obs;

  void initializeLikeStatus(String newsId, List<dynamic> likes) async {
    final userId = await StorageService.getData('userId');
    final isLiked = likes.any((like) => like['user_Id']['_id'] == userId);

    likedStatus[newsId] = isLiked;
    likeCount[newsId] = likes.length;
  }

  Future<void> toggleLike(String newsId) async {
    try {
      final currentStatus = likedStatus[newsId] ?? false;

      likedStatus[newsId] = !currentStatus;
      likeCount[newsId] = (likeCount[newsId] ?? 0) + (currentStatus ? -1 : 1);

      await _likeService.likeNews(newsId);
    } catch (e) {
      final currentStatus = likedStatus[newsId] ?? false;
      likedStatus[newsId] = !currentStatus;
      likeCount[newsId] = (likeCount[newsId] ?? 0) + (currentStatus ? 1 : -1);
      Get.snackbar(
        margin: EdgeInsets.only(top: 15, left: 15, right: 15),
        "Error",
        "Failed to like post",
        colorText: kWhite,
        backgroundColor: kRed.withOpacity(0.9),
      );
    }
  }
}
