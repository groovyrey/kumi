import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import '../models/genre.dart';
import '../models/media_item.dart';
import '../services/tmdb_service.dart';
import '../theme/app_theme.dart';
import '../widgets/lazy_media_grid.dart';
import '../widgets/poster_rail.dart';
import '../widgets/web_controls.dart';
import 'detail_screen.dart';

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
  List<Genre> _genres = [];
  int _genreId = -1;
  MediaItem? _featured;

  static const _allCategories = -1;

  @override
  void initState() {
    super.initState();
    _loadGenres();
    _loadFeatured();
  }

  Future<void> _loadFeatured() async {
    try {
      final page = await _tmdb.nowPlayingMoviesPage();
      if (!mounted || page.items.isEmpty) return;
      setState(() {
        _featured = page.items[Random().nextInt(page.items.length)];
      });
    } catch (_) {
      // Quiet: the rail still works without a featured pick.
    }
  }

  Future<void> _loadGenres() async {
    try {
      final genres = await _tmdb.movieGenres();
      if (mounted && genres.isNotEmpty) {
        setState(() => _genres = genres);
      }
    } catch (_) {
      if (mounted) setState(() => _genres = Genre.common);
    }
  }

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
          prefixIconConstraints: const BoxConstraints(
            minWidth: 26,
            minHeight: 26,
          ),
          prefixIcon: SizedBox(
            width: 26,
            height: 26,
            child: Icon(
              Symbols.search_rounded,
              size: 20,
              color: context.appAccent,
            ),
          ),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 36,
                    height: 44,
                  ),
                  onPressed: _clearSearch,
                  icon: Icon(
                    Symbols.close_rounded,
                    size: 18,
                    color: context.appOnSurfaceVariant,
                  ),
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
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

  Widget _genreResults(BuildContext context, Genre genre) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Text(
            '${genre.name.toUpperCase()} MOVIES',
            style: context.appTextTheme.labelSmall?.copyWith(
              color: context.appAccent,
            ),
          ),
        ),
        Expanded(
          child: LazyMediaGrid(
            key: ValueKey('genre-${genre.id}'),
            fetch: (page) => _tmdb.genreMoviesPage(genre.id, page: page),
          ),
        ),
      ],
    );
  }

  Widget _categoryDropdown(BuildContext context) {
    return AppDropdown<int>(
      value: _genreId,
      hint: 'All categories',
      fieldLeading: Icon(
        Symbols.category_rounded,
        size: 20,
        color: context.appAccent,
      ),
      onChanged: (value) => setState(() => _genreId = value ?? _allCategories),
      options: [
        const AppDropdownOption<int>(_allCategories, 'All categories'),
        for (final genre in _genres)
          AppDropdownOption<int>(genre.id, genre.name),
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
                            style: context.appTextTheme.bodyMedium?.copyWith(
                              color: context.appAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Symbols.chevron_right_rounded,
                            size: 12,
                            color: context.appAccent,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_featured != null && section.title == 'Now Playing')
            SliverToBoxAdapter(child: _featuredCard(context, _featured!)),
          SliverToBoxAdapter(
            child: SizedBox(height: 250, child: PosterRail(fetch: section.fetch)),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    );
  }

  Widget _featuredCard(BuildContext context, MediaItem item) {
    final poster = item.posterUrl;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 12),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DetailScreen(item: item)),
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Ink(
          width: double.infinity,
          height: 190,
          decoration: BoxDecoration(
            color: context.appSurface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              if (poster.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppRadius.card - 1),
                    bottomLeft: Radius.circular(AppRadius.card - 1),
                  ),
                  child: Image.network(
                    poster,
                    width: 124,
                    height: 190,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _featuredFallback(context),
                  ),
                )
              else
                _featuredFallback(context),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 14, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NOW PLAYING',
                        style: context.appTextTheme.labelSmall?.copyWith(
                          color: context.appAccent,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.appTextTheme.titleMedium?.copyWith(
                          color: context.appOnSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.overview,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: context.appTextTheme.bodySmall,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(
                            Symbols.star_rounded,
                            size: 16,
                            color: context.appAccent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.rating.toStringAsFixed(1),
                            style: context.appTextTheme.bodyMedium?.copyWith(
                              color: context.appOnSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(
                            Symbols.play_circle_rounded,
                            size: 16,
                            color: context.appAccent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Watch',
                            style: context.appTextTheme.bodyMedium?.copyWith(
                              color: context.appAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featuredFallback(BuildContext context) {
    return Container(
      width: 124,
      height: 190,
      color: context.appSurfaceVariant,
      child: Icon(
        Symbols.movie_rounded,
        size: 40,
        color: context.appOnSurfaceVariant,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searching = _query.isNotEmpty;
    final genre = _genreId > 0
        ? (_genres.isNotEmpty
            ? _genres.firstWhere(
                (g) => g.id == _genreId,
                orElse: () => Genre(id: _genreId, name: 'Category'),
              )
            : Genre(id: _genreId, name: 'Category'))
        : null;
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
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              children: [
                SizedBox(width: 230, child: _searchField(context)),
                const SizedBox(width: 8),
                SizedBox(width: 170, child: _categoryDropdown(context)),
              ],
            ),
          ),
        ),
        Expanded(
          child: searching
              ? _searchResults(context)
              : genre != null
                  ? _genreResults(context, genre)
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