import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../models/media_item.dart';
import '../theme/app_theme.dart';

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key, required this.item});

  final MediaItem item;

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
                    height: 220,
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
                    top: 8,
                    left: 8,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: context.appSurface.withValues(alpha: 0.9),
                      ),
                      icon: const Icon(Icons.arrow_back),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: context.appTextTheme.displayMedium?.copyWith(
                        color: context.appOnSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _iconLabel(context, Icons.star,
                            item.rating.toStringAsFixed(1)),
                        const SizedBox(width: 14),
                        if (item.releaseDate.isNotEmpty)
                          _iconLabel(
                              context, Icons.calendar_today, item.releaseDate),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text(
                      item.overview.isEmpty ? 'No synopsis available.' : item.overview,
                      style: context.appTextTheme.bodyLarge?.copyWith(
                        color: context.appOnSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Watch',
                      style: context.appTextTheme.headlineMedium?.copyWith(
                        color: context.appOnSurface,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ...EmbedSources.sources.map((src) {
                      final name = src.$1;
                      final url = src.$2(
                        id: item.id,
                        media: item.mediaType == 'tv' ? 'tvplay' : 'movie',
                      );
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _PlayerButton(
                          label: name,
                          url: url,
                          title: item.title,
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _posterOnly(BuildContext context) {
    return Center(
      child: SizedBox(
        height: 160,
        child: item.posterUrl.isEmpty
            ? Icon(Icons.local_movies_outlined,
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

class _PlayerButton extends StatelessWidget {
  const _PlayerButton({
    required this.label,
    required this.url,
    required this.title,
  });

  final String label;
  final String url;
  final String title;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      ),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Icon(Icons.play_circle_outline,
                size: 22, color: context.appAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Watch on $label',
                style: context.appTextTheme.titleLarge?.copyWith(
                  color: context.appOnSurface,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 16, color: context.appOnSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
