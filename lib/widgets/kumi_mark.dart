import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class KumiMark extends StatelessWidget {
  const KumiMark({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(size * 0.16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Center(
        child: Text(
          'K',
          style: context.appTextTheme.displayMedium?.copyWith(
            color: context.appAccent,
            fontSize: size * 0.52,
          ),
        ),
      ),
    );
  }
}
