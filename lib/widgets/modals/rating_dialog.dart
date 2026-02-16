import 'package:dama/utils/constants.dart';
import 'package:dama/widgets/buttons/custom_button.dart';
import 'package:flutter/material.dart';

class RatingDialog extends StatefulWidget {
  const RatingDialog({super.key});

  @override
  _RatingDialogState createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  double selectedRating = 0.0;
  bool isSubmitted = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (isSubmitted) {
      return AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: kGreen, size: 60),
            const SizedBox(height: 16),
            Text(
              'Thanks for your feedback!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Your rating helps others find quality resources.',
              style: TextStyle(fontSize: 14, color: kGrey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          CustomButton(
            callBackFunction: () {
              Navigator.of(context).pop(selectedRating);
            },
            label: "Done",
            backgroundColor: kBlue,
          ),
        ],
      );
    }

    return AlertDialog(
      title: Text('Rate this Resource'),
      content: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (index) {
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedRating = index + 1.0;
              });
            },
            child: Icon(
              Icons.star,
              color: index < selectedRating ? kYellow : kGrey,
              size: 35,
            ),
          );
        }),
      ),
      actions: [
        CustomButton(
          callBackFunction: () {
            if (selectedRating > 0) {
              setState(() {
                isSubmitted = true;
              });
            }
          },
          label: "Submit",
          backgroundColor: kBlue,
        ),
      ],
    );
  }
}
