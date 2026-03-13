import 'package:dama/controller/user_training_controller.dart';
import 'package:dama/models/training_model.dart';
import 'package:dama/services/api_service.dart';
import 'package:dama/services/unified_payment_service.dart';
import 'package:dama/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';

class TrainingDetailModal extends StatelessWidget {
  final TrainingModel training;
  final bool isDarkMode;
  final VoidCallback? onRefreshPressed;

  const TrainingDetailModal({
    super.key,
    required this.training,
    required this.isDarkMode,
    this.onRefreshPressed,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDarkMode ? kDarkCard : kWhite,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with drag handle and close button
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color:
                              isDarkMode ? Colors.grey[700] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Training Details',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? kWhite : kBlack,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: isDarkMode ? kWhite : kBlack,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        training.title,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? kWhite : kBlack,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Description
                      Text(
                        training.description,
                        style: TextStyle(
                          fontSize: 15,
                          color: isDarkMode ? kGrey : kGrey,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Info Cards
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDarkMode ? kDarkThemeBg : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                isDarkMode
                                    ? Colors.grey[800]!
                                    : Colors.grey[200]!,
                          ),
                        ),
                        child: Column(
                          children: [
                            // Instructor
                            if (training.trainer != null) ...[
                              _buildInfoRow(
                                Icons.person_outline,
                                'Instructor',
                                '${training.trainer!.firstName} ${training.trainer!.lastName}'
                                    .trim(),
                              ),
                              const Divider(height: 24),
                            ],

                            // Start Date
                            if (training.startDate != null) ...[
                              _buildInfoRow(
                                Icons.calendar_today_outlined,
                                'Start Date',
                                _formatDate(training.startDate),
                              ),
                              const Divider(height: 24),
                            ],

                            // Duration
                            if (training.learningTracks.isNotEmpty) ...[
                              _buildInfoRow(
                                Icons.schedule,
                                'Duration',
                                training.learningTracks.first.duration,
                              ),
                              const Divider(height: 24),
                            ],

                            // Price
                            if (training.learningTracks.isNotEmpty &&
                                training.learningTracks.first.price > 0) ...[
                              _buildInfoRow(
                                Icons.attach_money,
                                'Price',
                                'KES ${training.learningTracks.first.price.toStringAsFixed(0)}',
                                valueColor: kBlue,
                              ),
                            ] else ...[
                              _buildInfoRow(
                                Icons.money_off,
                                'Price',
                                'Free',
                                valueColor: Colors.green,
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Learning Outcomes
                      if (training.learningOutcomes.isNotEmpty) ...[
                        Text(
                          'Learning Outcomes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? kWhite : kBlack,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...training.learningOutcomes.map(
                          (outcome) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: kBlue.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.check,
                                    color: kBlue,
                                    size: 14,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    outcome,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDarkMode ? kWhite : kBlack,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Target Audience
                      if (training.targetAudience.isNotEmpty) ...[
                        Text(
                          'Target Audience',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? kWhite : kBlack,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              training.targetAudience
                                  .map(
                                    (audience) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: kBlue.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        audience,
                                        style: TextStyle(
                                          color: kBlue,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Bottom padding for button
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),

              // Bottom action button - fixed at bottom
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode ? kDarkCard : kWhite,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => _enrollInTraining(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        training.learningTracks.isNotEmpty &&
                                training.learningTracks.first.price > 0
                            ? 'Enroll Now - KES ${training.learningTracks.first.price.toStringAsFixed(0)}'
                            : 'Enroll Now - Free',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: kBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: kBlue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: kGrey)),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? (isDarkMode ? kWhite : kBlack),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'TBD';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _enrollInTraining(BuildContext context) {
    final isFree =
        training.learningTracks.isEmpty ||
        training.learningTracks.first.price <= 0;

    if (isFree) {
      _showFreeEnrollmentDialog(context);
    } else {
      _showPaymentModal(context);
    }
  }

  void _showFreeEnrollmentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.school, color: kBlue),
                const SizedBox(width: 8),
                const Text('Enroll in Training'),
              ],
            ),
            content: Text(
              'Are you sure you want to enroll in "${training.title}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _processFreeEnrollment(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: kBlue),
                child: const Text('Enroll'),
              ),
            ],
          ),
    );
  }

  Future<void> _processFreeEnrollment(BuildContext context) async {
    final apiService = ApiService();
    final userTrainingController = Get.find<UserTrainingController>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await apiService.enrollInTraining(training.id);
      Navigator.pop(context); // Close loading

      if (result['success'] == true) {
        await userTrainingController.fetchUserTrainings();

        if (onRefreshPressed != null) {
          onRefreshPressed!();
        }

        // Show success dialog with navigation guidance
        _showSuccessDialog(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'Failed to enroll. Please try again.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            contentPadding: const EdgeInsets.all(24),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Enrollment Successful!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  'You have successfully enrolled in "${training.title}". Go to My Trainings to start learning!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.pop(context); // Close training detail modal
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Stay Here'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.pop(context); // Close training detail modal
                          // Navigate to My Trainings
                          Get.toNamed('/my-trainings');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Go to My Trainings'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  void _showPaymentModal(BuildContext context) {
    final price = training.learningTracks.first.price;
    final trainingId = training.id;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => _PaymentBottomSheet(
            trainingName: training.title,
            amount: price,
            trainingId: trainingId,
            isDarkMode: isDarkMode,
            onPaymentComplete: () {
              Navigator.pop(ctx); // Close payment modal
              _showPaymentSuccessDialog(context);
            },
          ),
    );
  }

  void _showPaymentSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            contentPadding: const EdgeInsets.all(24),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Payment Successful!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your payment has been processed. You can now access "${training.title}" in My Trainings.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.pop(context); // Close training detail modal
                          if (onRefreshPressed != null) {
                            onRefreshPressed!();
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Stay Here'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.pop(context); // Close training detail modal
                          if (onRefreshPressed != null) {
                            onRefreshPressed!();
                          }
                          Get.toNamed('/my-trainings');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Go to My Trainings'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }
}

class _PaymentBottomSheet extends StatefulWidget {
  final String trainingName;
  final int amount;
  final String trainingId;
  final bool isDarkMode;
  final VoidCallback? onPaymentComplete;

  const _PaymentBottomSheet({
    required this.trainingName,
    required this.amount,
    required this.trainingId,
    required this.isDarkMode,
    this.onPaymentComplete,
  });

  @override
  State<_PaymentBottomSheet> createState() => _PaymentBottomSheetState();
}

class _PaymentBottomSheetState extends State<_PaymentBottomSheet> {
  String? completePhoneNumber;
  String? countryCode = '+254';
  bool _isPaymentProcessing = false;
  final bool isIOS = UnifiedPaymentService.isIOS;

  Future<void> _processPayment() async {
    // Phone validation only required for M-Pesa (Android)
    if (!isIOS &&
        (completePhoneNumber == null || completePhoneNumber!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a phone number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isPaymentProcessing = true);

    try {
      final result = await UnifiedPaymentService.pay(
        objectId: widget.trainingId,
        model: 'Training',
        amount: widget.amount,
        itemName: widget.trainingName,
        phoneNumber: isIOS ? null : completePhoneNumber,
      );

      if (result.success && widget.onPaymentComplete != null) {
        widget.onPaymentComplete!();
      }
    } finally {
      if (mounted) {
        setState(() => _isPaymentProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.isDarkMode ? kDarkCard : kWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: widget.isDarkMode ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Purchase Training',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: widget.isDarkMode ? kWhite : kBlack,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: widget.isDarkMode ? kWhite : kBlack,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Training name
                  Text(
                    widget.trainingName,
                    style: TextStyle(
                      fontSize: 15,
                      color: widget.isDarkMode ? kWhite : kGrey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Amount: KES ${widget.amount}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kBlue,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Payment method logo
                  Center(
                    child:
                        isIOS
                            ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.apple,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Pay',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : Image.asset("images/mpesa.png", height: 50),
                  ),
                  const SizedBox(height: 20),

                  // Phone number field - only for M-Pesa (Android)
                  if (!isIOS) ...[
                    Text(
                      "Phone Number *",
                      style: TextStyle(
                        color: widget.isDarkMode ? kWhite : kBlack,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    IntlPhoneField(
                      decoration: InputDecoration(
                        hintText: "7*******",
                        hintStyle: TextStyle(
                          color:
                              widget.isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.grey[700],
                        ),
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: const BorderSide(
                            color: kBlue,
                            width: 1.0,
                          ),
                        ),
                      ),
                      disableLengthCheck: true,
                      validator: (PhoneNumber? phone) {
                        if (phone == null || phone.number.isEmpty) {
                          return 'Please enter a phone number';
                        }
                        if (phone.number.length != 9) {
                          return 'Phone number must be exactly 9 digits';
                        }
                        if (!RegExp(r'^[0-9]+$').hasMatch(phone.number)) {
                          return 'Phone number must contain only digits';
                        }
                        return null;
                      },
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

                  const SizedBox(height: 16),

                  // Secure payment note
                  Row(
                    children: [
                      Icon(Icons.lock, color: kGrey, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Payments are secure & encrypted',
                        style: TextStyle(color: kGrey, fontSize: 12),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Price breakdown
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: widget.isDarkMode ? kDarkThemeBg : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            widget.isDarkMode
                                ? Colors.grey[800]!
                                : Colors.grey[200]!,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Summary',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: widget.isDarkMode ? kWhite : kBlack,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Training Fee',
                              style: TextStyle(
                                color:
                                    widget.isDarkMode
                                        ? kGrey
                                        : Colors.grey[700],
                              ),
                            ),
                            Text(
                              'KES ${widget.amount}',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: widget.isDarkMode ? kWhite : kBlack,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Divider(),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: widget.isDarkMode ? kWhite : kBlack,
                              ),
                            ),
                            Text(
                              'KES ${widget.amount}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: kBlue,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Bottom padding
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // Pay button - fixed at bottom
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: widget.isDarkMode ? kDarkCard : kWhite,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isPaymentProcessing ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isIOS ? Colors.black : kBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: Colors.grey,
                  ),
                  child:
                      _isPaymentProcessing
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (isIOS) ...[
                                const Icon(Icons.apple, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Pay KES ${widget.amount}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ] else
                                Text(
                                  'Pay KES ${widget.amount}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
