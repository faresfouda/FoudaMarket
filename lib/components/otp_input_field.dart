import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/appcolors.dart';

class OtpInputField extends StatefulWidget {
  final Function(String) onCompleted;
  final int length;

  const OtpInputField({
    Key? key,
    required this.onCompleted,
    this.length = 6,
  }) : super(key: key);

  @override
  State<OtpInputField> createState() => _OtpInputFieldState();
}

class _OtpInputFieldState extends State<OtpInputField> {
  late List<TextEditingController> controllers;
  late List<FocusNode> focusNodes;

  @override
  void initState() {
    super.initState();
    controllers = List.generate(widget.length, (index) => TextEditingController());
    focusNodes = List.generate(widget.length, (index) => FocusNode());
  }

  @override
  void dispose() {
    for (var controller in controllers) {
      controller.dispose();
    }
    for (var focusNode in focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _onChanged(String value, int index) {
    if (value.isNotEmpty) {
      // Move to next field
      if (index < widget.length - 1) {
        focusNodes[index + 1].requestFocus();
      } else {
        // Last field, check if all fields are filled
        _checkCompletion();
      }
    }
    _checkCompletion();
  }

  void _onBackspace(int index) {
    if (index > 0) {
      controllers[index - 1].clear();
      focusNodes[index - 1].requestFocus();
    }
  }

  void _checkCompletion() {
    String code = '';
    for (var controller in controllers) {
      code += controller.text;
    }
    if (code.length == widget.length) {
      widget.onCompleted(code);
    }
  }

  void clearAll() {
    for (var controller in controllers) {
      controller.clear();
    }
    focusNodes[0].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(widget.length, (index) {
          return SizedBox(
            width: 45,
            height: 55,
            child: TextField(
              controller: controllers[index],
              focusNode: focusNodes[index],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.blackColor,
              ),
              keyboardType: TextInputType.number,
              maxLength: 1,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: InputDecoration(
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.mediumGrayColor,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.orangeColor,
                    width: 2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.lightGrayColor,
                    width: 1.5,
                  ),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  _onChanged(value, index);
                }
              },
              onTap: () {
                // Clear the field when tapped
                controllers[index].clear();
              },
              onSubmitted: (value) {
                if (value.isEmpty && index > 0) {
                  _onBackspace(index);
                }
              },
            ),
          );
        }),
      ),
    );
  }
}
