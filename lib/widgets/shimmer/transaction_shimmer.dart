import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

class TransactionSkeleton extends StatelessWidget {
  const TransactionSkeleton({super.key});

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
              Padding(
                padding: EdgeInsets.only(left: 10, right: 15, top: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Skeleton.leaf(
                              child: Container(
                                height: 10,
                                width: 50,
                                decoration: BoxDecoration(
                                  color: isDarkMode ? kDarkThemeBg : kGrey,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            Skeleton.leaf(
                              child: Container(
                                height: 20,
                                width: 90,
                                decoration: BoxDecoration(
                                  color: isDarkMode ? kDarkThemeBg : kGrey,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Skeleton.leaf(
                          child: Container(
                            height: 10,
                            width: 50,
                            decoration: BoxDecoration(
                              color: isDarkMode ? kDarkThemeBg : kGrey,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        Skeleton.leaf(
                          child: Container(
                            height: 15,
                            width: 90,
                            decoration: BoxDecoration(
                              color: isDarkMode ? kDarkThemeBg : kGrey,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Skeleton.leaf(
                      child: Container(
                        height: 10,
                        width: 50,
                        decoration: BoxDecoration(
                          color: isDarkMode ? kDarkThemeBg : kGrey,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Skeleton.leaf(
                      child: Container(
                        height: 20,
                        width: 80,
                        decoration: BoxDecoration(
                          color: isDarkMode ? kDarkThemeBg : kGrey,
                          borderRadius: BorderRadius.circular(8),
                        ),
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
  }
}
