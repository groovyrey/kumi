import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../config.dart';
import '../models/media_item.dart';
import '../services/favorites.dart';
import '../services/tmdb_service.dart';
import '../services/watch_history.dart';
import '../theme/app_theme.dart';
import 'player_screen.dart';

/// Title page: a hero banner that plays the trailer in a muted loop when one
/// exists (falling back to the backdrop image), then rating, the play button
/// and the watch sources.
class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key, required this.item});

  final MediaItem item;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final TmdbService _tmdb = TmdbService();

  String? _trailerKey;

  MediaItem get item => widget.item;

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

  @override
  void initState() {
    super.initState();
    _loadTrailer();
  }

  Future<void> _loadTrailer() async {
    String? key;
    try {
      key = await _tmdb.trailerKey(item.id, item.mediaType);
    } catch (_) {
      key = null;
    }
    if (!mounted) return;
    setState(() => _trailerKey = key);
  }

  void _play(BuildContext context, {String? provider, bool forceEmbed = false}) {
    WatchHistory.instance.record(item);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          title: item.title,
          id: item.id,
          media: _mediaParam,
          preferredProvider: provider,
          forceEmbed: forceEmbed,
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
                    child: _trailerKey != null
                        ? _TrailerBackground(videoKey: _trailerKey!)
                        : _backdrop(context),
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
                      icon: Icon(PhosphorIcons.arrowLeft()),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: ListenableBuilder(
                      listenable: Favorites.instance,
                      builder: (context, _) {
                        final saved = Favorites.instance.contains(item);
                        return IconButton(
                          tooltip: saved ? 'Remove from My List' : 'Add to My List',
                          onPressed: () => Favorites.instance.toggle(item),
                          style: IconButton.styleFrom(
                            backgroundColor: saved
                                ? context.appAccent.withValues(alpha: 0.92)
                                : context.appSurface.withValues(alpha: 0.9),
                            foregroundColor: saved
                                ? context.appOnAccent
                                : context.appOnSurface,
                          ),
                          icon: Icon(
                            saved
                                ? PhosphorIcons.heart(PhosphorIconsStyle.fill)
                                : PhosphorIcons.heart(),
                          ),
                        );
                      },
                    ),
                  ),
                  if (_trailerKey != null)
                    Positioned(
                      right: 12,
                      bottom: 18,
                      child: _TrailerChip(videoKey: _trailerKey!),
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
                        _iconLabel(context, PhosphorIcons.star(),
                            item.rating.toStringAsFixed(1)),
                        const SizedBox(width: 14),
                        if (item.releaseDate.isNotEmpty)
                          _iconLabel(
                              context, PhosphorIcons.calendar(), item.releaseDate),
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
                        'Play sources',
                        style: context.appTextTheme.headlineSmall?.copyWith(
                          color: context.appOnSurface,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _SourceButton(
                        label: 'CineSrc',
                        hint: 'Embed source',
                        onTap: () => _play(context, forceEmbed: true),
                      ),
                      const SizedBox(height: 10),
                      for (final provider in NativeSources.providers)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _SourceButton(
                            label: provider.label,
                            hint: 'Kumi player',
                            onTap: () =>
                                _play(context, provider: provider.name),
                          ),
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

  Widget _backdrop(BuildContext context) {
    if (item.backdropPath == null || item.backdropPath!.isEmpty) {
      return _posterOnly(context);
    }
    return Image.network(
      '${AppConfig.tmdbImageBase}${item.backdropPath}',
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _posterOnly(context),
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
        icon: Icon(PhosphorIcons.play(), size: 30),
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
          Icon(PhosphorIcons.calendarPlus(), size: 24, color: context.appAccent),
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
            ? Icon(PhosphorIcons.filmSlate(),
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

/// Muted, looping YouTube trailer rendered behind the title hero.
class _TrailerBackground extends StatefulWidget {
  const _TrailerBackground({required this.videoKey});

  final String videoKey;

  @override
  State<_TrailerBackground> createState() => _TrailerBackgroundState();
}

class _TrailerBackgroundState extends State<_TrailerBackground> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }
    final controller = WebViewController.fromPlatformCreationParams(params);
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) =>
              request.url == _embedUrl() ? NavigationDecision.navigate : NavigationDecision.prevent,
        ),
      );
    if (controller.platform is AndroidWebViewController) {
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }
    controller.loadRequest(Uri.parse(_embedUrl()));
    _controller = controller;
  }

  String _embedUrl() {
    final key = widget.videoKey;
    return 'https://www.youtube-nocookie.com/embed/$key'
        '?autoplay=1&mute=1&loop=1&playlist=$key'
        '&controls=0&modestbranding=1&playsinline=1'
        '&rel=0&iv_load_policy=3';
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}

/// Small pill that opens the trailer on YouTube at full volume.
class _TrailerChip extends StatelessWidget {
  const _TrailerChip({required this.videoKey});

  final String videoKey;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        final uri = Uri.parse('https://www.youtube.com/watch?v=$videoKey');
        launchUrl(uri, mode: LaunchMode.externalApplication);
      },
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: context.appSurface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(PhosphorIcons.playCircle(), size: 16, color: context.appAccent),
            const SizedBox(width: 6),
            Text(
              'Trailer',
              style: context.appTextTheme.labelMedium?.copyWith(
                color: context.appOnSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceButton extends StatelessWidget {
  const _SourceButton({
    required this.label,
    required this.onTap,
    this.hint,
  });

  final String label;
  final String? hint;
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
            Icon(PhosphorIcons.playCircle(),
                size: 22, color: context.appAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Watch on $label',
                    style: context.appTextTheme.titleLarge?.copyWith(
                      color: context.appOnSurface,
                    ),
                  ),
                  if (hint != null)
                    Text(
                      hint!,
                      style: context.appTextTheme.bodySmall?.copyWith(
                        color: context.appOnSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            Icon(PhosphorIcons.caretRight(),
                size: 16, color: context.appAccent),
          ],
        ),
      ),
    );
  }
}