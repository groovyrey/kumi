import 'package:flutter/material.dart';

import '../services/tmdb_service.dart';
import '../theme/app_theme.dart';
import '../widgets/lazy_media_grid.dart';
import '../widgets/poster_rail.dart';

class _Section {
  const _Section(this.title, this.fetch);

  final String title;
  final Future<MediaPage> Function(int page) fetch;
}

/// Shows movies and series across every TMDB category as lazily-paginated
/// poster rails. Each rail pages in incrementally as it is scrolled; the
/// vertical shell builds only the sections on screen.
class BrowseScreen extends StatelessWidget {
  BrowseScreen({super.key});

  final _tmdb = TmdbService();

  late final List<_Section> _sections = [
    _Section(
      'Now Playing',
      (page) => _tmdb.nowPlayingMoviesPage(page: page),
    ),
    _Section(
      'Popular Movies',
      (page) => _tmdb.popularMoviesPage(page: page),
    ),
    _Section(
      'Top Rated',
      (page) => _tmdb.topRatedMoviesPage(page: page),
    ),
    _Section(
      'Upcoming',
      (page) => _tmdb.upcomingMoviesPage(page: page),
    ),
    _Section(
      'Popular Series',
      (page) => _tmdb.popularSeriesPage(page: page),
    ),
    _Section(
      'On The Air',
      (page) => _tmdb.onTheAirSeriesPage(page: page),
    ),
  ];

  void _seeAll(BuildContext context, _Section section) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _CategoryScreen(section: section)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 2),
            child: Text(
              'Browse',
              style: context.appTextTheme.titleLarge?.copyWith(
                letterSpacing: -0.5,
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 14),
            child: Text(
              'Every category, nothing hidden.',
              style: context.appTextTheme.bodyMedium,
            ),
          ),
        ),
        for (final section in _sections) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      section.title,
                      style: context.appTextTheme.headlineMedium?.copyWith(
                        color: context.appOnSurface,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => _seeAll(context, section),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      child: Row(
                        children: [
                          Text(
                            'See all',
                            style: context.appTextTheme.bodyMedium,
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 12,
                            color: context.appOnSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(height: 250, child: PosterRail(fetch: section.fetch)),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    );
  }
}

/// Full lazy grid for a single category, reachable from a Browse "See all".
class _CategoryScreen extends StatelessWidget {
  const _CategoryScreen({required this.section});

  final _Section section;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 20, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      section.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.appTextTheme.titleMedium?.copyWith(
                        color: context.appOnSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 16, color: AppColors.cardBorder),
            Expanded(
              child: LazyMediaGrid(fetch: section.fetch),
            ),
          ],
        ),
      ),
    );
  }
}