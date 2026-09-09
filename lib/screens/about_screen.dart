import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';
import '../widgets/kumi_mark.dart';
import '../widgets/web_controls.dart';

/// About the app first and the developer second. A hero mark, purpose card,
/// and a clean feature grid; the developer gets a quiet footer.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _githubUrl = 'https://github.com/groovyrey';
  static const _facebookUrl = 'https://www.facebook.com/share/1EGK4rZKfQ/';
  static const _email = 'reymartcenteno03@gmail.com';
  static const _purposeLabel = 'A quiet place to watch.';
  static const _purposeBody = 'Kumi is a no-strings streaming app built for '
      'movie nights: browse the latest films and shows, dive into a title, and '
      'start watching in seconds. No accounts, no ads, no noise.';
  static final _features = [
    (
      PhosphorIcons.filmSlate(),
      'Everything in one place',
      'Movies and series across every category, always fresh.',
    ),
    (
      PhosphorIcons.magnifyingGlass(),
      'Instant search',
      'One field finds the whole catalog in a keystroke.',
    ),
    (
      PhosphorIcons.playCircle(),
      'Cinema-grade player',
      'Native playback with a full screen and rich controls.',
    ),
    (
      PhosphorIcons.deviceMobile(),
      'Made for weekends',
      'A warm, calm design that works in light and dark.',
    ),
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
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: KumiMark(size: 88)),
          const SizedBox(height: 14),
          Center(
            child: Text(
              'Kumi',
              style: context.appTextTheme.displayMedium?.copyWith(
                color: context.appOnSurface,
                fontWeight: FontWeight.w700,
                letterSpacing: -1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'a quiet place to watch',
              style: context.appTextTheme.bodyLarge?.copyWith(
                color: context.appOnSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Center(child: _VersionPill()),
          const SizedBox(height: 30),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OUR PURPOSE',
                  style: context.appTextTheme.labelSmall?.copyWith(
                    color: context.appAccent,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _purposeLabel,
                  style: context.appTextTheme.headlineMedium?.copyWith(
                    color: context.appOnSurface,
                    height: 1.25,
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
          const SizedBox(height: 30),
          _sectionLabel(context, 'What Kumi does'),
          const SizedBox(height: 12),
          SurfaceCard(
            padding: const EdgeInsets.all(0),
            child: Column(
              children: [
                for (var i = 0; i < _features.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: AppColors.cardBorder),
                  _featureRow(context, _features[i]),
                ],
              ],
            ),
          ),
          const SizedBox(height: 34),
          SurfaceCard(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              children: [
                Text(
                  'Kumi is a hobby project — built free, open, and without '
                  'trackers. If it helps you find a movie tonight, that is '
                  'enough.',
                  textAlign: TextAlign.center,
                  style: context.appTextTheme.bodyMedium?.copyWith(
                    color: context.appOnSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                Divider(height: 1, color: AppColors.cardBorder),
                const SizedBox(height: 16),
                Text(
                  'Developed and maintained by Groovyrey',
                  style: context.appTextTheme.bodyMedium?.copyWith(
                    color: context.appOnSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    _linkChip(context, 'GitHub', PhosphorIcons.code(), _githubUrl),
                    _linkChip(
                        context, 'Facebook', PhosphorIcons.facebookLogo(), _facebookUrl),
                    _linkChip(context, 'Email', PhosphorIcons.envelope(),
                        'mailto:$_email'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _linkChip(BuildContext context, String label, IconData icon, String url) {
    return InkWell(
      onTap: () => _open(url),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: context.appAccentSoft,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: context.appAccent.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: context.appAccent),
            const SizedBox(width: 7),
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

  Widget _featureRow(BuildContext context, (IconData, String, String) feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.appAccentSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(feature.$1, size: 20, color: context.appAccent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.$2,
                  style: context.appTextTheme.titleMedium?.copyWith(
                    color: context.appOnSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  feature.$3,
                  style: context.appTextTheme.bodyMedium?.copyWith(
                    color: context.appOnSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String label) {
    return Text(
      label,
      style: context.appTextTheme.titleLarge?.copyWith(
        color: context.appOnSurface,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _VersionPill extends StatelessWidget {
  const _VersionPill();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snap) {
        final version = snap.data?.version ?? '';
        final build = snap.data?.buildNumber ?? '';
        final label = version.isEmpty ? '' : 'Version $version ($build)';
        if (label.isEmpty) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: context.appSurfaceVariant.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Text(
            label,
            style: context.appTextTheme.labelSmall?.copyWith(
              color: context.appOnSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
        );
      },
    );
  }
}