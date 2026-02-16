import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/transaction_model.dart';

class TransactionCard extends StatelessWidget {
  TransactionCard({super.key, required this.transaction});

  final TransactionModel transaction;
  final Utils _utils = Utils();

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'success':
        return const Color(0xFF10B981);
      case 'failed':
      case 'error':
        return const Color(0xFFEF4444);
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'processing':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'success':
        return Icons.check_circle;
      case 'failed':
      case 'error':
        return Icons.error;
      case 'pending':
        return Icons.schedule;
      case 'processing':
        return Icons.sync;
      default:
        return Icons.info;
    }
  }

  IconData _getObjectIcon(String onModel) {
    switch (onModel.toLowerCase()) {
      case 'event':
        return Icons.event;
      case 'resource':
        return Icons.library_books;
      default:
        return Icons.receipt;
    }
  }

  void _showTransactionDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransactionDetailsModal(transaction: transaction),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;

    return GestureDetector(
      onTap: () => _showTransactionDetails(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color:
                  isDarkMode
                      ? Colors.black.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color:
                isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _getStatusIcon(transaction.status),
                              size: 16,
                              color: _getStatusColor(transaction.status),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  transaction.status,
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _getStatusColor(
                                    transaction.status,
                                  ).withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                transaction.status,
                                style: TextStyle(
                                  color: _getStatusColor(transaction.status),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Object type and title
                        Row(
                          children: [
                            Icon(
                              _getObjectIcon(transaction.onModel),
                              size: 14,
                              color:
                                  isDarkMode
                                      ? const Color(0xFF9CA3AF)
                                      : const Color(0xFF6B7280),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                transaction.objectTitle,
                                style: TextStyle(
                                  color: isDarkMode ? kWhite : kBlack,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'KSh ${transaction.amount}',
                        style: TextStyle(
                          color:
                              isDarkMode
                                  ? Colors.white
                                  : const Color(0xFF111827),
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isDarkMode
                                  ? const Color(0xFF374151)
                                  : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          transaction.onModel,
                          style: TextStyle(
                            color:
                                isDarkMode
                                    ? const Color(0xFF9CA3AF)
                                    : const Color(0xFF6B7280),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 1,
                width: double.infinity,
                color:
                    isDarkMode
                        ? const Color(0xFF374151)
                        : const Color(0xFFE5E7EB),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 14,
                        color:
                            isDarkMode
                                ? const Color(0xFF9CA3AF)
                                : const Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _utils.formatUtcToLocal(
                          transaction.createdAt.toString(),
                        ),
                        style: TextStyle(
                          color:
                              isDarkMode
                                  ? const Color(0xFF9CA3AF)
                                  : const Color(0xFF6B7280),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        'Tap for details',
                        style: TextStyle(
                          color:
                              isDarkMode
                                  ? const Color(0xFF9CA3AF)
                                  : const Color(0xFF6B7280),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color:
                            isDarkMode
                                ? const Color(0xFF9CA3AF)
                                : const Color(0xFF6B7280),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Modal widget for transaction details
class TransactionDetailsModal extends StatelessWidget {
  final TransactionModel transaction;

  const TransactionDetailsModal({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[600] : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transaction Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Transaction ID', transaction.id, isDarkMode),
                  _buildDetailRow(
                    'M-Pesa Short Code',
                    transaction.mpesaShortCode,
                    isDarkMode,
                  ),
                  _buildDetailRow(
                    'Amount',
                    'KSh ${transaction.amount}',
                    isDarkMode,
                  ),
                  _buildDetailRow('Status', transaction.status, isDarkMode),
                  _buildDetailRow(
                    'Date Created',
                    Utils().formatUtcToLocal(transaction.createdAt.toString()),
                    isDarkMode,
                  ),

                  const SizedBox(height: 20),
                  Text(
                    'User Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildDetailRow(
                    'Name',
                    transaction.user.fullName,
                    isDarkMode,
                  ),
                  _buildDetailRow('Email', transaction.user.email, isDarkMode),

                  if (transaction.event != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Event Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Container(
                      height: 150,
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: NetworkImage(
                            transaction.event!.eventImageUrl,
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    _buildDetailRow(
                      'Event Title',
                      transaction.event!.eventTitle,
                      isDarkMode,
                    ),
                    _buildDetailRow(
                      'Location',
                      transaction.event!.location,
                      isDarkMode,
                    ),
                    _buildDetailRow(
                      'Event Date',
                      Utils().formatUtcToLocal(
                        transaction.event!.eventDate.toString(),
                      ),
                      isDarkMode,
                    ),
                    _buildDetailRow(
                      'Price',
                      'KSh ${transaction.event!.price}',
                      isDarkMode,
                    ),

                    const SizedBox(height: 12),
                    Text(
                      'Description',
                      style: TextStyle(
                        fontSize: kNormalTextSize,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      transaction.event!.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                        height: 1.5,
                      ),
                    ),

                    if (transaction.event!.speakers.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Speakers',
                        style: TextStyle(
                          fontSize: kNormalTextSize,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...transaction.event!.speakers.map(
                        (speaker) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundImage: NetworkImage(speaker.image),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                speaker.name,
                                style: TextStyle(
                                  fontSize: kNormalTextSize,
                                  color:
                                      isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: kNormalTextSize,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: kNormalTextSize,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
