// import 'package:dama/controller/fetchUserProfile.dart';
// import 'package:dama/controller/get_news_by_id.dart';
// import 'package:dama/routes/routes.dart';
// import 'package:dama/utils/constants.dart';
// import 'package:flutter/material.dart';
// import 'package:dama/widgets/top_navigation_bar.dart';
// import 'package:get/get.dart';

// class SelectedNews extends StatefulWidget {
//   const SelectedNews({required this.newsId});

//   final String newsId;

//   @override
//   State<SelectedNews> createState() => _SelectedNewsState();
// }

// class _SelectedNewsState extends State<SelectedNews> {
//   final FetchUserProfileController _fetchUserProfileController = Get.put(
//     FetchUserProfileController(),
//   );
//   final FetchNewsByIdController _newsController = Get.put(
//     FetchNewsByIdController(),
//   );

//   @override
//   void initState() {
//     super.initState();
//     _newsController.fetchNews(widget.newsId).then((_) {
//       final newsItem = _newsController.news.value;
//       if (newsItem?.author.id?.isNotEmpty == true) {
//         _fetchUserProfileController.fetchUserProfile(newsItem!.author.id);
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: kBGColor,
//       body: Obx(() {
//         if (_newsController.isLoading.value) {
//           return const Center(child: CircularProgressIndicator());
//         }

//         final news = _newsController.news.value;
//         if (news == null) {
//           return const Center(child: Text("News not found."));
//         }

//         final userProfile = _fetchUserProfileController.profile.value;
//         final authorName =
//             userProfile != null
//                 ? '${userProfile.firstName} ${userProfile.lastName}'
//                 : news.author;
//         final profileImage =
//             userProfile != null
//                 ? userProfile.profilePicture
//                 : news.author.profilePicture ?? '';

//         return Column(
//           children: [
//             TopNavigationbar(
//               title: news.title,
//               onBack: () {
//                 Navigator.pushNamed(context, AppRoutes.home);
//               },
//             ),
//             Expanded(
//               child: MediaQuery.removePadding(
//                 context: context,
//                 removeTop: true,
//                 child: ListView(
//                   children: [
//                     const SizedBox(height: 10),
//                     Center(
//                       child: ConstrainedBox(
//                         constraints: const BoxConstraints(maxWidth: 700),
//                         child: Container(
//                           color: kWhite,
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.stretch,
//                             children: [
//                               if (news.imageUrl.isNotEmpty)
//                                 Image.network(
//                                   news.imageUrl,
//                                   fit: BoxFit.cover,
//                                   width: double.infinity,
//                                 ),
//                               const SizedBox(height: 10),
//                               Padding(
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: kSidePadding,
//                                 ),
//                                 child: Row(
//                                   children: [
//                                     CircleAvatar(
//                                       radius: 25,
//                                       backgroundColor: kLightGrey,
//                                       backgroundImage:
//                                           profileImage.isNotEmpty
//                                               ? NetworkImage(profileImage)
//                                               : null,
//                                       child:
//                                           profileImage.isEmpty
//                                               ? const Icon(
//                                                 Icons.person,
//                                                 size: 30,
//                                                 color: kGrey,
//                                               )
//                                               : null,
//                                     ),
//                                     const SizedBox(width: 10),
//                                     Column(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         Text(
//                                           '${news.author.firstName} ${news.author.lastName}',
//                                           style: const TextStyle(
//                                             fontWeight: FontWeight.bold,
//                                           ),
//                                         ),
//                                         Text('${news.createdAt}'),
//                                       ],
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                               const Padding(
//                                 padding: EdgeInsets.symmetric(
//                                   horizontal: kSidePadding,
//                                   vertical: 10,
//                                 ),
//                                 child: Divider(color: kBGColor, thickness: 2),
//                               ),
//                               Padding(
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: kSidePadding,
//                                   vertical: 10,
//                                 ),
//                                 child: Text(
//                                   news.title,
//                                   style: const TextStyle(
//                                     fontSize: kBigTextSize,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                               ),
//                               Padding(
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: kSidePadding,
//                                 ),
//                                 child: Text(
//                                   news.description,
//                                   style: const TextStyle(
//                                     fontSize: kNormalTextSize,
//                                   ),
//                                 ),
//                               ),
//                               const SizedBox(height: 20),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         );
//       }),
//     );
//   }
// }
