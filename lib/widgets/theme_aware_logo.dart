import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../utils/theme_provider.dart';

/// A widget that displays the DAMA logo with theme-aware coloring.
/// In dark mode, uses logo_dark.svg which has white "KENYA" and "TM" text.
/// In light mode, uses logo_light.svg which has black "KENYA" and "TM" text.
class ThemeAwareLogo extends StatelessWidget {
  final double? height;
  final double? width;
  final BoxFit fit;

  const ThemeAwareLogo({
    super.key,
    this.height,
    this.width,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDark;

    return SvgPicture.asset(
      isDarkMode ? 'images/logo_dark.svg' : 'images/logo_light.svg',
      height: height,
      width: width,
      fit: fit,
    );
  }
}

/// A Hero widget wrapper for the theme-aware logo, commonly used in auth screens.
class HeroThemeAwareLogo extends StatelessWidget {
  final String tag;
  final double? height;
  final double? width;

  const HeroThemeAwareLogo({
    super.key,
    this.tag = "logo",
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDark;

    return Hero(
      tag: tag,
      child: SvgPicture.asset(
        isDarkMode ? 'images/logo_dark.svg' : 'images/logo_light.svg',
        height: height,
        width: width,
      ),
    );
  }
}
