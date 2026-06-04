import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class AppLogoHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String brandName;

  const AppLogoHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.brandName = 'Bệnh viện LPHV',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 104,
          height: 104,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Image.asset(
              'assets/images/logo_mark.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          brandName,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.hint,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
