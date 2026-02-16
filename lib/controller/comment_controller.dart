import 'package:dama/models/comment_model.dart';
import 'package:dama/services/api_service.dart';
import 'package:dama/services/local_storage_service.dart';
import 'package:dama/utils/constants.dart';
import 'package:dama/widgets/modals/comment_bottomsheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

class CommentController extends GetxController {
  final ApiService _commentService = ApiService();
  var isLoading = false.obs;
  var comments = <String, List<CommentData>>{}.obs;

  Future<void> addComment(String blogID, String commentText) async {
    isLoading.value = true;

    try {
      final firstName = await StorageService.getData('firstName') ?? 'User';
      final lastName = await StorageService.getData('lastName') ?? '';
      final profilePic =
          await StorageService.getData('profile_picture') ?? DEFAULT_IMAGE_URL;

      final tempComment = CommentData(
        createdAt: DateTime.now(),
        name: '$firstName $lastName',
        comment: commentText,
        profileImageUrl: profilePic,
      );

      comments.update(
        blogID,
        (existing) => [...existing, tempComment],
        ifAbsent: () => [tempComment],
      );

      final commentModel = CommentModel(comment: commentText);
      await _commentService.addComment(commentModel, blogID);
    } catch (e) {
      comments.update(blogID, (existing) => existing..removeLast());
      Get.snackbar(
        margin: EdgeInsets.only(top: 15, left: 15, right: 15),
        "Error",
        "Failed to add comment",
        colorText: kWhite,
        backgroundColor: kRed.withOpacity(0.9),
      );
    } finally {
      isLoading.value = false;
    }
  }

  void initializeComments(String blogId, List<dynamic> apiComments) {
    final formattedComments = apiComments.map((e) {
      DateTime createdAt;

      try {
        // parse from string or assign fallback
        createdAt = e.createdAt != null
            ? DateTime.parse(e.createdAt.toString())
            : DateTime.now();
      } catch (_) {
        createdAt = DateTime.now();
      }

      return CommentData(
        createdAt: createdAt,
        name: '${e.user.firstName ?? 'User'} ${e.user.lastName ?? ''}',
        comment: e.comment ?? '',
        profileImageUrl: e.user.profilePicture ?? DEFAULT_IMAGE_URL,
      );
    }).toList();

    comments[blogId] = formattedComments;
  }

}
