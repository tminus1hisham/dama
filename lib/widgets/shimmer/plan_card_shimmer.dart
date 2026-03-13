import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

class PlanCardSkeleton extends StatelessWidget {
  const PlanCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDarkMode = themeProvider.isDark;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Skeletonizer(
        enabled: true,
        effect: ShimmerEffect(
          baseColor:
              isDarkMode ? const Color(0xFF222531) : const Color(0xFFF4F6FF),
          highlightColor:
              isDarkMode ? const Color(0xFF2C2F3E) : const Color(0xFFE4E0E1),
          duration: const Duration(seconds: 1),
        ),
        child: Container(
          color: isDarkMode ? kBlack : kWhite,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon
              Padding(
                padding: const EdgeInsets.only(left: 20, top: 20),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Skeleton.leaf(
                    child: Container(
                      height: 30,
                      width: 30,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: kGrey,
                      ),
                    ),
                  ),
                ),
              ),
              // Plan Text
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: TextSelectionToolbar.kHandleSize,
                  vertical: 10,
                ),
                child: Skeleton.leaf(
                  child: Container(
                    height: 20,
                    width: 100,
                    decoration: BoxDecoration(
                      color: kGrey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              // Lock and Text
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Row(
                  children: [
                    Skeleton.leaf(
                      child: Container(
                        height: 15,
                        width: 15,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: kGrey,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Skeleton.leaf(
                      child: Container(
                        height: 10,
                        width: 180,
                        decoration: BoxDecoration(
                          color: kGrey,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Divider
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: kSidePadding,
                  vertical: 15,
                ),
                child: Container(height: 1, color: kGrey),
              ),
              // Amount + Text
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: kSidePadding),
                child: Row(
                  children: [
                    Skeleton.leaf(
                      child: Container(
                        height: 20,
                        width: 80,
                        decoration: BoxDecoration(
                          color: kGrey,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Skeleton.leaf(
                      child: Container(
                        height: 10,
                        width: 50,
                        decoration: BoxDecoration(
                          color: kGrey,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: kSidePadding),
                child: Skeleton.leaf(
                  child: Container(
                    height: 45,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: kGrey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
