import 'package:dama/utils/constants.dart';
import 'package:flutter/material.dart';

class CustomButton extends StatefulWidget {
  const CustomButton({super.key, 
    required this.callBackFunction,
    required this.label,
    required this.backgroundColor,
    this.isLoading = false,
    this.textColor,
  });

  final dynamic callBackFunction;
  final String label;
  final Color backgroundColor;
  final bool isLoading;
  final Color? textColor;

  @override
  _CustomButtonState createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: widget.isLoading || widget.callBackFunction == null ? null : () {
        widget.callBackFunction();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: widget.isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(kWhite),
                ),
              )
            : Text(
                widget.label,
                style: TextStyle(color: widget.textColor ?? kWhite, fontSize: 15),
              ),
      ),
    );
  }
}
