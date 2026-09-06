import 'dart:math';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../models/media_item.dart';
import '../services/screen_time.dart';
import '../services/tmdb_service.dart';
import '../services/version_checker.dart';
import '../services/watch_history.dart';
import '../theme/app_theme.dart';
import '../widgets/poster_rail.dart';
import '../widgets/web_controls.dart';
import 'detail_screen.dart';
import 'player_screen.dart';

/// Netflix-style landing: a spotlight hero, continue watching, discovery
/// rails, watch history and a compact screen-time card.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WatchHistory _history = WatchHistory.instance;
  final TmdbService _tmdb = TmdbService();

  MediaItem? _featured;
  VersionInfo? _update;

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
    _loadHero();
  }

  Future<void> _checkForUpdate() async {
    final update = await VersionChecker().check();
    if (!mounted || update == null) return;
    setState(() => _update = update);
  }

  Future<void> _loadHero() async {
    try {
      var items = (await _tmdb.nowPlayingMoviesPage()).items;
      if (items.isEmpty) items = (await _tmdb.popularMoviesPage()).items;
      if (!mounted || items.isEmpty) return;
      setState(() => _featured = items[Random().nextInt(items.length)]);
    } catch (_) {
      // Quiet: the rails still work without a spotlight title.
    }
  }

  void _play(MediaItem item) {
    WatchHistory.instance.record(item);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          title: item.title,
          id: item.id,
          media: item.mediaType == 'tv' ? 'tvplay' : 'movie',
        ),
      ),
    );
  }

  void _moreInfo(MediaItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailScreen(item: item)),
    );
  }

  Future<void> _openRelease(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _timeAgo(int epochMs) {
    if (epochMs <= 0) return '';
    final diff = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(epochMs),
    );
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays} day ago';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_history, ScreenTime.instance]),
      builder: (context, _) {
        final entries = _history.entries;
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_update case final VersionInfo update)
                _UpdateBanner(update: update, onOpen: _openRelease),
              if (_featured case final MediaItem featured)
                _HeroCard(
                  item: featured,
                  onPlay: () => _play(featured),
                  onMore: () => _moreInfo(featured),
                ),
              if (entries.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
                  child: Text(
                    'CONTINUE WATCHING',
                    style: context.appTextTheme.labelSmall?.copyWith(
                      color: context.appAccent,
                    ),
                  ),
                ),
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: entries.take(10).length,
                    itemBuilder: (context, i) {
                      final e = entries.take(10).toList()[i];
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: _ContinueCard(
                          entry: e,
                          onTap: () => _play(e.item),
                        ),
                      );
                    },
                  ),
                ),
              ] else
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
                  child: SurfaceCard(
                    child: Column(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: context.appAccentSoft,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            PhosphorIcons.playCircle(),
                            size: 28,
                            color: context.appAccent,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Nothing watched yet',
                          textAlign: TextAlign.center,
                          style: context.appTextTheme.titleMedium?.copyWith(
                            color: context.appOnSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Everything you watch shows up here, ready to continue.',
                          textAlign: TextAlign.center,
                          style: context.appTextTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              _railTitle(context, 'Popular Movies'),
              PosterRail(fetch: (page) => _tmdb.popularMoviesPage(page: page)),
              _railTitle(context, 'Popular Series'),
              PosterRail(fetch: (page) => _tmdb.popularSeriesPage(page: page)),
              if (entries.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 26, 8, 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'WATCH HISTORY',
                          style: context.appTextTheme.labelSmall?.copyWith(
                            color: context.appAccent,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _history.clear(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          minimumSize: const Size(0, 36),
                        ),
                        child: Text(
                          'Clear all',
                          style: TextStyle(color: context.appAccent),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SurfaceCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (final entry in entries) ...[
                          _HistoryTile(
                            entry: entry,
                            onTap: () => _play(entry.item),
                            onRemove: () => _history.remove(entry),
                            timeAgo: _timeAgo(entry.watchedAt),
                          ),
                          Container(height: 1, color: AppColors.cardBorder),
                        ],
                        Container(height: 1, color: AppColors.cardBorder),
                        // Anchor line so last row keeps its hairline divider.
                        const SizedBox(height: 0),
                      ],
                    ),
                  ),
                ),
              ],
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
                child: _ScreenTimeCard(),
              ),
              const SizedBox(height: 28),
            ],
          ),
        );
      },
    );
  }

  Widget _railTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
      child: Text(
        title,
        style: context.appTextTheme.headlineMedium?.copyWith(
          color: context.appOnSurface,
        ),
      ),
    );
  }
}

