import 'package:dama/services/api_service.dart';
import 'package:dama/services/local_storage_service.dart';
import 'package:dama/utils/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

class LikeController extends GetxController {
  final ApiService _likeService = ApiService();

  final likedStatus = <String, bool>{}.obs;
  final likeCount = <String, int>{}.obs;

  void initializeLikeStatus(String blogId, List<dynamic> likes) async {
    final userId = await StorageService.getData('userId');
    if (userId == null || likes == null || likes.isEmpty) {
      likedStatus[blogId] = false;
      likeCount[blogId] = 0;
      return;
    }

    final isLiked = likes.any((like) => like['user_Id']['_id'] == userId);

    likedStatus[blogId] = isLiked;
    likeCount[blogId] = likes.length;
  }

  Future<void> toggleLike(String blogId) async {
    try {
      final currentStatus = likedStatus[blogId] ?? false;

      likedStatus[blogId] = !currentStatus;
      likeCount[blogId] = (likeCount[blogId] ?? 0) + (currentStatus ? -1 : 1);

      await _likeService.likeBlog(blogId);
    } catch (e) {
      final currentStatus = likedStatus[blogId] ?? false;
      likedStatus[blogId] = !currentStatus;
      likeCount[blogId] = (likeCount[blogId] ?? 0) + (currentStatus ? 1 : -1);
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
