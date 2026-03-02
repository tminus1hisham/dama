import 'package:dama/utils/constants.dart';
import 'package:dama/views/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void showSuccessBottomSheet(
  BuildContext context,
  String? title,
  String? date,
  String? location,
  bool isDark,
) {
  if (!context.mounted) {
    return;
  }

  showModalBottomSheet(
    backgroundColor: isDark ? kBlack : kWhite,
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    isScrollControlled: true,
    builder:
        (context) => SuccessBottomSheetContent(
          title: title,
          date: date,
          location: location,
          isDark: isDark,
        ),
  );
}

class SuccessBottomSheetContent extends StatefulWidget {
  final String? title;
  final String? date;
  final String? location;
  final bool isDark;

  const SuccessBottomSheetContent({
    super.key,
    this.title,
    this.date,
    this.location,
    required this.isDark,
  });

  @override
  State<SuccessBottomSheetContent> createState() =>
      _SuccessBottomSheetContentState();
}

class _SuccessBottomSheetContentState extends State<SuccessBottomSheetContent> {
  @override
  void initState() {
    super.initState();
    // Auto-navigate after 3 seconds
    if (widget.date == 'Training enrollment') {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          // Close the success bottom sheet
          Navigator.of(context).pop();
          // Navigate to training dashboard after a brief delay
          Future.delayed(const Duration(milliseconds: 100), () {
            Get.toNamed('/my-trainings');
          });
        }
      });
    } else if (widget.date == 'Resource purchased') {
      // Auto-navigate after 3 seconds for resources
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          // Close the success bottom sheet
          Navigator.of(context).pop();
          // Navigate to resources dashboard after a brief delay
          Future.delayed(const Duration(milliseconds: 100), () {
            Get.offAll(() => Dashboard(initialTab: 3, initialSubTab: 1));
          });
        }
      });
    } else {
      // Auto-navigate after 3 seconds for events
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          // Close the success bottom sheet
          Navigator.of(context).pop();
          // Navigate to events dashboard after a brief delay
          Future.delayed(const Duration(milliseconds: 100), () {
            Get.offAll(() => Dashboard(initialTab: 4, initialSubTab: 1));
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 100),
          SizedBox(height: 20),
          Text(
            'Reservation Confirmed',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: widget.isDark ? kWhite : kBlack,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12),
          Text(
            "We're thrilled to have you join us. Your reservation is confirmed, and we look forward to welcoming you soon.",
            style: TextStyle(
              fontSize: 16,
              color: widget.isDark ? kWhite : kBlack,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          Text(
            widget.title ?? '',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: widget.isDark ? kWhite : kBlack,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            '${widget.date ?? ''}   ${widget.location ?? ''}',
            style: TextStyle(
              fontSize: 16,
              color: widget.isDark ? kWhite : kBlack,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the bottom sheet
              // Check if this is for training enrollment
              if (widget.date == 'Training enrollment') {
                Get.toNamed('/my-trainings');
              } else if (widget.date == 'Resource purchased') {
                // Navigate to dashboard with resources tab selected (index 3) and My Resources sub-tab (1)
                Get.offAll(() => Dashboard(initialTab: 3, initialSubTab: 1));
              } else {
                // Navigate to dashboard with events tab selected (index 4) and My Events and Tickets sub-tab (1)
                Get.offAll(() => Dashboard(initialTab: 4, initialSubTab: 1));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kBlue,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: Text(
              widget.date == 'Training enrollment'
                  ? 'View My Trainings'
                  : widget.date == 'Resource purchased'
                      ? 'View My Resources'
                      : 'View My Reservations',
              style: TextStyle(color: kWhite, fontSize: 16),
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}
