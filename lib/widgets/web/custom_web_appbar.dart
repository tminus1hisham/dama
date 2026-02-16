import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:dama/utils/constants.dart';

class CustomWebAppBar extends StatelessWidget {
  const CustomWebAppBar({super.key, required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      child: Container(
        color: kWhite,
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Logo or User Avatar
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: kLightGrey,
                  backgroundImage:
                      imageUrl != null ? NetworkImage(imageUrl!) : null,
                  child:
                      imageUrl == null
                          ? Icon(Icons.person, size: 28, color: kGrey)
                          : null,
                ),
                const SizedBox(width: 12),
                Text(
                  "Dama Web",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: kBlue,
                  ),
                ),
              ],
            ),

            // Navigation icons with hover effect
            Row(
              children: [
                _NavBarIcon(
                  icon: FontAwesomeIcons.house,
                  tooltip: 'Home',
                  onTap: () {},
                ),
                const SizedBox(width: 20),
                _NavBarIcon(
                  icon: FontAwesomeIcons.solidBell,
                  tooltip: 'Notifications',
                  onTap: () {},
                ),
                const SizedBox(width: 20),
                _NavBarIcon(
                  icon: FontAwesomeIcons.solidMessage,
                  tooltip: 'Messages',
                  onTap: () {},
                ),
                const SizedBox(width: 20),
                _NavBarIcon(
                  icon: FontAwesomeIcons.gear,
                  tooltip: 'Settings',
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NavBarIcon extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _NavBarIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_NavBarIcon> createState() => _NavBarIconState();
}

class _NavBarIconState extends State<_NavBarIcon> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Tooltip(
          message: widget.tooltip,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _hovering ? kLightGrey : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(widget.icon, color: kGrey, size: 22),
          ),
        ),
      ),
    );
  }
}
