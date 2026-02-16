import 'package:dama/controller/article_count_controller.dart';
import 'package:dama/controller/payment_controller.dart';
import 'package:dama/controller/plans_controller.dart';
import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/utils/utils.dart';
import 'package:dama/widgets/buttons/custom_button.dart';
import 'package:dama/widgets/cards/plans_card.dart';
import 'package:dama/widgets/custom_spinner.dart';
import 'package:dama/widgets/inputs/custom_input.dart';
import 'package:dama/widgets/shimmer/plan_card_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  final PlansController _plansController = Get.put(PlansController());
  final PaymentController _paymentController = Get.put(PaymentController());
  final ArticleCountController _articleCountController = Get.put(
    ArticleCountController(),
  );
  final TextEditingController _phoneController = TextEditingController();

  final Utils _utils = Utils();
  late final GlobalKey<ScaffoldState> _planKey;

  // Use nullable boolean to track loading state
  final Rx<bool?> membershipExpired = Rx<bool?>(null);

  @override
  void initState() {
    super.initState();
    _planKey = GlobalKey();
    // Check membership expiration first, before plans are loaded
    _checkUserPlanStatus();
  }

  // Check membership expiration and wait for it to complete
  Future<void> _checkUserPlanStatus() async {
    try {
      bool canRead =
          await _articleCountController.checkArticleLimitBeforeReading();
      membershipExpired.value = !canRead;
    } catch (e) {
      membershipExpired.value = true;
    }
  }

  String _getButtonText(String planType) {
    if (!_plansController.hasActivePlan.value) {
      return "Activate";
    }

    String currentPlan = _plansController.currentUserPlan.value;
    String planTypeLower = planType.toLowerCase();

    if (currentPlan == planTypeLower) {
      return "Active";
    } else {
      return "Activate";
    }
  }

  bool _isButtonEnabled(String planType) {
    if (membershipExpired.value == null) {
      return false;
    }

    if (membershipExpired.value == true) {
      return true;
    }

    if (!_plansController.hasActivePlan.value) {
      return true;
    }

    String currentPlan = _plansController.currentUserPlan.value;
    String planTypeLower = planType.toLowerCase();

    return currentPlan != planTypeLower;
  }

  Color _getButtonColor(String planType, String buttonText) {
    switch (buttonText) {
      case "Active":
        return kGreen;
      default:
        // For "Activate", use plan-specific color
        return _getPlanColor(planType);
    }
  }

  Color _getPlanColor(String planType) {
    switch (planType.toLowerCase()) {
      case "student":
        return kBlue;
      case "professional":
        return kYellow;
      case "corporate":
        return kOrange;
      default:
        return kBlue;
    }
  }

  void _showFullMessageBottomSheet(
    BuildContext context,
    String membership,
    bool isDark,
    int amount,
    IconData icon,
    String planID,
    String plan,
  ) {
    // Check if button should be enabled before showing bottom sheet
    if (!_isButtonEnabled(membership)) {
      Get.snackbar(
        'Info',
        'This is your current active plan',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
      return;
    }

    showModalBottomSheet(
      backgroundColor: isDark ? kDarkThemeBg : kWhite,
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            String buttonText = _getButtonText(membership);
            Color buttonColor = _getButtonColor(membership, buttonText);

            return SafeArea(
              bottom: true,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: kBGColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: kSidePadding),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Icon(
                            membership.toLowerCase() == "student"
                                ? FontAwesomeIcons.graduationCap
                                : membership.toLowerCase() == "professional"
                                ? FontAwesomeIcons.briefcase
                                : FontAwesomeIcons.building,
                            size: 30,
                            color: kBlue,
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: kSidePadding),
                        child: Text(
                          membership,
                          style: TextStyle(
                            fontSize: kBigTextSize,
                            color: isDark ? kWhite : kBlack,
                          ),
                        ),
                      ),

                      // Show current plan status using controller observables
                      Obx(() {
                        if (_plansController.hasActivePlan.value &&
                            membershipExpired.value != true) {
                          return Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: kSidePadding,
                            ),
                            child: Container(
                              margin: EdgeInsets.only(top: 10),
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.blue.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                'Current Plan: ${_plansController.currentUserPlan.value.toUpperCase()}',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }
                        return SizedBox.shrink();
                      }),

                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: kSidePadding),
                        child: Row(
                          children: [
                            Icon(FontAwesomeIcons.lock, color: kGrey, size: 15),
                            SizedBox(width: 10),
                            Text(
                              "Payments are secure & encrypted",
                              style: TextStyle(color: kGrey),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10),
                      InputField(
                        controller: _phoneController,
                        hintText: "eg: 07XXXXXXXX",
                        label: "Phone Number *",
                      ),
                      SizedBox(height: 15),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: kSidePadding),
                        child: Text(
                          'Breakdown',
                          style: TextStyle(
                            fontSize: kBigTextSize,
                            color: isDark ? kWhite : kBlack,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: kSidePadding),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  "KES $amount",
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: isDark ? kWhite : kBlack,
                                  ),
                                ),
                                SizedBox(width: 5),
                                Text("/ month", style: TextStyle(color: kGrey)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: kSidePadding),
                        child: Container(height: 1, color: kGrey),
                      ),
                      SizedBox(height: 10),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: kSidePadding),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Total",
                              style: TextStyle(
                                color: isDark ? kWhite : kBlack,
                                fontSize: kBigTextSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "KES $amount",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: kBigTextSize,
                                color: isDark ? kWhite : kBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: kSidePadding),
                        child: CustomButton(
                          callBackFunction:
                              buttonText == "Active"
                                  ? null
                                  : () {
                                    if (_phoneController.text.isNotEmpty) {
                                      _payForPlan(
                                        context,
                                        amount,
                                        planID,
                                        _utils.formatPhoneNumber(
                                          _phoneController.text,
                                        ),
                                        plan,
                                        isDark,
                                      );
                                      Navigator.pop(context);
                                    } else {
                                      Get.snackbar(
                                        'Error',
                                        'Please enter a phone number',
                                        backgroundColor: Colors.red,
                                        colorText: Colors.white,
                                      );
                                    }
                                  },
                          label: "Confirm $buttonText",
                          backgroundColor:
                              buttonText == "Active"
                                  ? buttonColor.withOpacity(0.6)
                                  : buttonColor,
                        ),
                      ),
                      SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _payForPlan(
    BuildContext context,
    price,
    planID,
    phoneNumber,
    plan,
    isDark,
  ) async {
    _paymentController.amountToPay.value = price;
    _paymentController.model.value = 'Plan';
    _paymentController.object_id.value = planID;
    _paymentController.phoneNumber.value = phoneNumber;

    final result = await _paymentController.pay(context);

    // Refresh both controller and local membership status
    await _plansController.refreshPlanStatus();
    await _checkUserPlanStatus();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _planKey.currentContext;
      if (context != null && context.mounted) {
        showSuccessPlanPurchase(context, plan, price, isDark);
      } else {
        ScaffoldMessenger.of(
          _planKey.currentContext!,
        ).showSnackBar(SnackBar(content: Text('Payment successful!')));
      }
    });
  }

  void showSuccessPlanPurchase(
    BuildContext context,
    String? plan,
    int price,
    bool isDark,
  ) {
    if (!context.mounted) {
      return;
    }

    showModalBottomSheet(
      backgroundColor: isDark ? kBlack : kWhite,
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder:
          (context) => SafeArea(
            bottom: true,
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 100),
                  SizedBox(height: 20),
                  Text(
                    'Subscription Confirmed',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? kWhite : kBlack,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12),
                  Text(
                    "Thank you for subscribing to the $plan plan.",
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? kWhite : kBlack,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),
                  Text(
                    'KES: $price',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? kWhite : kBlack,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 30),
                ],
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;

    return SafeArea(
      bottom: true,
      child: Obx(
        () => Stack(
          children: [
            Scaffold(
              key: _planKey,
              backgroundColor: isDarkMode ? kDarkThemeBg : kBGColor,
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    color: isDarkMode ? kBlack : kWhite,
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: 30,
                        left: kSidePadding,
                        right: kSidePadding,
                      ),
                      child: Padding(
                        padding: EdgeInsets.only(top: 20),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: Icon(
                                Icons.arrow_back_ios,
                                color: isDarkMode ? kWhite : kBlack,
                              ),
                            ),
                            SizedBox(width: 20),
                            Expanded(
                              child: Text(
                                "Welcome to Dama Kenya",
                                style: TextStyle(
                                  color: isDarkMode ? kWhite : kBlack,
                                  fontSize: kBigTextSize,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 600),
                        child: Obx(() {
                          // Wait for membership expiration check to complete first
                          if (membershipExpired.value == null) {
                            return ListView(
                              children: List.generate(
                                3,
                                (_) => const PlanCardSkeleton(),
                              ),
                            );
                          }

                          // Then wait for plans to load and plan status to be checked
                          if (_plansController.isLoading.value ||
                              _plansController.isLoadingPlanStatus.value) {
                            return ListView(
                              children: List.generate(
                                3,
                                (_) => const PlanCardSkeleton(),
                              ),
                            );
                          }

                          if (_plansController.plansList.isEmpty) {
                            return Center(child: Text("No plans available"));
                          }

                          return ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: _plansController.plansList.length,
                            itemBuilder: (context, index) {
                              final plan = _plansController.plansList[index];
                              String buttonText = _getButtonText(
                                plan.membership,
                              );
                              bool isEnabled = _isButtonEnabled(
                                plan.membership,
                              );
                              Color buttonColor = _getButtonColor(
                                plan.membership,
                                buttonText,
                              );
                              return plansCard(
                                icon:
                                    plan.membership.toLowerCase() == "student"
                                        ? FontAwesomeIcons.graduationCap
                                        : plan.membership.toLowerCase() ==
                                            "professional"
                                        ? FontAwesomeIcons.briefcase
                                        : FontAwesomeIcons.building,
                                amount: plan.price.toString(),
                                plan: plan.membership,
                                buttonText: buttonText,
                                isEnabled: isEnabled,
                                buttonColor: buttonColor,
                                onClick:
                                    () => _showFullMessageBottomSheet(
                                      context,
                                      plan.membership,
                                      isDarkMode,
                                      plan.price,
                                      FontAwesomeIcons.graduationCap,
                                      plan.id,
                                      plan.type,
                                    ),
                              );
                            },
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_paymentController.isLoading.value)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(child: customSpinner),
              ),
          ],
        ),
      ),
    );
  }
}
