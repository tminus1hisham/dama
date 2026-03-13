import 'package:flutter/material.dart';
import 'package:dama/utils/constants.dart';

class ProfileAvatar extends StatefulWidget {
  final double radius;
  final ImageProvider? backgroundImage;
  final Color backgroundColor;
  final Widget? child;
  final Color? borderColor;
  final double borderWidth;
  final bool animateBorder;
  final Color? glowColor;

  // Black border color
  static const Color defaultBorderColor = Colors.black;

  // Default blue glow color
  static const Color defaultGlowColor = Colors.blue;

  const ProfileAvatar({
    super.key,
    this.radius = 50,
    this.backgroundImage,
    this.backgroundColor = kLightGrey,
    this.child,
    this.borderColor,
    this.borderWidth = 3.0,
    this.animateBorder =
        false, // Default: no animation (border only, for Home page)
    this.glowColor,
  });

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    // Animation controller for the pulsing glow effect
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Scale animation: scales from 1.0 to 1.12 (subtle breathing effect)
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Opacity animation: fades from 0.3 to 0.8 for the glow effect
    _opacityAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Start the animation if enabled
    if (widget.animateBorder) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use black as default border color
    final Color borderColor =
        widget.borderColor ?? ProfileAvatar.defaultBorderColor;

    // Use blue as default glow color
    final Color glowColor = widget.glowColor ?? ProfileAvatar.defaultGlowColor;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.animateBorder ? _scaleAnimation.value : 1.0,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // Solid black border (3-4px)
              border: Border.all(color: borderColor, width: widget.borderWidth),
              // Animated blue glow/pulse effect surrounding the black border
              boxShadow:
                  widget.animateBorder
                      ? [
                        BoxShadow(
                          color: glowColor.withValues(
                            alpha: _opacityAnimation.value,
                          ),
                          blurRadius: 15 * _scaleAnimation.value,
                          spreadRadius: 2 * _scaleAnimation.value,
                        ),
                        BoxShadow(
                          color: glowColor.withValues(
                            alpha: _opacityAnimation.value * 0.5,
                          ),
                          blurRadius: 25 * _scaleAnimation.value,
                          spreadRadius: 4 * _scaleAnimation.value,
                        ),
                      ]
                      : [
                        BoxShadow(
                          color: borderColor.withValues(alpha: 0.2),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
            ),
            child: CircleAvatar(
              radius: widget.radius,
              backgroundColor: widget.backgroundColor,
              backgroundImage: widget.backgroundImage,
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}
