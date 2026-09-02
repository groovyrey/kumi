import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class KumiMark extends StatelessWidget {
  const KumiMark({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.gradientStart,
            AppColors.gradientMid,
            AppColors.gradientEnd,
          ],
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.35),
            blurRadius: size * 0.35,
            offset: Offset(0, size * 0.16),
          ),
        ],
      ),
child: Center(
        child: Icon(
          Icons.local_florist,
          size: size * 0.5,
          color: AppColors.gradientAccent,
        ),
      ),
    );
  }
}