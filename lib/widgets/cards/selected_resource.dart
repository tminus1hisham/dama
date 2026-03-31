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
    this.onRatingSubmitted,
    this.buttonText,
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
  final Function(double)? onRatingSubmitted;
  final String? buttonText;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;

    return Padding(
      padding: EdgeInsets.only(top: 8),
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? kBlack : kWhite,
          border: Border.all(
            color: isDarkMode ? const Color(0xFF1D2839) : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image (clean, no badge)
            SizedBox(
              width: double.infinity,
              height: 250,
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
            const SizedBox(height: 8),
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
            const SizedBox(height: 8),
            // Read Now Button + Free/Price + Rating Stars Row (like main page)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: kSidePadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Read Now / Purchase button on left with icon
                  ElevatedButton.icon(
                    onPressed: onPressed,
                    icon: Icon(
                      (isPaid || priceInt == 0)
                          ? Icons.menu_book_outlined
                          : (buttonText == 'View')
                              ? Icons.visibility
                              : Icons.shopping_cart_outlined,
                      size: 18,
                    ),
                    label: Text(
                      buttonText ??
                          ((isPaid || priceInt == 0) ? 'Read Now' : 'Purchase'),
                      style: const TextStyle(
                        color: kWhite,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          (isPaid || priceInt == 0) ? kBlue : kGreen,
                      foregroundColor: kWhite,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                  ),
                  // Free/Price and Rating on right
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Free/Price text
                      Text(
                        priceInt == 0 ? 'Free' : 'KES $price',
                        style: TextStyle(
                          color: kGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Rating stars (interactive if purchased/free)
                      Row(
                        children: [
                          ...List.generate(5, (starIndex) {
                            return GestureDetector(
                              onTap:
                                  (isPaid || priceInt == 0)
                                      ? () => onRatingSubmitted?.call(
                                        starIndex + 1.0,
                                      )
                                      : null,
                              child: Icon(
                                starIndex < rating.round()
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color:
                                    starIndex < rating.round()
                                        ? kYellow
                                        : kGrey,
                                size: 20,
                              ),
                            );
                          }),
                          const SizedBox(width: 4),
                          Text(
                            rating.toStringAsFixed(1),
                            style: TextStyle(
                              color: isDarkMode ? kWhite : kBlack,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(height: 5, color: isDarkMode ? kDarkThemeBg : kBGColor),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: kSidePadding,
                vertical: 12,
              ),
              child: Text(
                'Description',
                style: TextStyle(
                  color: isDarkMode ? kWhite : kBlack,
                  fontSize: 16,
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
            const SizedBox(height: 30),
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
                        fontSize: 16,
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
                      children: List.generate(relatedResources.length, (index) {
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
                                border:
                                    isDarkMode
                                        ? Border.all(
                                          color: const Color(0xFF1D2839),
                                          width: 1,
                                        )
                                        : null,
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
                                    child:
                                        resource.resourceImageUrl.isNotEmpty
                                            ? Image.network(
                                              resource.resourceImageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => Icon(
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Title - first sentence only with ellipsis
                                        Text(
                                          resource.title.split('.').first +
                                              '...',
                                          maxLines: 1,
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
                                              resource.averageRating
                                                  .toStringAsFixed(1),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color:
                                                    isDarkMode
                                                        ? kWhite
                                                        : kBlack,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        // Price
                                        Text(
                                          resource.price == 0
                                              ? 'Free'
                                              : 'KES ${resource.price}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                resource.price == 0
                                                    ? kGreen
                                                    : kBlue,
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
                      }),
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
