import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/theme_toggle.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Kumi',
                    style: context.appTextTheme.titleLarge?.copyWith(
                      letterSpacing: -0.5,
                    ),
                  ),
                  const ThemeToggle(),
                ],
              ),
              const SizedBox(height: 36),
              Text(
                "Hello, I'm Kumi.",
                style: context.appTextTheme.displayMedium?.copyWith(
                  color: context.appOnSurface,
                ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Text(
                  'A fresh Flutter starter, built and shipped by GitHub Actions.',
                  style: context.appTextTheme.bodyLarge?.copyWith(
                    color: context.appOnSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 44),
              Text(
                'Get started',
                style: context.appTextTheme.headlineMedium?.copyWith(
                  color: context.appOnSurface,
                ),
              ),
              const SizedBox(height: 18),
              const _FeatureTile(
                icon: Icons.brush_outlined,
                title: 'Design a screen',
                subtitle: 'Screens live in lib/screens and render here.',
              ),
              const _FeatureTile(
                icon: Icons.contrast_outlined,
                title: 'Tune the theme',
                subtitle: 'Palette and type live in lib/theme.',
              ),
              const _FeatureTile(
                icon: Icons.rocket_launch_outlined,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: context.appAccentSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 21, color: context.appAccent),
            ),
            const SizedBox(width: 16),
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
                  const SizedBox(height: 3),
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
