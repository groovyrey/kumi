import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/media_item.dart';
import '../services/tmdb_service.dart';
import '../services/version_checker.dart';
import '../services/watch_history.dart';
import '../theme/app_theme.dart';
import '../widgets/lazy_media_grid.dart';
import 'browse_screen.dart';
import 'player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _tmdb = TmdbService();
  final WatchHistory _history = WatchHistory.instance;
  VersionInfo? _update;
  late final List<(String, Widget)> _tabs = [
    (
      'Movies',
      LazyMediaGrid(fetch: (page) => _tmdb.popularMoviesPage(page: page)),
    ),
    (
      'Series',
      LazyMediaGrid(fetch: (page) => _tmdb.popularSeriesPage(page: page)),
    ),
  ];
  int _active = 0;

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
    _history.addListener(_onHistory);
    _history.ensureLoaded();
  }

  @override
  void dispose() {
    _history.removeListener(_onHistory);
    super.dispose();
  }

  void _onHistory() => setState(() {});

  Future<void> _checkForUpdate() async {
    final update = await VersionChecker().check();
    if (!mounted || update == null) return;
    setState(() => _update = update);
  }

  void _continueWatching(MediaItem item) {
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

  Future<void> _openRelease(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _updateBanner(BuildContext context, VersionInfo update) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 2),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: context.appAccentSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.appAccent.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.new_releases_rounded, size: 20, color: context.appAccent),
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
            onPressed: () => _openRelease(update.url),
            child: Text(
              'Update',
              style: TextStyle(color: context.appAccent),
            ),
          ),
        ],
      ),
    );
  }

Widget _continueWatchingSection(BuildContext context) {
    final entries = _history.entries.take(10).toList();
    if (entries.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
          child: Row(
            children: [
              Text(
                'Continue Watching',
                style: context.appTextTheme.titleMedium?.copyWith(
                  color: context.appOnSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _history.clear(),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                ),
                child: Text('Clear', style: TextStyle(color: context.appAccent)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 226,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: entries.length,
            itemBuilder: (context, i) {
              final entry = entries[i];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _ContinueCard(
                  entry: entry,
                  onTap: () => _continueWatching(entry.item),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_update case final VersionInfo update) _updateBanner(context, update),
        _continueWatchingSection(context),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
          child: Row(
            children: [
              Text(
                'Kumi',
                style: context.appTextTheme.titleLarge?.copyWith(
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Browse all',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BrowseScreen()),
                ),
                icon: const Icon(Icons.grid_view_rounded, size: 22),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: Row(
            children: [
              for (var i = 0; i < _tabs.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 18),
                  child: InkWell(
                    onTap: () => setState(() => _active = i),
                    child: Text(
                      _tabs[i].$1,
                      style: context.appTextTheme.titleLarge?.copyWith(
                        color: i == _active
                            ? context.appOnSurface
                            : context.appOnSurfaceVariant,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Divider(
          height: 18,
          color: AppColors.cardBorder,
        ),
        Expanded(
          child: IndexedStack(
            index: _active,
            children: [for (final tab in _tabs) tab.$2],
          ),
        ),
      ],
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({
    required this.entry,
    required this.onTap,
    this.width = 120,
  });

  final WatchEntry entry;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    final height = width * 1.5;
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
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (item.posterUrl.isEmpty)
                    Center(
                      child: Icon(
                        Icons.local_movies_outlined,
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
                          Icons.local_movies_outlined,
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
                        style: TextStyle(
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
                      child: const Icon(
                        Icons.play_arrow_rounded,
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
              maxLines: 2,
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