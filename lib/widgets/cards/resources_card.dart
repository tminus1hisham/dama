import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ResourcesCard extends StatelessWidget {
  const ResourcesCard({
    super.key,
    required this.heading,
    required this.imageUrl,
    required this.rating,
    required this.onPressed,
    required this.onReadNowPressed,
  });

  final double rating;
  final String heading;
  final String imageUrl;
  final VoidCallback onPressed;
  final VoidCallback onReadNowPressed;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;

    return Padding(
      padding: EdgeInsets.only(top: 8),
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          color: isDarkMode ? kBlack : kWhite,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image
              SizedBox(
                width: double.infinity,
                height: 200,
                child:
                    imageUrl.isNotEmpty
                        ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) => const Center(
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
              const SizedBox(height: 12),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: kSidePadding),
                child: Text(
                  heading,
                  style: TextStyle(
                    fontSize: kMidText,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? kWhite : kBlack,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 12),
              // Read Now, FREE tag, and Rating row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: kSidePadding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Read Now button (left)
                    ElevatedButton.icon(
                      onPressed: onReadNowPressed,
                      icon: const Icon(
                        Icons.menu_book_rounded,
                        size: 18,
                        color: kWhite,
                      ),
                      label: const Text(
                        'Read Now',
                        style: TextStyle(
                          color: kWhite,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kBlue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                    ),
                    // FREE tag (center)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
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
                          fontSize: 12,
                        ),
                      ),
                    ),
                    // Rating (right)
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            index < rating.round()
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: index < rating.round() ? kYellow : kGrey,
                            size: 20,
                          );
                        }),
                        const SizedBox(width: 6),
                        Text(
                          rating.toStringAsFixed(1),
                          style: TextStyle(
                            color: isDarkMode ? kWhite : kBlack,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
