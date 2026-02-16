import 'package:dama/models/alert_model.dart';
import 'package:dama/utils/constants.dart';
import 'package:flutter/material.dart';

class AlertDialogWidget extends StatelessWidget {
  final AlertModel alert;
  final VoidCallback onClose;
  final bool isDarkMode;

  const AlertDialogWidget({
    super.key,
    required this.alert,
    required this.onClose,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 600;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isWeb ? 100 : 20,
        vertical: 40,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isWeb ? 600 : double.infinity,
          maxHeight: 700,
        ),
        decoration: BoxDecoration(
          color: isDarkMode ? kBlack : kWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close button
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: Icon(Icons.close, color: isDarkMode ? kWhite : kBlack),
                onPressed: onClose,
              ),
            ),

            // Alert Image
            if (alert.imageUrl.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    alert.imageUrl,
                    height: 80,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 80,
                        decoration: BoxDecoration(
                          color: isDarkMode ? kDarkThemeBg : kBGColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 40,
                            color: kGrey,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

            SizedBox(height: 16),

            // Alert Description
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  alert.description,
                  style: TextStyle(
                    color: isDarkMode ? kWhite : kBlack,
                    fontSize: 16,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            SizedBox(height: 20),

            // Action Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton(
                onPressed: onClose,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBlue,
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Got it!',
                  style: TextStyle(
                    color: kWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
