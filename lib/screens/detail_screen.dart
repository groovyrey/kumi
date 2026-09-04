import 'package:flutter/material.dart';

import '../config.dart';
import '../models/media_item.dart';
import '../theme/app_theme.dart';
import 'player_screen.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key, required this.item});

  final MediaItem item;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late final String _mediaParam;
  late int _activeIndex;

  @override
  void initState() {
    super.initState();
    _mediaParam = widget.item.mediaType == 'tv' ? 'tvplay' : 'movie';
    _activeIndex = 0; // CineSrc is first and the default.
  }

  String _sourceUrl(int index) {
    final src = EmbedSources.sources[index];
    return src.$2(id: widget.item.id, media: _mediaParam);
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
                    height: 180,
                    width: double.infinity,
                    color: context.appSurfaceVariant,
                    child: widget.item.backdropPath == null ||
                            widget.item.backdropPath!.isEmpty
                        ? _posterOnly(context)
                        : Image.network(
                            '${AppConfig.tmdbImageBase}${widget.item.backdropPath}',
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
                        backgroundColor:
                            context.appSurface.withValues(alpha: 0.9),
                      ),
                      icon: const Icon(Icons.arrow_back),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _player(context),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.title,
                      style: context.appTextTheme.displayMedium?.copyWith(
                        color: context.appOnSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _iconLabel(context, Icons.star,
                            widget.item.rating.toStringAsFixed(1)),
                        const SizedBox(width: 14),
                        if (widget.item.releaseDate.isNotEmpty)
                          _iconLabel(context, Icons.calendar_today,
                              widget.item.releaseDate),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text(
                      widget.item.overview.isEmpty
                          ? 'No synopsis available.'
                          : widget.item.overview,
                      style: context.appTextTheme.bodyLarge?.copyWith(
                        color: context.appOnSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Inline player, ready to play immediately with the default (CineSrc) embed.
  Widget _player(BuildContext context) {
    return Container(
      height: 210,
      width: double.infinity,
      color: Colors.black,
      child: Stack(
        children: [
          Positioned.fill(child: PlayerView(url: _sourceUrl(_activeIndex))),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _sourcePicker(),
          ),
        ],
      ),
    );
  }

  Widget _sourcePicker() {
    return Container(
      color: Colors.black.withValues(alpha: 0.72),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          for (var i = 0; i < EmbedSources.sources.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: _SourceChip(
                  label: EmbedSources.sources[i].$1,
                  active: i == _activeIndex,
                  onTap: () {
                    setState(() {
                      _activeIndex = i;
                    });
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _posterOnly(BuildContext context) {
    return Center(
      child: SizedBox(
        height: 140,
        child: widget.item.posterUrl.isEmpty
            ? Icon(Icons.local_movies_outlined,
                size: 64, color: context.appOnSurfaceVariant)
            : Image.network(widget.item.posterUrl, fit: BoxFit.contain),
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

class _SourceChip extends StatelessWidget {
  const _SourceChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: context.appTextTheme.bodyMedium?.copyWith(
            color: active ? Colors.black : Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
