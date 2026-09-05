import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import '../models/media_item.dart';
import '../models/series_details.dart';
import '../services/tmdb_service.dart';
import '../theme/app_theme.dart';
import 'detail_screen.dart';

/// Upcoming release dates in one place: scheduled movie release dates from
/// the TMDB upcoming list and the next scheduled episode of on-air series
/// (via `next_episode_to_air`). TMDB reports the broadcast schedule — it does
/// not predict dates that networks have not announced yet.
///
/// Sections reveal 5 items at a time: a Load more button appends the next 5,
/// fetching the next page only when the loaded buffer runs out.
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleRow {
  const _ScheduleRow({
    required this.item,
    required this.date,
    required this.label,
    required this.extra,
  });

  final MediaItem item;
  final String date;
  final String label;
  final String extra;
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  static const _pageStep = 5;
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  final _tmdb = TmdbService();

  final List<MediaItem> _movies = [];
  int _showingMovies = _pageStep;
  int _moviePage = 0;
  bool _movieHasMore = true;
  bool _loadingMovies = false;
  bool _movieFailed = false;

  final List<_ScheduleRow> _episodes = [];
  int _showingEpisodes = _pageStep;
  bool _loadingEpisodes = true;
  bool _episodesFailed = false;

  @override
  void initState() {
    super.initState();
    _loadMoreMovies();
    _loadEpisodes();
  }

  String _todayIso() {
    final now = DateTime.now();
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    return '${now.year}-$mm-$dd';
  }

  Future<void> _loadMoreMovies() async {
    if (_loadingMovies || !_movieHasMore) return;
    setState(() {
      _loadingMovies = true;
      _movieFailed = false;
    });
    try {
      final result = await _tmdb.upcomingMoviesPage(page: _moviePage + 1);
      if (!mounted) return;
      final today = _todayIso();
      setState(() {
        _moviePage = result.page;
        _movieHasMore = result.hasMore;
        _movies.addAll(
          result.items.where((m) => m.releaseDate.compareTo(today) >= 0),
        );
        _loadingMovies = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingMovies = false;
        _movieFailed = true;
      });
    }
  }

  Future<void> _loadMoreMoviesPressed() async {
    setState(() => _showingMovies += _pageStep);
    if (_movies.length < _showingMovies && _movieHasMore) {
      await _loadMoreMovies();
    }
  }

  Future<void> _loadEpisodes() async {
    setState(() {
      _loadingEpisodes = true;
      _episodesFailed = false;
    });
    try {
      final page = await _tmdb.onTheAirSeriesPage(page: 1);
      if (!mounted) return;
      final today = _todayIso();
      final rows = <_ScheduleRow>[];
      for (final show in page.items.take(12)) {
        final SeriesDetails? details = await _tmdb.seriesDetails(show.id);
        final next = details?.nextEpisodeToAir;
        if (next == null || next.airDate.compareTo(today) < 0) continue;
        rows.add(
          _ScheduleRow(
            item: show,
            date: next.airDate,
            label: switch ((next.season, next.episode)) {
              (final int s, final int e) => 'Season $s · Episode $e',
              _ => 'Next episode',
            },
            extra: next.name,
          ),
        );
      }
      rows.sort((a, b) => a.date.compareTo(b.date));
      if (!mounted) return;
      setState(() {
        _episodes
          ..clear()
          ..addAll(rows);
        _loadingEpisodes = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingEpisodes = false;
        _episodesFailed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final shownMovies = _movies.take(_showingMovies).toList();
    final shownEpisodes = _episodes.take(_showingEpisodes).toList();
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
        children: [
          Text(
            'Schedule',
            style: context.appTextTheme.titleLarge?.copyWith(
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          _sectionLabel(context, 'Upcoming movie releases'),
          if (shownMovies.isEmpty && !_loadingMovies && !_movieFailed)
            _emptyMessage(context, 'No upcoming releases found.')
          else
            for (var i = 0; i < shownMovies.length; i++) ...[
              _rowTile(
                context,
                _ScheduleRow(
                  item: shownMovies[i],
                  date: shownMovies[i].releaseDate,
                  label: 'Movie',
                  extra: '',
                ),
              ),
              if (i < shownMovies.length - 1)
                Divider(height: 1, color: AppColors.cardBorder),
            ],
          _movieFooter(context),
          const SizedBox(height: 26),
          _sectionLabel(context, 'Next series episodes'),
          if (_loadingEpisodes)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 22),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (_episodesFailed)
            Center(
              child: TextButton(
                onPressed: _loadEpisodes,
                child: Text('Could not load next episodes · Tap to retry'),
              ),
            )
          else if (shownEpisodes.isEmpty)
            _emptyMessage(context, 'No episodes scheduled yet.')
          else ...[
            for (var i = 0; i < shownEpisodes.length; i++) ...[
              _rowTile(context, shownEpisodes[i]),
              if (i < shownEpisodes.length - 1)
                Divider(height: 1, color: AppColors.cardBorder),
            ],
            if (_episodes.length > _showingEpisodes)
              _loadButton(
                context,
                label: 'Load more episodes',
                onPressed: () =>
                    setState(() => _showingEpisodes += _pageStep),
              ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _movieFooter(BuildContext context) {
    if (_loadingMovies) {
      return _loadButton(context, label: 'Load more', onPressed: null);
    }
    if (_movieFailed) {
      return Center(
        child: TextButton(
          onPressed: _loadMoreMovies,
          child: Text('Could not load releases · Tap to retry'),
        ),
      );
    }
    if (_movies.isNotEmpty &&
        !_movieHasMore &&
        _showingMovies >= _movies.length) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Center(
          child: Text(
            'All upcoming releases shown.',
            style: context.appTextTheme.bodySmall,
          ),
        ),
      );
    }
    if (_movies.isEmpty || !(_movies.length > _showingMovies || _movieHasMore)) {
      return const SizedBox(height: 4);
    }
    return _loadButton(
      context,
      label: 'Load more movies',
      onPressed: _loadMoreMoviesPressed,
    );
  }

  Widget _loadButton(
    BuildContext context, {
    required String label,
    required VoidCallback? onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SizedBox(
        width: double.infinity,
        height: 44,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadius.control),
          child: Container(
            decoration: BoxDecoration(
              color: context.appAccentSoft,
              borderRadius: BorderRadius.circular(AppRadius.control),
              border: Border.all(
                color: context.appAccent.withValues(alpha: 0.4),
              ),
            ),
            child: Center(
              child: onPressed == null
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Symbols.add_rounded,
                          size: 18,
                          color: context.appAccent,
                        ),
                        const SizedBox(width: 6),
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
          ),
        ),
      ),
    );
  }

  Widget _rowTile(BuildContext context, _ScheduleRow row) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailScreen(item: row.item)),
      ),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 69,
              decoration: BoxDecoration(
                color: context.appSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.cardBorder),
              ),
              clipBehavior: Clip.antiAlias,
              child: row.item.posterUrl.isEmpty
                  ? Icon(
                      Symbols.local_movies_rounded,
                      size: 18,
                      color: context.appOnSurfaceVariant,
                    )
                  : Image.network(
                      row.item.posterUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Symbols.local_movies_rounded,
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
                    row.item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.appTextTheme.bodyLarge?.copyWith(
                      color: context.appOnSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    row.label,
                    style: context.appTextTheme.bodySmall?.copyWith(
                      color: context.appOnSurfaceVariant,
                    ),
                  ),
                  if (row.extra.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(
                      row.extra,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.appTextTheme.bodySmall?.copyWith(
                        color: context.appOnSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: context.appAccentSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _whenLabel(row.date),
                style: context.appTextTheme.bodySmall?.copyWith(
                  color: context.appAccent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label.toUpperCase(),
        style: context.appTextTheme.labelSmall?.copyWith(
          color: context.appAccent,
        ),
      ),
    );
  }

  Widget _emptyMessage(BuildContext context, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: Text(message, style: context.appTextTheme.bodyMedium),
      ),
    );
  }

  String _whenLabel(String iso) {
    final parts = iso.split('-');
    if (parts.length != 3) return iso;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return iso;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(year, month, day);
    final days = date.difference(today).inDays;
    if (days == 0) return 'Today';
    if (days == 1) return 'Tomorrow';
    if (days >= 2 && days <= 6) return _weekdays[date.weekday - 1];
    return '${_months[month - 1]} $day';
  }
}