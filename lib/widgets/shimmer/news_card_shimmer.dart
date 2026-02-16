import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

class NewsCardSkeleton extends StatelessWidget {
  const NewsCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    bool isDarkMode = themeProvider.isDark;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Skeletonizer(
        enabled: true,
        effect: ShimmerEffect(
          baseColor: themeProvider.isDark ? Color(0xFF222531) : Color(0xFFF4F6FF),
          highlightColor:
          themeProvider.isDark ? Color(0xFF2C2F3E) : Color(0xFFE4E0E1),
          duration: Duration(seconds: 1),
        ),
        child: Container(
          color: isDarkMode ? kBlack : kWhite,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Row (time + News button)
              Padding(
                padding: EdgeInsets.only(left: 10, right: 15, top: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Skeleton.leaf(
                          child: Container(
                            height: 50,
                            width: 50,
                            decoration: BoxDecoration(
                              color: kGrey,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Skeleton.leaf(
                              child: Container(
                                height: 10,
                                width: 80,
                                decoration: BoxDecoration(
                                  color: kGrey,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            Skeleton.leaf(
                              child: Container(
                                height: 10,
                                width: 60,
                                decoration: BoxDecoration(
                                  color: kGrey,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // "News" badge skeleton
                    Skeleton.leaf(
                      child: Container(
                        height: 20,
                        width: 50,
                        decoration: BoxDecoration(
                          color: kGrey,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  top: 10,
                  left: 10,
                  right: kSidePadding,
                  bottom: 10,
                ),
                child: Skeleton.leaf(
                  child: Container(
                    height: 20,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: kGrey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              Skeleton.leaf(
                child: Container(
                  height: 180,
                  width: double.infinity,
                  color: kGrey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
