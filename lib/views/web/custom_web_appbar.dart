import 'package:flutter/material.dart';

class CustomWebAppBar extends StatelessWidget {
  final String? imageUrl;
  final VoidCallback onMenuTap;
  final VoidCallback onSearchTap;

  const CustomWebAppBar({
    super.key,
    required this.imageUrl,
    required this.onMenuTap,
    required this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 2,
      leading: GestureDetector(
        onTap: onMenuTap,
        child: CircleAvatar(
          radius: 22,
          backgroundColor: Colors.grey[200],
          backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
          child:
              imageUrl == null
                  ? Icon(Icons.person, size: 30, color: Colors.grey)
                  : null,
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onSearchTap,
              child: Container(
                height: 40,
                padding: EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey),
                    SizedBox(width: 10),
                    Text("Search...", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.notifications, color: Colors.grey),
          onPressed: () {
            // Navigate to notifications
          },
        ),
        IconButton(
          icon: Icon(Icons.message, color: Colors.grey),
          onPressed: () {
            // Navigate to messages
          },
        ),
        IconButton(
          icon: Icon(Icons.logout, color: Colors.grey),
          onPressed: () {
            // Handle logout
          },
        ),
      ],
    );
  }
}
