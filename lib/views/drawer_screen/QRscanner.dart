import 'package:dama/controller/verify_by_phone_controler.dart';
import 'package:dama/controller/verify_qr_code_controller.dart';
import 'package:dama/models/verify_by_phone_model.dart';
import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/widgets/buttons/custom_button.dart';
import 'package:dama/widgets/theme_aware_logo.dart';
import 'package:dama/widgets/inputs/custom_input.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

class QRScannerScreen extends StatefulWidget {
  final String eventId;

  const QRScannerScreen({super.key, required this.eventId});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String? result;
  final VerifyQrCodeController verifyController = Get.put(
    VerifyQrCodeController(),
  );

  final VerifyByPhoneController verifyByPhoneController = Get.put(
    VerifyByPhoneController(),
  );

  int selectedTab = 0;
  final TextEditingController searchController = TextEditingController();

  @override
  void reassemble() {
    super.reassemble();
    if (controller != null) {
      controller!.pauseCamera();
      controller!.resumeCamera();
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      if (result == null) {
        setState(() {
          result = scanData.code;
        });
        controller.pauseCamera();

        final statusCode = await verifyController.verifyQrCodeFromJsonString(
          scanData.code ?? '',
        );

        if (statusCode == 200) {
          _showBottomSheet("Success", "QR code verified successfully!", true);
        } else if (statusCode == 400) {
          _showBottomSheet(
            "Already Scanned",
            "This QR code has already been scanned.",
            false,
          );
        } else {
          _showSnackBar("An error occurred while verifying the QR code.");
        }

        Future.delayed(const Duration(seconds: 3), () {
          setState(() {
            result = null;
          });
          controller.resumeCamera();
        });
      }
    });
  }

  void _showBottomSheet(String title, String message, bool isSuccess) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          bottom: true,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : Icons.error,
                  color: isSuccess ? Colors.green : Colors.red,
                  size: 50,
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildPillButton(String text, int index) {
    final bool isSelected = selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? kBlue : kWhite,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: isSelected ? kBlue : kGrey),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? kWhite : kGrey,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchTab(bool isDarkMode) {
    return Container(
      color: isDarkMode ? kDarkThemeBg : kWhite,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(color: isDarkMode ? kBlack : kLightGrey, height: 2),
          ThemeAwareLogo(height: 80, width: 150),
          const SizedBox(height: 10),
          InputField(
            controller: searchController,
            hintText: "0700000000",
            label: "Search a person by phone number *",
            isRequired: true,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return "This field is required";
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: kSidePadding),
            child: Obx(() {
              if (verifyByPhoneController.isLoading.value) {
                return Container(
                  decoration: BoxDecoration(
                    color: kGrey,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Verifying ...',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: kWhite),
                    ),
                  ),
                );
              }
              return CustomButton(
                callBackFunction: () async {
                  final phone = searchController.text.trim();
                  if (phone.isEmpty) {
                    _showSnackBar("Enter phone number");
                    return;
                  }

                  final request = VerifyByPhoneModel(
                    phoneNumber: phone,
                    eventId: widget.eventId,
                  );

                  final statusCode = await verifyByPhoneController
                      .verifyByPhone(request);

                  if (statusCode == 200) {
                    _showBottomSheet(
                      "Success",
                      "Phone verified successfully!",
                      true,
                    );
                  } else if (statusCode == 400) {
                    _showBottomSheet(
                      "Already Verified",
                      "This phone is already verified.",
                      false,
                    );
                  } else {
                    _showSnackBar("Error verifying phone.");
                  }
                },
                label: "Verify",
                backgroundColor: kBlue,
              );
            }),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;

    return Scaffold(
      backgroundColor: isDarkMode ? kDarkThemeBg : kBGColor,
      appBar: AppBar(
        title: Text(
          'Verify',
          style: TextStyle(color: isDarkMode ? kWhite : kBlack),
        ),
        backgroundColor: isDarkMode ? kDarkThemeBg : kWhite,
        iconTheme: IconThemeData(color: isDarkMode ? kWhite : kBlack),
      ),
      body: Column(
        children: [
          SizedBox(height: 2),
          Container(
            color: isDarkMode ? kBlack : kWhite,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 10.0,
                horizontal: 15,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildPillButton("QR code", 0),
                  const SizedBox(width: 10),
                  _buildPillButton("Search", 1),
                ],
              ),
            ),
          ),
          Expanded(
            child:
                selectedTab == 0
                    ? Column(
                      children: [
                        Expanded(
                          flex: 5,
                          child: QRView(
                            key: qrKey,
                            onQRViewCreated: _onQRViewCreated,
                            overlay: QrScannerOverlayShape(
                              borderColor: Colors.green,
                              borderRadius: 10,
                              borderLength: 30,
                              borderWidth: 10,
                              cutOutSize: 300,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Container(
                            color: isDarkMode ? kBlack : kWhite,
                            child: Center(
                              child: Obx(() {
                                if (verifyController.isLoading.value) {
                                  return const CircularProgressIndicator();
                                }
                                if (result != null) {
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Result: $result',
                                        style: const TextStyle(fontSize: 18),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        verifyController
                                            .verificationResult
                                            .value,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color:
                                              verifyController
                                                          .verificationResult
                                                          .value ==
                                                      'Verification successful!'
                                                  ? Colors.green
                                                  : Colors.red,
                                        ),
                                      ),
                                    ],
                                  );
                                }
                                return ThemeAwareLogo(height: 80, width: 150);
                              }),
                            ),
                          ),
                        ),
                      ],
                    )
                    : _buildSearchTab(isDarkMode),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
