import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

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

  Future<void> _generateAndDownloadReceipt(BuildContext context) async {
    try {
      final pdf = pw.Document();

      // Format date and time
      final formattedDate = DateFormat(
        'MMM d, yyyy',
      ).format(transaction.createdAt);
      final formattedTime = DateFormat('h:mm a').format(transaction.createdAt);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Center(
                  child: pw.Text(
                    'DAMA Kenya Payment Receipt',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Center(
                  child: pw.Text(
                    'Receipt Date: $formattedDate',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Divider(),
                pw.SizedBox(height: 20),

                // Transaction Summary
                pw.Text(
                  'Transaction Summary',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),

                // Detail rows
                pw.Column(
                  children: [
                    _buildReceiptRow('Transaction ID', transaction.id),
                    _buildReceiptRow('Reference Number', 'N/A'),
                    _buildReceiptRow('Description', transaction.objectTitle),
                    _buildReceiptRow('Transaction Type', transaction.onModel),
                    _buildReceiptRow(
                      'Date & Time',
                      '$formattedDate, $formattedTime',
                    ),
                    _buildReceiptRow('Payment Method', 'M-Pesa'),
                  ],
                ),

                pw.SizedBox(height: 20),
                pw.Divider(),
                pw.SizedBox(height: 20),

                // Amount Paid
                pw.Text(
                  'Amount Paid',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Center(
                  child: pw.Text(
                    'KES ${transaction.amount}',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 12),

                // Payment Status
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      'Payment Status',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                pw.Center(
                  child: pw.Text(
                    transaction.status,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),

                pw.Spacer(),

                // Footer
                pw.Divider(),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Thank you for your purchase!',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'DAMA Kenya – Data Management Professionals Community',
                        style: const pw.TextStyle(fontSize: 11),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Support: support@damakenya.org',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text(
                        'www.damakenya.org',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'This is a system-generated receipt and does not require a signature.',
                        style: const pw.TextStyle(fontSize: 9),
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Generate filename
      final fileName =
          'Receipt_${transaction.id.substring(0, 8)}_${DateFormat('ddMMyyyy').format(transaction.createdAt)}.pdf';

      // Save and share
      await Printing.sharePdf(bytes: await pdf.save(), filename: fileName);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Receipt downloaded successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate receipt: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  pw.Widget _buildReceiptRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 11),
            textAlign: pw.TextAlign.end,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;
    final utils = Utils();

    final formattedDate = DateFormat(
      'MMM d, yyyy',
    ).format(transaction.createdAt);
    final formattedTime = DateFormat('h:mm a').format(transaction.createdAt);

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
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
              color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
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
                    fontSize: 22,
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main Card
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 8,
                    ),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131C2B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF1E293B),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              isDarkMode
                                  ? Colors.black.withOpacity(0.3)
                                  : Colors.grey.withOpacity(0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Transaction ID Section
                        Text(
                          'Transaction ID',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          transaction.id,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 1,
                          width: double.infinity,
                          color: const Color(0xFF334155),
                        ),
                        const SizedBox(height: 20),

                        // Reference Number
                        _buildDetailSection(
                          'Reference Number',
                          'N/A',
                          isDarkMode,
                        ),

                        // Description
                        _buildDetailSection(
                          'Description',
                          transaction.objectTitle,
                          isDarkMode,
                        ),

                        // Amount
                        _buildDetailSection(
                          'Amount',
                          'KSh ${transaction.amount}',
                          isDarkMode,
                        ),

                        // Date & Time
                        _buildDetailSection(
                          'Date & Time',
                          '$formattedDate $formattedTime',
                          isDarkMode,
                        ),

                        // Type
                        _buildDetailSection(
                          'Type',
                          transaction.onModel,
                          isDarkMode,
                        ),

                        // Status
                        _buildDetailSection(
                          'Status',
                          transaction.status,
                          isDarkMode,
                        ),

                        // Payment Method (no underline - last item)
                        Text(
                          'Payment Method',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'M-Pesa',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Download Receipt Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed:
                                () => _generateAndDownloadReceipt(context),
                            icon: const Icon(Icons.download),
                            label: const Text(
                              'Download Receipt',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String label, String value, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 1,
          width: double.infinity,
          color: const Color(0xFF334155),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
