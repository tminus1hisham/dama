import 'package:dama/models/transaction_model.dart';
import 'package:dama/services/api_service.dart';
import 'package:get/get.dart';

class TransactionController extends GetxController {
  var transactionList = <TransactionModel>[].obs;

  var isLoading = false.obs;

  final ApiService _transactionService = ApiService();

  Future<void> fetchTransactions() async {
    isLoading.value = true;
    try {
      List<TransactionModel> fetchedTranscations;
      fetchedTranscations = await _transactionService.getTransactions();
      transactionList.assignAll(fetchedTranscations);
    } catch (e) {
      print(e);
    } finally {
      isLoading.value = false;
    }
  }
}
