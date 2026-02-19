import 'package:flutter/material.dart';
import 'package:dama/utils/constants.dart';

class ProfileAvatar extends StatelessWidget {
  final double radius;
  final ImageProvider? backgroundImage;
  final Color backgroundColor;
  final Widget? child;
  final Color? borderColor;
  final double borderWidth;

  const ProfileAvatar({
    super.key,
    this.radius = 20,
    this.backgroundImage,
    this.backgroundColor = kLightGrey,
    this.child,
    this.borderColor,
    this.borderWidth = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    // Use blue as default border color to match app theme
    final border = Border.all(
      color: borderColor ?? kBlue,
      width: borderWidth,
    );

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: border,
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        backgroundImage: backgroundImage,
        child: child,
      ),
    );
  }
}
