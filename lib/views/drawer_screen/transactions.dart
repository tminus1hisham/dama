import 'package:dama/controller/transaction_controller.dart';
import 'package:dama/services/local_storage_service.dart';
import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/widgets/cards/profile_card.dart';
import 'package:dama/widgets/shimmer/transaction_shimmer.dart';
import 'package:dama/widgets/top_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../widgets/cards/transaction_card.dart';

class Transactions extends StatefulWidget {
  const Transactions({super.key});

  @override
  State<Transactions> createState() => _TransactionsState();
}

class _TransactionsState extends State<Transactions> {
  final TransactionController _transactionController = Get.put(
    TransactionController(),
  );

  bool _isLoading = false;
  String imageUrl = '';
  String firstName = '';
  String lastName = '';
  String title = '';
  String bio = '';
  String memberId = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
    _loadData();
  }

  void _loadData() async {
    final url = await StorageService.getData('profile_picture');
    final fetchedFirstName = await StorageService.getData('firstName');
    final fetchedLastName = await StorageService.getData('lastName');
    final fetchedTitle = await StorageService.getData('title');
    final fetchedMemberId = await StorageService.getData('memberId');
    String? fetchedBio = await StorageService.getData('brief');

    setState(() {
      imageUrl = url;
      firstName = fetchedFirstName;
      memberId = fetchedMemberId;
      lastName = fetchedLastName;
      title = fetchedTitle;
      bio = fetchedBio ?? '';
    });
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    await _transactionController.fetchTransactions();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;
    bool kIsWeb = MediaQuery.of(context).size.width > 1100;

    return Scaffold(
      backgroundColor: isDarkMode ? kDarkThemeBg : kBGColor,
      body: Column(
        children: [
          TopNavigationbar(title: "Transactions"),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 1500),
                child: Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (kIsWeb)
                        ProfileCard(
                          isDarkMode: isDarkMode,
                          imageUrl: imageUrl,
                          firstName: firstName,
                          lastName: lastName,
                          title: title,
                          bio: bio,
                        ),
                      if (kIsWeb) SizedBox(width: 10),
                      Expanded(
                        child: Center(
                          child: Container(
                            // constraints: BoxConstraints(maxWidth: 600),
                            child: RefreshIndicator(
                              color: kWhite,
                              backgroundColor: kBlue,
                              displacement: 40,
                              onRefresh: _fetchData,
                              child: Obx(() {
                                if (_transactionController.isLoading.value ||
                                    _isLoading) {
                                  return ListView.builder(
                                    padding: EdgeInsets.zero,
                                    itemCount: 10,
                                    itemBuilder:
                                        (context, index) =>
                                            TransactionSkeleton(),
                                  );
                                }

                                if (_transactionController
                                    .transactionList
                                    .isEmpty) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.receipt_long,
                                        size: 48,
                                        color: Colors.grey[400],
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        "No transactions yet",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        "Your transactions will appear here",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  );
                                }

                                final reversedList =
                                    _transactionController
                                        .transactionList
                                        .reversed
                                        .toList();

                                return ListView.builder(
                                  padding: EdgeInsets.zero,
                                  itemCount: reversedList.length,
                                  itemBuilder: (context, index) {
                                    final transaction = reversedList[index];
                                    return TransactionCard(
                                      transaction: transaction,
                                    );
                                  },
                                );
                              }),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
