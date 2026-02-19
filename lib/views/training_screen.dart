import 'package:dama/controller/get_user_data.dart';
import 'package:dama/controller/payment_controller.dart';
import 'package:dama/controller/training_controller.dart';
import 'package:dama/controller/user_training_controller.dart';
import 'package:dama/models/training_model.dart';
import 'package:dama/routes/routes.dart';
import 'package:dama/services/api_service.dart';
import 'package:dama/services/local_storage_service.dart';
import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/views/course_sessions_screen.dart';
import 'package:dama/views/my_trainings_screen.dart';
import 'package:dama/widgets/buttons/custom_button.dart';
import 'package:dama/widgets/cards/profile_card.dart';
import 'package:dama/widgets/custom_spinner.dart';
import 'package:dama/widgets/inputs/custom_input.dart';
import 'package:dama/widgets/modals/success_bottomsheet.dart';
import 'package:dama/widgets/top_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:provider/provider.dart';

class TrainingScreen extends StatefulWidget {
  const TrainingScreen({super.key, this.training});

  final TrainingModel? training;

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final TrainingController _trainingController = Get.put(TrainingController());
  final UserTrainingController _userTrainingController =
      Get.find<UserTrainingController>();
  String imageUrl = '';
  String firstName = '';
  String lastName = '';
  String title = '';
  String bio = '';
  String memberId = '';
  late TabController _tabController;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _trainingController.fetchTrainings();
    _userTrainingController.fetchUserTrainings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _loadData() async {
    final url = await StorageService.getData('profile_picture');
    final fetchedFirstName = await StorageService.getData('firstName');
    final fetchedLastName = await StorageService.getData('lastName');
    final fetchedTitle = await StorageService.getData('title');
    final fetchedMemberId = await StorageService.getData('memberId');
    String? fetchedBio = await StorageService.getData('brief');
    setState(() {
      imageUrl = url ?? '';
      firstName = fetchedFirstName ?? '';
      lastName = fetchedLastName ?? '';
      title = fetchedTitle ?? '';
      memberId = fetchedMemberId ?? '';
      bio = fetchedBio ?? '';
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _userTrainingController.fetchUserTrainings();
    }
  }

  void _refreshUserTrainings() {
    _userTrainingController.refreshUserTrainings();
  }

  void _viewCourse() async {
    // Redirect to My Trainings screen
    Get.to(() => MyTrainingsScreen());
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;
    bool kIsWeb = MediaQuery.of(context).size.width > 1100;

    return Scaffold(
      backgroundColor: isDarkMode ? kDarkThemeBg : kBGColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TopNavigationbar(title: "Training"),
            SizedBox(height: 5),
            Container(
              color: isDarkMode ? kDarkCard : kWhite,
              child: Padding(
                padding: EdgeInsets.only(top: 10, bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      child: Text(
                        "Get Certified.",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? kWhite : kBlack,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      child: Text(
                        "Advance your data management career",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? kWhite : kBlack,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Obx(() {
                      int inProgress =
                          _userTrainingController.userTrainings
                              .where((t) {
                                final status = (t.status ?? '').toLowerCase();
                                final regStatus = (t.learningTracks.isNotEmpty
                                    ? t.learningTracks.first.registrationStatus
                                    : '')
                                    .toLowerCase();
                                return status == 'ongoing' || regStatus == 'ongoing';
                              })
                              .length;
                      int completed =
                          _userTrainingController.userTrainings
                              .where((t) {
                                final status = (t.status ?? '').toLowerCase();
                                final progress = t.progress ?? 0;
                                return status.contains('completed') || progress == 100;
                              })
                              .length;
                      int total = _userTrainingController.userTrainings.length;
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatCard(
                              'In Progress',
                              inProgress,
                              Icons.play_arrow,
                              isDarkMode,
                            ),
                            _buildStatCard(
                              'Completed',
                              completed,
                              Icons.check_circle,
                              isDarkMode,
                            ),
                            _buildStatCard('Total', total, Icons.list, isDarkMode),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            Container(
              color: isDarkMode ? kDarkCard : kWhite,
              child: TabBar(
                controller: _tabController,
                indicatorColor: kBlue,
                labelColor: kBlue,
                unselectedLabelColor: isDarkMode ? kWhite : kBlack,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_bag),
                        SizedBox(width: 8),
                        Text('Available Trainings'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.school),
                        SizedBox(width: 8),
                        Text('My Trainings'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Available Trainings Tab
                  _buildAvailableTrainingsTab(isDarkMode, kIsWeb),
                  // My Trainings Tab
                  _buildMyTrainingsTab(isDarkMode, kIsWeb),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableTrainingsTab(bool isDarkMode, bool kIsWeb) {
    return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 1500),
                child: Padding(
                  padding: EdgeInsets.only(top: 10, bottom: 80),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (kIsWeb)
                        ProfileCard(
                          isDarkMode: isDarkMode,
                          imageUrl: imageUrl,
                          firstName: firstName,
                          lastName: lastName,
                          title: title,
                          bio: bio,
                        ),
                      if (kIsWeb) SizedBox(width: 10),
                      Expanded(
                        child: Obx(() {
                          if (_trainingController.isLoading.value) {
                            return Center(child: customSpinner);
                          }

                          if (_trainingController
                              .errorMessage
                              .value
                              .isNotEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    "Failed to load trainings",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed:
                                        () =>
                                            _trainingController
                                                .refreshTrainings(),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: kBlue,
                                      foregroundColor: kWhite,
                                    ),
                                    child: Text("Retry"),
                                  ),
                                ],
                              ),
                            );
                          }

                          return RefreshIndicator(
                            color: kWhite,
                            backgroundColor: kBlue,
                            onRefresh: () async {
                              await _trainingController.refreshTrainings();
                              await _userTrainingController
                                  .refreshUserTrainings();
                            },
                            child: Center(
                              child: ListView.builder(
                                padding: const EdgeInsets.all(0),
                                itemCount:
                                    _trainingController.trainings.length,
                                itemBuilder: (context, index) {
                                  final training =
                                      _trainingController.trainings[index];
                                  return TrainingCard(
                                    isDarkMode: isDarkMode,
                                    training: training,
                                    onJoinPressed: () {
                                      _showTrainingDetails(
                                        context,
                                        training,
                                        isDarkMode,
                                      );
                                    },
                                    onRefreshPressed: _refreshUserTrainings,
                                    onViewCoursePressed: _viewCourse,
                                  );
                                },
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            );
  }

  Widget _buildMyTrainingsTab(bool isDarkMode, bool kIsWeb) {
    return Obx(() {
      if (_userTrainingController.isLoading.value) {
        return Center(child: customSpinner);
      }

      if (_userTrainingController.errorMessage.value.isNotEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.grey[400],
              ),
              SizedBox(height: 16),
              Text(
                "Failed to load your trainings",
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _userTrainingController.refreshUserTrainings(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBlue,
                  foregroundColor: kWhite,
                ),
                child: Text("Retry"),
              ),
            ],
          ),
        );
      }

      if (_userTrainingController.userTrainings.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.school_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              SizedBox(height: 16),
              Text(
                "No trainings yet",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[600]),
              ),
              SizedBox(height: 8),
              Text(
                "Enroll in a training to get started",
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        );
      }

      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 1500),
          child: RefreshIndicator(
            color: kWhite,
            backgroundColor: kBlue,
            onRefresh: () async {
              await _userTrainingController.refreshUserTrainings();
            },
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              itemCount: _userTrainingController.userTrainings.length,
              itemBuilder: (context, index) {
                final training = _userTrainingController.userTrainings[index];
                return TrainingCard(
                  isDarkMode: isDarkMode,
                  training: training,
                  onJoinPressed: () {
                    _showTrainingDetails(context, training, isDarkMode);
                  },
                  onRefreshPressed: _refreshUserTrainings,
                  onViewCoursePressed: _viewCourse,
                );
              },
            ),
          ),
        ),
      );
    });
  }

  void _showTrainingDetails(
    BuildContext context,
    TrainingModel training,
    bool isDarkMode,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => TrainingDetailModal(
            training: training,
            isDarkMode: isDarkMode,
            onRefreshPressed: _refreshUserTrainings,
          ),
    );
  }

  Widget _buildStatCard(
    String label,
    int count,
    IconData icon,
    bool isDarkMode,
  ) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 12),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[800] : kWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isDarkMode
                    ? Colors.grey[700]!
                    : Colors.grey[200]!,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: kBlue,
            ),
            SizedBox(height: 8),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? kWhite : kBlack,
              ),
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? kGrey : kGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TrainingCard extends StatelessWidget {
  const TrainingCard({
    super.key,
    required this.isDarkMode,
    required this.training,
    required this.onJoinPressed,
    required this.onRefreshPressed,
    required this.onViewCoursePressed,
  });

  final bool isDarkMode;
  final TrainingModel training;
  final VoidCallback onJoinPressed;
  final VoidCallback onRefreshPressed;
  final VoidCallback onViewCoursePressed;

  @override
  Widget build(BuildContext context) {
    final UserTrainingController userTrainingController =
        Get.find<UserTrainingController>();

    return Obx(() {
      final hasUserTrainingError =
          userTrainingController.errorMessage.value.isNotEmpty;
      final isLoadingUserTrainings = userTrainingController.isLoading.value;
      final isEnrolled = userTrainingController.userTrainings.any(
        (t) => t.id == training.id,
      );

      return Padding(
        padding: EdgeInsets.only(top: 5),
        child: Container(
          color: isDarkMode ? kDarkCard : kWhite,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Training image placeholder
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [kBlue.withOpacity(0.8), kBlue.withOpacity(0.6)],
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.school, size: 60, color: kWhite),
                          SizedBox(height: 10),
                          Text(
                            "DAMA KENYA",
                            style: TextStyle(
                              color: kWhite,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (training.learningTracks.isNotEmpty)
                      Positioned(
                        top: 15,
                        right: 15,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: kWhite,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${training.learningTracks.first.currency} ${training.learningTracks.first.price}',
                            style: TextStyle(
                              color: kBlue,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 15),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: Text(
                  training.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? kWhite : kBlack,
                  ),
                ),
              ),
              SizedBox(height: 10),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: Text(
                  training.description,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDarkMode ? kWhite : kBlack,
                    height: 1.4,
                  ),
                ),
              ),
              if (training.learningTracks.isNotEmpty) ...[
                SizedBox(height: 15),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 15),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 16,
                        color: isDarkMode ? kWhite : kGrey,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          training.learningTracks.first.duration,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? kWhite : kGrey,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              training
                                          .learningTracks
                                          .first
                                          .registrationStatus ==
                                      'ongoing'
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          training.learningTracks.first.registrationStatus
                              .toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color:
                                training
                                            .learningTracks
                                            .first
                                            .registrationStatus ==
                                        'ongoing'
                                    ? Colors.green
                                    : Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                child: CustomButton(
                  callBackFunction:
                      hasUserTrainingError
                          ? onRefreshPressed
                          : (isLoadingUserTrainings
                              ? () {}
                              : (isEnrolled
                                  ? onViewCoursePressed
                                  : onJoinPressed)),
                  label:
                      hasUserTrainingError
                          ? "Retry loading status"
                          : (isLoadingUserTrainings
                              ? "Loading..."
                              : (isEnrolled
                                  ? "Go to Dashboard"
                                  : "Enroll now")),
                  backgroundColor: kBlue,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class TrainingDetailModal extends StatefulWidget {
  final TrainingModel training;
  final bool isDarkMode;
  final VoidCallback onRefreshPressed;

  const TrainingDetailModal({
    super.key,
    required this.training,
    required this.isDarkMode,
    required this.onRefreshPressed,
  });

  @override
  State<TrainingDetailModal> createState() => _TrainingDetailModalState();
}

class _TrainingDetailModalState extends State<TrainingDetailModal> {
  final PaymentController _paymentController = Get.put(PaymentController());
  final GetUserProfileController _getUserProfileController = Get.put(
    GetUserProfileController(),
  );

  String? completePhoneNumber;
  String? countryCode = '+254';
  String phoneNumber = '';
  String? fetchedPhoneNumber;
  String fetchedUserId = '';
  LearningTrack? selectedTrack;

  @override
  void initState() {
    super.initState();
    _fetchPhoneNumberAndUser();
    // Refresh user trainings to ensure latest enrollment status
    // Get.find<UserTrainingController>().fetchUserTrainings(); // Removed to avoid setState during build
    // Set default track to first one
    if (widget.training.learningTracks.isNotEmpty) {
      selectedTrack = widget.training.learningTracks.first;
    }
  }

  Future<void> _fetchPhoneNumberAndUser() async {
    fetchedPhoneNumber = await StorageService.getData("phoneNumber");
    fetchedUserId = await StorageService.getData('userId');
    await _getUserProfileController.fetchUserProfile(fetchedUserId);
  }

  void _showPhoneNumberModal() {
    if (selectedTrack == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a learning track first')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: widget.isDarkMode ? kDarkThemeBg : kWhite,
      builder: (context) {
        return SafeArea(
          bottom: true,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    'Enroll in ${widget.training.title}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: widget.isDarkMode ? kWhite : kBlack,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Track: ${selectedTrack!.type.toUpperCase()}',
                    style: TextStyle(
                      fontSize: 14,
                      color: widget.isDarkMode ? kWhite : kGrey,
                    ),
                  ),
                  Text(
                    'Amount: ${selectedTrack!.currency} ${selectedTrack!.price}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: kBlue,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Image.asset("images/mpesa.png", height: 50),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Phone Number *",
                          style: TextStyle(
                            color: widget.isDarkMode ? kWhite : kBlack,
                            fontWeight: FontWeight.bold,
                            fontSize: kNormalTextSize,
                          ),
                        ),
                        SizedBox(height: 8),
                        IntlPhoneField(
                          decoration: InputDecoration(
                            hintText: "7*******",
                            hintStyle: TextStyle(
                              color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[700],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide(color: kBlue, width: 1.0),
                            ),
                          ),
                          style: TextStyle(
                            color: widget.isDarkMode ? kWhite : kBlack,
                          ),
                          dropdownTextStyle: TextStyle(
                            color: widget.isDarkMode ? kWhite : kBlack,
                          ),
                          dropdownIcon: Icon(
                            Icons.arrow_drop_down,
                            color: widget.isDarkMode ? kWhite : kBlack,
                          ),
                          initialCountryCode: 'KE',
                          onChanged: (PhoneNumber phone) {
                            completePhoneNumber = phone.completeNumber;
                          },
                          onCountryChanged: (country) {
                            countryCode = '+${country.dialCode}';
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        callBackFunction: () {
                          Navigator.pop(context);
                          phoneNumber = completePhoneNumber ?? '';
                          _payForTraining();
                        },
                        label: "Confirm Payment",
                        backgroundColor: kBlue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _payForTraining() async {
    if (selectedTrack == null) return;

    // Check if user is already enrolled
    final UserTrainingController userTrainingController =
        Get.find<UserTrainingController>();
    await userTrainingController
        .fetchUserTrainings(); // Refresh to get latest data
    final isAlreadyEnrolled = userTrainingController.userTrainings.any(
      (t) => t.id == widget.training.id,
    );

    if (isAlreadyEnrolled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You are already enrolled in this training.')),
      );
      Navigator.pop(context); // Close the modal
      return;
    }

    _paymentController
      ..amountToPay.value = selectedTrack!.price
      ..model.value = 'Training'
      ..object_id.value = widget.training.id
      ..phoneNumber.value = phoneNumber;

    final success = await _paymentController.pay(context);

    if (success) {
      // Refresh user trainings list after successful payment
      await userTrainingController.fetchUserTrainings();

      // Call the refresh callback to update the parent widget
      widget.onRefreshPressed();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          showSuccessBottomSheet(
            context,
            widget.training.title,
            'Training enrollment',
            selectedTrack!.type,
            widget.isDarkMode,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    Get.find<UserTrainingController>().fetchUserTrainings();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate height to ensure content is fully visible
    // No need to reserve space for bottom action bar anymore
    final double availableHeight = MediaQuery.of(context).size.height;
    final double modalHeight =
        availableHeight * 0.95; // Increased to use more screen space

    return Container(
      height: modalHeight.clamp(
        600,
        MediaQuery.of(context).size.height * 0.95,
      ), // Adjusted min and max height
      decoration: BoxDecoration(
        color: widget.isDarkMode ? kBlack : kWhite,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Obx(() {
        return Stack(
          children: [
            Column(
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color:
                            widget.isDarkMode
                                ? Colors.grey[700]!
                                : Colors.grey[200]!,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Training Details",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: widget.isDarkMode ? kWhite : kBlack,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close,
                          color: widget.isDarkMode ? kWhite : kBlack,
                        ),
                      ),
                    ],
                  ),
                ),

                // Content - Make it fill remaining space
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: 10,
                      bottom:
                          20, // Reduced padding since button is now in scrollable area
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          widget.training.title,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: widget.isDarkMode ? kWhite : kBlack,
                          ),
                        ),
                        SizedBox(height: 12), // Reduced from 15
                        // Description
                        Text(
                          widget.training.description,
                          style: TextStyle(
                            fontSize: 16,
                            color: widget.isDarkMode ? kWhite : kBlack,
                            height: 1.5,
                          ),
                        ),
                        SizedBox(height: 20), // Reduced from 25
                        // Learning Tracks
                        if (widget.training.learningTracks.isNotEmpty) ...[
                          _buildSectionTitle("Learning Tracks"),
                          ...widget.training.learningTracks.map(
                            (track) => _buildTrackCard(track),
                          ),
                          SizedBox(height: 15), // Reduced from 20
                        ],

                        // Target Audience
                        if (widget.training.targetAudience.isNotEmpty) ...[
                          _buildSectionTitle("Target Audience"),
                          ...widget.training.targetAudience.map(
                            (audience) => _buildBulletPoint(audience),
                          ),
                          SizedBox(height: 15), // Reduced from 20
                        ],

                        // Learning Outcomes
                        if (widget.training.learningOutcomes.isNotEmpty) ...[
                          _buildSectionTitle("Learning Outcomes"),
                          ...widget.training.learningOutcomes.map(
                            (outcome) => _buildBulletPoint(outcome),
                          ),
                          SizedBox(height: 15), // Reduced from 20
                        ],

                        // Course Outline
                        if (widget.training.courseOutline.isNotEmpty) ...[
                          _buildSectionTitle("Course Outline"),
                          ...widget.training.courseOutline.map(
                            (outline) => _buildOutlineCard(outline),
                          ),
                        ],

                        // Demarcation line before enrollment button
                        SizedBox(height: 20),
                        Divider(
                          color:
                              widget.isDarkMode
                                  ? Colors.grey[600]
                                  : Colors.grey[300],
                          thickness: 1,
                          height: 1,
                        ),
                        SizedBox(height: 20),

                        // Enrollment Button - Now in scrollable content
                        SizedBox(height: 30),
                        Obx(() {
                          final UserTrainingController userTrainingController =
                              Get.find<UserTrainingController>();
                          final hasUserTrainingError =
                              userTrainingController
                                  .errorMessage
                                  .value
                                  .isNotEmpty;
                          final isLoadingUserTrainings =
                              userTrainingController.isLoading.value;

                          return SizedBox(
                            width: double.infinity,
                            child: CustomButton(
                              callBackFunction:
                                  hasUserTrainingError
                                      ? widget.onRefreshPressed
                                      : (isLoadingUserTrainings
                                          ? () {}
                                          : _showPhoneNumberModal),
                              label:
                                  selectedTrack != null
                                      ? "Enroll Now - ${selectedTrack!.currency} ${selectedTrack!.price}"
                                      : "Select a Track",
                              backgroundColor: kBlue,
                            ),
                          );
                        }),
                        SizedBox(height: 20), // Extra space at bottom
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Loading overlay
            ...(_paymentController.isLoading.value
                ? [
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: Center(child: customSpinner),
                  ),
                ]
                : []),
          ],
        );
      }),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: widget.isDarkMode ? kWhite : kBlack,
        ),
      ),
    );
  }

  Widget _buildTrackCard(LearningTrack track) {
    bool isSelected = selectedTrack?.id == track.id;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTrack = track;
        });
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? kBlue.withOpacity(0.1)
                  : (widget.isDarkMode ? Colors.grey[800] : Colors.grey[50]),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                isSelected
                    ? kBlue
                    : (widget.isDarkMode
                        ? Colors.grey[700]!
                        : Colors.grey[200]!),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (isSelected)
                      Icon(Icons.check_circle, color: kBlue, size: 20),
                    if (isSelected) SizedBox(width: 8),
                    Text(
                      track.type.toUpperCase(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? kBlue : kBlue,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${track.currency} ${track.price}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: widget.isDarkMode ? kWhite : kBlack,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Duration: ${track.duration}',
              style: TextStyle(
                fontSize: 14,
                color: widget.isDarkMode ? kWhite : kBlack,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Schedule: ${track.schedule}',
              style: TextStyle(
                fontSize: 14,
                color: widget.isDarkMode ? kWhite : kBlack,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "• ",
            style: TextStyle(
              fontSize: 16,
              color: kBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: widget.isDarkMode ? kWhite : kBlack,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutlineCard(CourseOutline outline) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? Colors.grey[800] : Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: widget.isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                outline.day,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: kBlue,
                ),
              ),
              SizedBox(width: 10),
              Text(
                outline.time,
                style: TextStyle(
                  fontSize: 12,
                  color:
                      widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            outline.topic,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: widget.isDarkMode ? kWhite : kBlack,
            ),
          ),
          SizedBox(height: 4),
          Text(
            outline.description,
            style: TextStyle(
              fontSize: 14,
              color: widget.isDarkMode ? kWhite : kBlack,
            ),
          ),
        ],
      ),
    );
  }
}
