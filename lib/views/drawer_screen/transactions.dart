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
  
  // Search and filter state
  late TextEditingController _searchController;
  String _selectedStatus = 'All Status';
  String _selectedType = 'All Types';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _fetchData();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  List<dynamic> _getFilteredTransactions() {
    var transactions = _transactionController.transactionList.reversed.toList();
    
    // Filter by search query
    if (_searchController.text.isNotEmpty) {
      transactions = transactions.where((tx) {
        final query = _searchController.text.toLowerCase();
        return tx.objectTitle.toLowerCase().contains(query) ||
            tx.id.toLowerCase().contains(query) ||
            tx.amount.toLowerCase().contains(query);
      }).toList();
    }
    
    // Filter by status
    if (_selectedStatus != 'All Status') {
      transactions = transactions.where((tx) => tx.status == _selectedStatus).toList();
    }
    
    // Filter by type
    if (_selectedType != 'All Types') {
      transactions = transactions.where((tx) => tx.onModel == _selectedType).toList();
    }
    
    return transactions;
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
                            child: Column(
                              children: [
                                // Search and Filter Card
                                Container(
                                  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF131C2B),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey[700]!,
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      // Search TextField
                                      TextField(
                                        controller: _searchController,
                                        style: TextStyle(color: Colors.white),
                                        decoration: InputDecoration(
                                          hintText: "Search transactions...",
                                          hintStyle: TextStyle(color: Colors.grey[500]),
                                          prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(color: Colors.grey[700]!, width: 0.5),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(color: Colors.grey[700]!, width: 0.5),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(color: kBlue, width: 1),
                                          ),
                                        ),
                                        onChanged: (value) => setState(() {}),
                                      ),
                                      SizedBox(height: 12),
                                      // Filter Dropdowns Row
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Container(
                                              padding: EdgeInsets.symmetric(horizontal: 12),
                                              decoration: BoxDecoration(
                                                color: Color(0xFF0a0f1a),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: Colors.grey[700]!,
                                                  width: 0.5,
                                                ),
                                              ),
                                              child: DropdownButton<String>(
                                                value: _selectedStatus,
                                                underline: SizedBox(),
                                                isExpanded: true,
                                                dropdownColor: Color(0xFF131C2B),
                                                items: ['All Status', 'Pending', 'Completed', 'Failed']
                                                    .map((status) {
                                                  return DropdownMenuItem<String>(
                                                    value: status,
                                                    child: Text(
                                                      status,
                                                      style: TextStyle(color: Colors.white),
                                                    ),
                                                  );
                                                }).toList(),
                                                onChanged: (value) {
                                                  setState(() => _selectedStatus = value ?? 'All Status');
                                                },
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Container(
                                              padding: EdgeInsets.symmetric(horizontal: 12),
                                              decoration: BoxDecoration(
                                                color: Color(0xFF0a0f1a),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: Colors.grey[700]!,
                                                  width: 0.5,
                                                ),
                                              ),
                                              child: DropdownButton<String>(
                                                value: _selectedType,
                                                underline: SizedBox(),
                                                isExpanded: true,
                                                dropdownColor: Color(0xFF131C2B),
                                                items: ['All Types', 'Event', 'Resource', 'Subscription']
                                                    .map((type) {
                                                  return DropdownMenuItem<String>(
                                                    value: type,
                                                    child: Text(
                                                      type,
                                                      style: TextStyle(color: Colors.white),
                                                    ),
                                                  );
                                                }).toList(),
                                                onChanged: (value) {
                                                  setState(() => _selectedType = value ?? 'All Types');
                                                },
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Transactions List
                                Expanded(
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

                                      final filteredList = _getFilteredTransactions();

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

                                      if (filteredList.isEmpty) {
                                        return Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.search_off,
                                              size: 48,
                                              color: Colors.grey[400],
                                            ),
                                            SizedBox(height: 16),
                                            Text(
                                              "No matching transactions",
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        );
                                      }

                                      return ListView.builder(
                                        padding: EdgeInsets.zero,
                                        itemCount: filteredList.length,
                                        itemBuilder: (context, index) {
                                          final transaction = filteredList[index];
                                          return TransactionCard(
                                            transaction: transaction,
                                          );
                                        },
                                      );
                                    }),
                                  ),
                                ),
                              ],
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