/// Netflix-style spotlight banner: full-bleed backdrop, bottom gradient, and
/// Play / More Info actions laid over the title card.
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.item, required this.onPlay, required this.onMore});

  final MediaItem item;
  final VoidCallback onPlay;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    const height = 470.0;
    final backdrop = item.backdropPath;
    return SizedBox(
      width: double.infinity,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: context.appSurfaceVariant,
            child: backdrop == null || backdrop.isEmpty
                ? _fill(context)
                : Image.network(
                    '${AppConfig.tmdbImageBase}$backdrop',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _fill(context),
                  ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                stops: const [0.0, 0.55, 1.0],
                colors: [
                  context.appBackground,
                  context.appBackground.withValues(alpha: 0.6),
                  context.appBackground.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.mediaType == 'tv' ? 'SERIES' : 'MOVIE',
                  style: context.appTextTheme.labelSmall?.copyWith(
                    color: context.appAccent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.appTextTheme.displayMedium?.copyWith(
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(PhosphorIcons.star(), size: 17, color: context.appAccent),
                    const SizedBox(width: 4),
                    Text(
                      item.rating.toStringAsFixed(1),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (item.releaseDate.isNotEmpty) ...[
                      Text(
                        item.releaseDate.length >= 4
                            ? item.releaseDate.substring(0, 4)
                            : item.releaseDate,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  item.overview,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: onPlay,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 26, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      icon: Icon(PhosphorIcons.play(),
                          color: Colors.black, size: 26),
                      label: const Text(
                        'Play',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: onMore,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.35),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      icon: Icon(PhosphorIcons.info(),
                          color: Colors.white, size: 22),
                      label: const Text(
                        'More Info',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fill(BuildContext context) {
    return Container(
      color: context.appSurfaceVariant,
      child: Center(
        child: Icon(
          PhosphorIcons.filmSlate(),
          size: 56,
          color: context.appOnSurfaceVariant,
        ),
      ),
    );
  }
}

class _UpdateBanner extends StatelessWidget {
  const _UpdateBanner({required this.update, required this.onOpen});

  final VersionInfo update;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 2),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: context.appAccentSoft,
        borderRadius: BorderRadius.circular(AppRadius.control),
        border: Border.all(
          color: context.appAccent.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(
            PhosphorIcons.megaphone(),
            size: 20,
            color: context.appAccent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Kumi ${update.version} is out',
              style: context.appTextTheme.titleMedium?.copyWith(
                color: context.appOnSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => onOpen(update.url),
            child: Text('Update', style: TextStyle(color: context.appAccent)),
          ),
        ],
      ),
    );
  }
}

class _ScreenTimeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenTime = ScreenTime.instance;
    final week = screenTime.last7;
    final today = screenTime.todaySeconds;
    final total = week.fold<int>(0, (sum, day) => sum + day.$2);
    final average = total ~/ 7;
    final maxDay = week.fold<int>(1, (max, day) => day.$2 > max ? day.$2 : max);
    final sections = screenTime.sections.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final now = DateTime.now();

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                PhosphorIcons.timer(),
                size: 20,
                color: context.appAccent,
              ),
              const SizedBox(width: 8),
              Text(
                'Screen time',
                style: context.appTextTheme.titleMedium?.copyWith(
                  color: context.appOnSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _stat(context, 'Today', _fmt(today)),
              _stat(context, 'This week', _fmt(total)),
              _stat(context, 'Daily average', _fmt(average)),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: AppColors.cardBorder),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final (day, seconds) in week)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: _DayBar(
                      seconds: seconds,
                      max: maxDay,
                      isToday: day.year == now.year &&
                          day.month == now.month &&
                          day.day == now.day,
                      label: _weekdayLetter(day),
                    ),
                  ),
                ),
            ],
          ),
          if (sections.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 0, color: Colors.transparent),
            Container(height: 1, color: AppColors.cardBorder),
            const SizedBox(height: 14),
            Text(
              'TODAY BY SECTION',
              style: context.appTextTheme.labelSmall?.copyWith(
                color: context.appAccent,
                fontSize: 10,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in sections.take(6))
                  _SectionChip(label: entry.key, minutes: _fmt(entry.value)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _fmt(int seconds) {
    final m = seconds ~/ 60;
    if (m < 1) return '<1m';
    if (m < 60) return '${m}m';
    return '${m ~/ 60}h ${(m % 60)}m';
  }

  String _weekdayLetter(DateTime day) =>
      const ['M', 'T', 'W', 'T', 'F', 'S', 'S'][day.weekday - 1];

  Widget _stat(
    BuildContext context,
    String label,
    String value, {
    bool accentValue = false,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: context.appTextTheme.labelSmall?.copyWith(
              fontSize: 10,
              color: accentValue
                  ? context.appAccent
                  : context.appOnSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: context.appTextTheme.titleMedium?.copyWith(
              color: accentValue ? context.appAccent : context.appOnSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayBar extends StatelessWidget {
  const _DayBar({
    required this.seconds,
    required this.max,
    required this.isToday,
    required this.label,
  });

  final int seconds;
  final int max;
  final bool isToday;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ratio = max <= 0
        ? 0.04
        : (seconds / max).clamp(0.04, 1.0).toDouble();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 4 + 40 * ratio,
          decoration: BoxDecoration(
            color: isToday ? context.appAccent : context.appAccentSoft,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: context.appTextTheme.labelSmall?.copyWith(
            fontSize: 10,
            color: isToday
                ? context.appAccent
                : context.appOnSurfaceVariant,
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _SectionChip extends StatelessWidget {
  const _SectionChip({required this.label, required this.minutes});

  final String label;
  final String minutes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: context.appAccentSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label · $minutes',
        style: context.appTextTheme.labelSmall?.copyWith(
          color: context.appAccent,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.entry, required this.onTap});

  static const width = 120.0;

  final WatchEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final height = width * 1.4;
    final item = entry.item;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: context.appSurface,
                borderRadius: BorderRadius.circular(AppRadius.control),
                border: Border.all(color: AppColors.cardBorder),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (item.posterUrl.isEmpty)
                    Center(
                      child: Icon(
                        PhosphorIcons.filmSlate(),
                        size: 30,
                        color: context.appOnSurfaceVariant,
                      ),
                    )
                  else
                    Image.network(
                      item.posterUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Icon(
                          PhosphorIcons.filmSlate(),
                          size: 30,
                          color: context.appOnSurfaceVariant,
                        ),
                      ),
                    ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.mediaType == 'tv' ? 'TV' : 'MOVIE',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.8),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        PhosphorIcons.play(),
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.appTextTheme.bodyMedium?.copyWith(
                color: context.appOnSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.entry,
    required this.onTap,
    required this.onRemove,
    required this.timeAgo,
  });

  final WatchEntry entry;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final String timeAgo;

  @override
  Widget build(BuildContext context) {
    final item = entry.item;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 60,
              decoration: BoxDecoration(
                color: context.appSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.cardBorder),
              ),
              clipBehavior: Clip.antiAlias,
              child: item.posterUrl.isEmpty
                  ? Icon(
                      PhosphorIcons.filmSlate(),
                      size: 18,
                      color: context.appOnSurfaceVariant,
                    )
                  : Image.network(
                      item.posterUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        PhosphorIcons.filmSlate(),
                        size: 18,
                        color: context.appOnSurfaceVariant,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.appTextTheme.bodyLarge?.copyWith(
                      color: context.appOnSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${item.mediaType == 'tv' ? 'TV' : 'MOVIE'}'
                    '${timeAgo.isEmpty ? '' : ' · $timeAgo'}',
                    style: context.appTextTheme.bodySmall?.copyWith(
                      color: context.appOnSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Remove from history',
              onPressed: onRemove,
              icon: Icon(
                PhosphorIcons.x(),
                size: 18,
                color: context.appOnSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}