import 'package:dama/utils/constants.dart';
import 'package:dama/utils/terms_constants.dart';
import 'package:flutter/material.dart';

class TermsAndConditionsDialog extends StatefulWidget {
  final VoidCallback onAccept;
  final VoidCallback? onDecline;

  const TermsAndConditionsDialog({
    super.key,
    required this.onAccept,
    this.onDecline,
  });

  @override
  State<TermsAndConditionsDialog> createState() =>
      _TermsAndConditionsDialogState();
}

class _TermsAndConditionsDialogState extends State<TermsAndConditionsDialog> {
  bool _hasScrolledToBottom = false;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 50) {
      if (!_hasScrolledToBottom) {
        setState(() {
          _hasScrolledToBottom = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDarkMode ? kDarkCard : kWhite,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              color: kBlue,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Text(
              'Terms & Conditions',
              style: const TextStyle(
                color: kWhite,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Scrollable Content
          Flexible(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  termsContent,
                  style: TextStyle(
                    color: isDarkMode ? kDarkText : Colors.black87,
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
              ),
            ),
          ),

          // Scroll prompt (shows until user scrolls)
          if (!_hasScrolledToBottom)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Please scroll to read and accept the terms',
                style: TextStyle(
                  color: kYellow,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

          // Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Decline button
                if (widget.onDecline != null)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onDecline,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: kRed),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Decline',
                        style: TextStyle(
                          color: kRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                if (widget.onDecline != null) const SizedBox(width: 12),

                // Accept button (only enabled after scrolling)
                Expanded(
                  child: ElevatedButton(
                    onPressed: _hasScrolledToBottom ? widget.onAccept : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kBlue,
                      disabledBackgroundColor: kGrey.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Accept & Continue',
                      style: TextStyle(
                        color: _hasScrolledToBottom ? kWhite : kGrey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
