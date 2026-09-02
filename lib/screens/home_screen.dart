import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/app_theme.dart';
import '../widgets/kumi_mark.dart';
import '../widgets/theme_toggle.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      PhosphorIcon(
                        PhosphorIcons.flower(),
                        size: 22,
                        color: colors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Kumi',
                        style: context.appTextTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const ThemeToggle(),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
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
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const KumiMark(size: 64),
                    const SizedBox(height: 26),
                    Text(
                      "Hello, I'm Kumi.",
                      style: context.appTextTheme.displayMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'A fresh Flutter starter, built and shipped by GitHub Actions.',
                      style: context.appTextTheme.bodyLarge?.copyWith(
                        color: AppColors.gradientAccent,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Text(
                'Get started',
                style: context.appTextTheme.headlineMedium?.copyWith(
                  color: context.appOnSurface,
                ),
              ),
              const SizedBox(height: 16),
              _FeatureTile(
                icon: PhosphorIcons.compass(),
                title: 'Design a screen',
                subtitle: 'Your screens live in lib/screens.',
              ),
              _FeatureTile(
                icon: PhosphorIcons.paintBrush(),
                title: 'Tune the theme',
                subtitle: 'Palette and type live in lib/theme.',
              ),
              _FeatureTile(
                icon: PhosphorIcons.rocketLaunch(),
                title: 'Ship an APK',
                subtitle: 'Push a v* tag and Actions attaches the release.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colors.primaryContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: colors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.appTextTheme.titleLarge?.copyWith(
                      color: context.appOnSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: context.appTextTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}