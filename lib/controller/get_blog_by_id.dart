import 'package:dama/models/blogs_model.dart';
import 'package:dama/services/api_service.dart';
import 'package:dama/utils/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

class FetchBlogByIdController extends GetxController {
  final ApiService _apiService = ApiService();

  var blog = Rxn<BlogPostModel>();

  var isLoading = false.obs;
  var error = ''.obs;

  Future<void> fetchBlog(String blogId) async {
    try {
      isLoading.value = true;
      error.value = '';
      final blogData = await _apiService.getBlogById(blogId);
      blog.value = blogData;
    } catch (e) {
      error.value = 'Failed to fetch blog: ${e.toString()}';
      Get.snackbar(
        margin: EdgeInsets.only(top: 15, left: 15, right: 15),
        "Error",
        "Failed to fetch blog by ID",
        colorText: kWhite,
        backgroundColor: kRed.withOpacity(0.9),
      );
    } finally {
      isLoading.value = false;
    }
  }
}
