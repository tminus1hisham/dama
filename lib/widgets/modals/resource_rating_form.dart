import 'package:dama/models/rating_model.dart';
import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ResourceRatingForm extends StatefulWidget {
  final Function(RatingModel) onSubmit;
  final bool isLoading;

  const ResourceRatingForm({
    super.key,
    required this.onSubmit,
    this.isLoading = false,
  });

  @override
  State<ResourceRatingForm> createState() => _ResourceRatingFormState();
}

class _ResourceRatingFormState extends State<ResourceRatingForm> {
  double _selectedRating = 0.0;
  final TextEditingController _feedbackController = TextEditingController();

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _submitRating() {
    if (_selectedRating == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a rating'),
          backgroundColor: kRed,
        ),
      );
      return;
    }

    final rating = RatingModel(rating: _selectedRating);

    widget.onSubmit(rating);

    // Reset form after submission
    setState(() {
      _selectedRating = 0.0;
      _feedbackController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;

    return Container(
      color: isDarkMode ? kDarkThemeBg : kBGColor,
      padding: EdgeInsets.all(kSidePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'Rate this Resource',
            style: TextStyle(
              fontSize: kBigTextSize,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? kWhite : kBlack,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'How would you rate your reading experience?',
            style: TextStyle(fontSize: 14, color: kGrey),
          ),
          const SizedBox(height: 24),

          // Star Rating Input
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedRating = (index + 1).toDouble();
                    });
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      index < _selectedRating.toInt()
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: index < _selectedRating.toInt() ? kYellow : kGrey,
                      size: 40,
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          // Rating display
          Center(
            child: Text(
              _selectedRating > 0
                  ? '${_selectedRating.toInt()} / 5 Stars'
                  : 'Select a rating',
              style: TextStyle(
                fontSize: 14,
                color: _selectedRating > 0 ? kBlue : kGrey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Feedback TextField
          Text(
            'Share your thoughts about this resource (optional)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? kWhite : kBlack,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: isDarkMode ? kDarkCard : kWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                width: 0.5,
              ),
            ),
            child: TextField(
              controller: _feedbackController,
              enabled: !widget.isLoading,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                hintText:
                    'Tell other members what you think about this resource...',
                hintStyle: TextStyle(color: kGrey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
                counterStyle: TextStyle(color: kGrey, fontSize: 12),
              ),
              style: TextStyle(
                color: isDarkMode ? kWhite : kBlack,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.isLoading ? null : _submitRating,
              style: ElevatedButton.styleFrom(
                backgroundColor: kBlue,
                disabledBackgroundColor: Colors.grey[600],
                foregroundColor: kWhite,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child:
                  widget.isLoading
                      ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(kWhite),
                        ),
                      )
                      : Text(
                        'Submit Rating',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
