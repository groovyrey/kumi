import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';
import '../widgets/kumi_mark.dart';

/// About the app first and the developer second. The purpose and feature list
/// take center stage; the developer gets a quiet footer.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _githubUrl = 'https://github.com/groovyrey';
  static const _email = 'reymartcenteno03@gmail.com';
  static const _purposeLabel = 'Kumi is a place to watch movies and the shows people keep talking about.';
  static const _purposeBody = 'Browse the latest films, dive into a title, and start streaming in seconds — no accounts, no noise, just the watch.';
  static const _features = [
    'Everything in one place: movies and series across every category',
    'Search that finds the whole catalog instantly',
    'An immersive full-screen player that watches like a cinema',
    'A quiet, warm design that looks right in light and dark',
  ];

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: KumiMark(size: 92)),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Kumi',
              style: context.appTextTheme.displayMedium?.copyWith(
                color: context.appOnSurface,
              ),
            ),
          ),
          Center(
            child: Text(
              'A quiet place to watch',
              style: context.appTextTheme.bodyMedium?.copyWith(
                color: context.appAccent,
              ),
            ),
          ),
          const SizedBox(height: 30),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            decoration: BoxDecoration(
              color: context.appAccentSoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: context.appAccent.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PURPOSE',
                  style: context.appTextTheme.titleMedium?.copyWith(
                    color: context.appAccent,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _purposeLabel,
                  style: context.appTextTheme.headlineMedium?.copyWith(
                    color: context.appOnSurface,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _purposeBody,
                  style: context.appTextTheme.bodyLarge?.copyWith(
                    color: context.appOnSurfaceVariant,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          _sectionLabel(context, 'What Kumi does'),
          for (final feature in _features)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Icon(
                      Symbols.check_circle_rounded,
                      size: 17,
                      color: context.appAccent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      feature,
                      style: context.appTextTheme.bodyLarge?.copyWith(
                        color: context.appOnSurface,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 30),
          Divider(height: 1, color: AppColors.cardBorder),
          const SizedBox(height: 18),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Built with care by Reymart Centeno · dev name groovyrey',
                  textAlign: TextAlign.center,
                  style: context.appTextTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _linkText(context, 'GitHub', Symbols.code_rounded, _githubUrl),
                    Container(
                      width: 1,
                      height: 14,
                      margin: const EdgeInsets.symmetric(horizontal: 13),
                      color: AppColors.cardBorder,
                    ),
                    _linkText(context, 'Email', Symbols.mail_rounded, 'mailto:$_email'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _linkText(BuildContext context, String label, IconData icon, String url) {
    return InkWell(
      onTap: () => _open(url),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: context.appAccent),
            const SizedBox(width: 4),
            Text(
              label,
              style: context.appTextTheme.bodyMedium?.copyWith(
                color: context.appAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        label,
        style: context.appTextTheme.titleLarge?.copyWith(
          color: context.appOnSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}