import 'package:dama/models/resources_model.dart';
import 'package:dama/services/api_service.dart';
import 'package:get/get.dart';

class ResourceController extends GetxController {
  var resourceList = <ResourceModel>[].obs;

  var isLoading = false.obs;

  final ApiService _resourceService = ApiService();

  @override
  void onInit() {
    super.onInit();
    fetchResources();
  }

  Future<void> fetchResources() async {
    isLoading.value = true;
    try {
      List<ResourceModel> fetchedBlogs = await _resourceService.getResources();
      resourceList.assignAll(fetchedBlogs);
    } catch (e) {
      print(e);
    } finally {
      isLoading.value = false;
    }
  }
}
