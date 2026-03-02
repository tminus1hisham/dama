import 'package:dama/models/resources_model.dart';
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
    required this.isPaid,
    required this.onRatingUpdated,
    required this.priceInt,
    this.relatedResources = const [],
    this.onRelatedResourceTap,
  });

  final double rating;
  final String heading;
  final String imageUrl;
  final String price;
  final String description;
  final VoidCallback onPressed;
  final bool isPaid;
  final VoidCallback onRatingUpdated;
  final int priceInt;
  final List<ResourceModel> relatedResources;
  final Function(ResourceModel)? onRelatedResourceTap;

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
                // FREE badge (only show for free resources)
                if (priceInt == 0)
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
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Rating section - only interactive if purchased
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
                          onTap: isPaid ? onRatingUpdated : null,
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
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Tap to rate button - only show if purchased or free
                    if (isPaid || priceInt == 0)
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
                      )
                    else
                      Text(
                        'Purchase to rate',
                        style: TextStyle(
                          color: kGrey,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Read Now / Purchase button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: kSidePadding),
              child: ElevatedButton.icon(
                onPressed: onPressed,
                icon: Icon(
                  (isPaid || priceInt == 0) ? Icons.menu_book_outlined : Icons.shopping_cart_outlined,
                ),
                label: Text(
                  (isPaid || priceInt == 0) ? 'Read Now' : 'Purchase - KES $price',
                  style: const TextStyle(
                    color: kWhite,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: (isPaid || priceInt == 0) ? kBlue : kGreen,
                  foregroundColor: kWhite,
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
                  fontSize: 14,
                  color: isDarkMode ? kWhite : kGrey,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 40),
            // Related Resources Section
            if (relatedResources.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: kSidePadding),
                    child: Text(
                      'Related Resources',
                      style: TextStyle(
                        fontSize: kBigTextSize,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? kWhite : kBlack,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: kSidePadding),
                    child: Row(
                      children: List.generate(
                        relatedResources.length,
                        (index) {
                          final resource = relatedResources[index];
                          return Container(
                            margin: EdgeInsets.only(right: 12),
                            width: 280,
                            child: GestureDetector(
                              onTap: () => onRelatedResourceTap?.call(resource),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isDarkMode ? kDarkCard : kBGColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                                    width: 0.5,
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Image
                                    Container(
                                      height: 160,
                                      width: double.infinity,
                                      color: Colors.grey[700],
                                      child: resource.resourceImageUrl.isNotEmpty
                                          ? Image.network(
                                              resource.resourceImageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) =>
                                                  Icon(
                                                Icons.image_not_supported,
                                                color: Colors.grey[600],
                                              ),
                                            )
                                          : Icon(
                                              Icons.image_not_supported,
                                              color: Colors.grey[600],
                                            ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Title
                                          Text(
                                            resource.title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: isDarkMode ? kWhite : kBlack,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          // Rating
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.star_rounded,
                                                color: kYellow,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                resource.averageRating.toStringAsFixed(1),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isDarkMode ? kWhite : kBlack,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          // Price
                                          Text(
                                            resource.price == 0
                                                ? 'FREE'
                                                : 'KES ${resource.price}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: resource.price == 0 ? kGreen : kBlue,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
