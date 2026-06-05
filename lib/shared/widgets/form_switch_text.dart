import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class FormSwitchText extends StatelessWidget {
  final String normalText;
  final String actionText;
  final VoidCallback onTap;

  FormSwitchText({
    super.key,
    required this.normalText,
    required this.actionText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        Text(normalText, style: TextStyle(color: AppColors.hint)),
        GestureDetector(
          onTap: onTap,
          child: Text(
            actionText,
            style: TextStyle(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
