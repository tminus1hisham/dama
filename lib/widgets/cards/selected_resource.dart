import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SelectedResource extends StatelessWidget {
  const SelectedResource({
    super.key,
    required this.heading,
    required this.imageUrl,
    required this.rating,
    required this.price,
    required this.onPressed,
    required this.description,
    required this.onViewPressed,
    required this.isPaid,
    required this.onRatingUpdated,
  });

  final double rating;
  final String heading;
  final String imageUrl;
  final String price;
  final String description;
  final VoidCallback onPressed;
  final VoidCallback onViewPressed;
  final bool isPaid;
  final VoidCallback onRatingUpdated;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;

    return Padding(
      padding: EdgeInsets.only(top: 8),
      child: Container(
        color: isDarkMode ? kBlack : kWhite,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image with FREE badge
            Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 250,
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                ),
                // FREE badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: kGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'FREE',
                      style: TextStyle(
                        color: kWhite,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Title
            Padding(
              padding: EdgeInsets.symmetric(horizontal: kSidePadding),
              child: Text(
                heading,
                style: TextStyle(
                  color: isDarkMode ? kWhite : kBlack,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Rating section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: kSidePadding),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode ? kDarkThemeBg : kBGColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Rating",
                          style: TextStyle(
                            color: kGrey,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: onRatingUpdated,
                          child: Row(
                            children: [
                              ...List.generate(5, (index) {
                                return Icon(
                                  index < rating.round()
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  color:
                                      index < rating.round() ? kYellow : kGrey,
                                  size: 28,
                                );
                              }),
                              const SizedBox(width: 8),
                              Text(
                                rating.toStringAsFixed(1),
                                style: TextStyle(
                                  color: isDarkMode ? kWhite : kBlack,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Tap to rate
                    GestureDetector(
                      onTap: onRatingUpdated,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: kBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.rate_review, color: kBlue, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Rate this',
                              style: TextStyle(
                                color: kBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Read Now button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: kSidePadding),
              child: ElevatedButton.icon(
                onPressed: onViewPressed,
                icon: const Icon(
                  Icons.menu_book_rounded,
                  color: kWhite,
                ),
                label: const Text(
                  'Read Now',
                  style: TextStyle(
                    color: kWhite,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(height: 5, color: isDarkMode ? kDarkThemeBg : kBGColor),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: kSidePadding,
                vertical: 16,
              ),
              child: Text(
                'Description',
                style: TextStyle(
                  color: isDarkMode ? kWhite : kBlack,
                  fontSize: kMidText,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: kSidePadding),
              child: Text(
                description,
                style: TextStyle(
                  fontSize: 15,
                  color: isDarkMode ? kWhite : kGrey,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
