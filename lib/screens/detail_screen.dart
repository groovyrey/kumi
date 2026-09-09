import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../config.dart';
import '../models/media_item.dart';
import '../models/series_details.dart';
import '../models/tv_season.dart';
import '../services/favorites.dart';
import '../services/tmdb_service.dart';
import '../services/watch_history.dart';
import '../theme/app_theme.dart';
import '../widgets/web_controls.dart';
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
  List<TvSeason>? _seasons;
  EpisodeAir? _nextEpisode;
  int _season = 1;
  int _episode = 1;

  MediaItem get item => widget.item;

  String get _mediaParam => item.mediaType == 'tv' ? 'tvplay' : 'movie';

  bool get _isTv => item.mediaType == 'tv';

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
    if (_isTv) _loadSeasons();
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

  Future<void> _loadSeasons() async {
    List<TvSeason> seasons;
    EpisodeAir? upcoming;
    try {
      final results = await Future.wait([
        _tmdb.tvSeasons(item.id),
        _tmdb.seriesDetails(item.id),
      ]);
      seasons = results[0] as List<TvSeason>;
      final details = results[1] as SeriesDetails?;
      final next = details?.nextEpisodeToAir;
      final today = DateTime.now();
      upcoming =
          (next != null &&
                  next.season != null &&
                  next.episode != null &&
                  next.airDate.isNotEmpty &&
                  DateTime.tryParse(next.airDate) != null &&
                  !DateTime.parse(next.airDate).isBefore(
                      DateTime(today.year, today.month, today.day)))
              ? next
              : null;
    } catch (_) {
      seasons = const [];
    }
    if (!mounted) return;
    setState(() {
      _seasons = seasons;
      _nextEpisode = upcoming;
      if (seasons.isNotEmpty) {
        _season = seasons.first.number;
        _episode = _firstEpisodeOf(seasons.first.number);
      }
    });
  }

  int _firstEpisodeOf(int season) {
    for (final s in _seasons ?? const <TvSeason>[]) {
      if (s.number == season && s.episodes.isNotEmpty) {
        return s.episodes.first.number;
      }
    }
    return 1;
  }

  void _play(
    BuildContext context, {
    String? provider,
    bool forceEmbed = false,
    int? season,
    int? episode,
  }) {
    WatchHistory.instance.record(item, season: season, episode: episode);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          title: item.title,
          id: item.id,
          media: _mediaParam,
          season: season ?? _season,
          episode: episode ?? _episode,
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
                    if (_isTv) ...[
                      const SizedBox(height: 28),
                      _seasonsSection(context),
                    ],
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
    final label = _seasons == null || _seasons!.isEmpty
        ? 'Play Now'
        : 'Play S$_season · E$_episode';
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
          label,
          style: context.appTextTheme.titleMedium?.copyWith(
            color: context.appOnAccent,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _seasonsSection(BuildContext context) {
    if (_seasons == null && _nextEpisode == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    final seasons = _seasons ?? const <TvSeason>[];
    final episodes = _episodesOf(_season);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Seasons & episodes',
          style: context.appTextTheme.headlineSmall?.copyWith(
            color: context.appOnSurface,
          ),
        ),
        const SizedBox(height: 8),
        if (seasons.isEmpty && _nextEpisode == null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              'Episodes are not available yet.',
              style: context.appTextTheme.bodyMedium,
            ),
          )
        else
          SurfaceCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_nextEpisode != null)
                  _upcomingEpisode(context, _nextEpisode!),
                if (seasons.length > 1) ...[
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                    child: Row(
                      children: [
                        for (final season in seasons) ...[
                          _SeasonChip(
                            label: season.name == 'Season ${season.number}'
                                ? 'S${season.number}'
                                : season.name,
                            selected: season.number == _season,
                            onTap: () => setState(() {
                              _season = season.number;
                              _episode = _firstEpisodeOf(season.number);
                            }),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                  Divider(height: 1, color: AppColors.cardBorder),
                ],
                if (episodes.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No episodes listed for this season yet.',
                      style: context.appTextTheme.bodyMedium,
                    ),
                  )
                else
                  for (final episode in episodes)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _EpisodeTile(
                          season: _season,
                          episode: episode,
                          onTap: () => _play(context,
                              season: _season, episode: episode.number),
                        ),
                        if (episode != episodes.last)
                          Divider(height: 1, color: AppColors.cardBorder),
                      ],
                    ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _upcomingEpisode(BuildContext context, EpisodeAir next) {
    final season = next.season ?? 1;
    final episode = next.episode ?? 1;
    final airDate = next.airDate;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: context.appAccentSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.appAccent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: context.appAccent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'UPCOMING',
              style: context.appTextTheme.labelSmall?.copyWith(
                color: context.appOnAccent,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'S$season · E$episode  '
                  '${next.name.isEmpty ? '' : '· ${next.name}'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.appTextTheme.bodyMedium?.copyWith(
                    color: context.appOnSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Airs $_airDate',
                  style: context.appTextTheme.bodySmall?.copyWith(
                    color: context.appOnSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<TvEpisode> _episodesOf(int season) {
    for (final s in _seasons ?? const <TvSeason>[]) {
      if (s.number == season) return s.episodes;
    }
    return const [];
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

/// A tappable season pill in the seasons & episodes card.
class _SeasonChip extends StatelessWidget {
  const _SeasonChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected
                ? context.appAccent
                : context.appAccentSoft.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(8),
            border: selected
                ? null
                : Border.all(color: AppColors.cardBorder),
          ),
          child: Text(
            label,
            style: context.appTextTheme.labelSmall?.copyWith(
              color: selected ? context.appOnAccent : context.appOnSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

/// A single episode row. Tapping it starts playback of that episode right
/// away; the trailing play icon signals it is watchable now.
class _EpisodeTile extends StatelessWidget {
  const _EpisodeTile({
    required this.season,
    required this.episode,
    required this.onTap,
  });

  final int season;
  final TvEpisode episode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: context.appAccentSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                'E${episode.number}',
                style: context.appTextTheme.labelSmall?.copyWith(
                  color: context.appAccent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    episode.name.isEmpty
                        ? 'Episode ${episode.number}'
                        : episode.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.appTextTheme.bodyMedium?.copyWith(
                      color: context.appOnSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _metadataLine(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.appTextTheme.bodySmall?.copyWith(
                      color: context.appOnSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(PhosphorIcons.play(), size: 18, color: context.appAccent),
          ],
        ),
      ),
    );
  }

  String _metadataLine() {
    final parts = <String>[
      if (episode.airDate.isNotEmpty) episode.airDate,
      if (episode.rating > 0) '${episode.rating.toStringAsFixed(1)} rating',
    ];
    return parts.isEmpty ? 'Season $season' : parts.join(' · ');
  }
}