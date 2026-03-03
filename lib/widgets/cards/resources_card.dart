import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ResourcesCard extends StatelessWidget {
  const ResourcesCard({
    super.key,
    required this.heading,
    required this.imageUrl,
    required this.price,
    required this.onPressed,
    required this.onReadNowPressed,
    this.isPurchased = false,
  });

  final String heading;
  final String imageUrl;
  final int price;
  final VoidCallback onPressed;
  final VoidCallback onReadNowPressed;
  final bool isPurchased;

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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? kWhite : kBlack,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 12),
              // Action button and Price row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: kSidePadding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
              // Action button (left) - always go to detail screen
                    ElevatedButton.icon(
                      onPressed: onPressed,
                      icon: Icon(
                        (isPurchased || price == 0) ? Icons.menu_book_outlined : Icons.shopping_cart_outlined,
                        size: 18,
                      ),
                      label: Text(
                        (isPurchased || price == 0) ? 'Read Now' : 'Purchase',
                        style: const TextStyle(
                          color: kWhite,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kBlue,
                        foregroundColor: kWhite,
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
                    // Price/FREE (right side)
                    Text(
                      price == 0 ? 'FREE' : 'KES $price',
                      style: TextStyle(
                        color: kGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
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
