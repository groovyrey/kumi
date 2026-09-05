import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import '../config.dart';
import '../models/media_item.dart';
import '../services/watch_history.dart';
import '../theme/app_theme.dart';
import 'player_screen.dart';

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key, required this.item});

  final MediaItem item;

  String get _mediaParam => item.mediaType == 'tv' ? 'tvplay' : 'movie';

  /// True for movies whose release date is still in the future — nothing is
  /// playable until then, so the play and source buttons are replaced by an
  /// "in theaters" card.
  bool get _isUpcoming {
    if (item.mediaType != 'movie') return false;
    final date = DateTime.tryParse(item.releaseDate);
    if (date == null) return false;
    final now = DateTime.now();
    return date.isAfter(DateTime(now.year, now.month, now.day));
  }

  void _play(BuildContext context) {
    WatchHistory.instance.record(item);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          title: item.title,
          id: item.id,
          media: _mediaParam,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    height: 240,
                    width: double.infinity,
                    color: context.appSurfaceVariant,
                    child: item.backdropPath == null ||
                            item.backdropPath!.isEmpty
                        ? _posterOnly(context)
                        : Image.network(
                            '${AppConfig.tmdbImageBase}${item.backdropPath}',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _posterOnly(context),
                          ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            context.appSurface,
                            context.appSurface.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor:
                            context.appSurface.withValues(alpha: 0.9),
                      ),
                      icon: const Icon(Symbols.arrow_back_rounded),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 6, 22, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: context.appTextTheme.displayMedium?.copyWith(
                        color: context.appOnSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _iconLabel(context, Symbols.star_rounded,
                            item.rating.toStringAsFixed(1)),
                        const SizedBox(width: 14),
                        if (item.releaseDate.isNotEmpty)
                          _iconLabel(
                              context, Symbols.event_rounded, item.releaseDate),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (_isUpcoming)
                      _comingSoonCard(context, item.releaseDate)
                    else
                      _playButton(context),
                    const SizedBox(height: 24),
                    Text(
                      'Overview',
                      style: context.appTextTheme.headlineSmall?.copyWith(
                        color: context.appOnSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.overview.isEmpty
                          ? 'No synopsis available.'
                          : item.overview,
                      style: context.appTextTheme.bodyLarge?.copyWith(
                        color: context.appOnSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    if (item.mediaType == 'movie' && _isUpcoming) ...[
                      const SizedBox(height: 26),
                      Text(
                        'Watch on CineSrc',
                        style: context.appTextTheme.headlineSmall?.copyWith(
                          color: context.appOnSurface,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Available on CineSrc after the release date.',
                        style: context.appTextTheme.bodyMedium,
                      ),
                    ] else ...[
                      const SizedBox(height: 26),
                      Text(
                        'Watch on CineSrc',
                        style: context.appTextTheme.headlineSmall?.copyWith(
                          color: context.appOnSurface,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _SourceButton(
                        label: 'CineSrc',
                        defaultSource: true,
                        onTap: () => _play(context),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _playButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () => _play(context),
        style: FilledButton.styleFrom(
          backgroundColor: context.appAccent,
          foregroundColor: context.appOnAccent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: const Icon(Symbols.play_arrow_rounded, size: 30),
        label: Text(
          'Play Now',
          style: context.appTextTheme.titleMedium?.copyWith(
            color: context.appOnAccent,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _comingSoonCard(BuildContext context, String releaseDate) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final date = DateTime.tryParse(releaseDate);
    final label = date == null
        ? releaseDate
        : '${months[date.month - 1]} ${date.day}, ${date.year}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.appAccentSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.appAccent.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(Symbols.upcoming_rounded, size: 24, color: context.appAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'In theaters soon',
                  style: context.appTextTheme.titleMedium?.copyWith(
                    color: context.appOnSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Releases $label',
                  style: context.appTextTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _posterOnly(BuildContext context) {
    return Center(
      child: SizedBox(
        height: 180,
        child: item.posterUrl.isEmpty
            ? Icon(Symbols.local_movies_rounded,
                size: 64, color: context.appOnSurfaceVariant)
            : Image.network(item.posterUrl, fit: BoxFit.contain),
      ),
    );
  }

  Widget _iconLabel(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: context.appAccent),
        const SizedBox(width: 5),
        Text(text, style: context.appTextTheme.bodyMedium),
      ],
    );
  }
}

class _SourceButton extends StatelessWidget {
  const _SourceButton({
    required this.label,
    required this.defaultSource,
    required this.onTap,
  });

  final String label;
  final bool defaultSource;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Icon(Symbols.play_circle_rounded,
                size: 22, color: context.appAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Watch on $label${defaultSource ? '  ·  Default' : ''}',
                style: context.appTextTheme.titleLarge?.copyWith(
                  color: context.appOnSurface,
                ),
              ),
            ),
            Icon(Symbols.chevron_right_rounded,
                size: 16, color: context.appOnSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
