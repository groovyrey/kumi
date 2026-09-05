import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import '../services/tmdb_service.dart';
import '../theme/app_theme.dart';
import '../widgets/lazy_media_grid.dart';
import '../widgets/poster_rail.dart';
import '../widgets/web_controls.dart';

class _Section {
  const _Section(this.title, this.fetch);

  final String title;
  final Future<MediaPage> Function(int page) fetch;
}

/// Movies and series across every TMDB category, plus an in-page live search.
///
/// The search field sits at the top; a non-empty query swaps the category
/// rails for a lazy results grid (debounced), and clearing it restores them.
/// Each rail pages in incrementally as it is scrolled; the vertical shell
/// builds only the sections on screen.
class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  final _tmdb = TmdbService();
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';

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

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted && query != _query) {
        setState(() => _query = query);
      }
    });
  }

  void _submit(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query != _query) setState(() => _query = query);
  }

  void _clearSearch() {
    _debounce?.cancel();
    _controller.clear();
    if (_query.isNotEmpty) setState(() => _query = '');
  }

  void _seeAll(BuildContext context, _Section section) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _CategoryScreen(section: section)),
    );
  }

  Widget _searchField(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: TextField(
        controller: _controller,
        onChanged: _onChanged,
        onSubmitted: _submit,
        textInputAction: TextInputAction.search,
        style: context.appTextTheme.bodyLarge?.copyWith(
          color: context.appOnSurface,
        ),
        decoration: InputDecoration(
          hintText: 'Search movies and series',
          hintStyle: context.appTextTheme.bodyMedium?.copyWith(
            color: context.appOnSurfaceVariant,
          ),
          prefixIcon: Icon(
            Symbols.search_rounded,
            size: 20,
            color: context.appOnSurfaceVariant,
          ),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  onPressed: _clearSearch,
                  icon: Icon(
                    Symbols.close_rounded,
                    size: 18,
                    color: context.appOnSurfaceVariant,
                  ),
                ),
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }

  Widget _searchResults(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Text(
            'RESULTS FOR "$_query"',
            style: context.appTextTheme.labelSmall?.copyWith(
              color: context.appAccent,
            ),
          ),
        ),
        Expanded(
          child: LazyMediaGrid(
            key: ValueKey('search-$_query'),
            fetch: (page) => _tmdb.searchPage(_query, page: page),
          ),
        ),
      ],
    );
  }

  Widget _sectionsScroll(BuildContext context) {
    return CustomScrollView(
      slivers: [
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
                            Symbols.chevron_right_rounded,
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

  @override
  Widget build(BuildContext context) {
    final searching = _query.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 2),
          child: Text(
            'Browse',
            style: context.appTextTheme.titleLarge?.copyWith(
              letterSpacing: -0.5,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 2, 20, 12),
          child: Text(
            'Every category, nothing hidden.',
            style: context.appTextTheme.bodyMedium,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
          child: _searchField(context),
        ),
        Expanded(
          child: searching
              ? _searchResults(context)
              : _sectionsScroll(context),
        ),
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
                    icon: const Icon(Symbols.arrow_back_rounded),
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