import 'package:flutter/material.dart';

import '../models/media_item.dart';
import '../services/tmdb_service.dart';
import '../theme/app_theme.dart';
import '../widgets/media_poster.dart';
import '../widgets/theme_toggle.dart';
import 'detail_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _tmdb = TmdbService();
  final _rowKeys = <String, Future<List<MediaItem>>>{};
  late final Map<String, Future<List<MediaItem>> Function()> _tabs = {
    'Movies': _tmdb.popularMovies,
    'Series': _tmdb.popularSeries,
  };
  String _active = 'Movies';

  @override
  void initState() {
    super.initState();
    _rowKeys.addEntries(_tabs.entries);
  }

  void _setActive(String key) {
    setState(() {
      _active = key;
    });
    if (!_rowKeys.containsKey(key)) {
      _rowKeys[key] = _tabs[key]!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SearchScreen()),
                    ),
                    icon: const Icon(Icons.search, size: 22),
                  ),
                  const SizedBox(width: 4),
                  const ThemeToggle(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Row(
                children: [
                  for (final tab in _tabs.keys)
                    Padding(
                      padding: const EdgeInsets.only(right: 18),
                      child: InkWell(
                        onTap: () => _setActive(tab),
                        child: Text(
                          tab,
                          style: context.appTextTheme.titleLarge?.copyWith(
                            color: tab == _active
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
              child: FutureBuilder(
                future: _rowKeys[_active],
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return _errorView();
                  }
                  final items = snapshot.data ?? const [];
                  return _posterGrid(items);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _posterGrid(List<MediaItem> items) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 160,
        mainAxisSpacing: 20,
        crossAxisSpacing: 14,
        childAspectRatio: 0.5,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        return MediaPoster(
          item: item,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DetailScreen(item: item)),
          ),
        );
      },
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off, size: 40, color: context.appOnSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'Could not load titles.',
              style: context.appTextTheme.headlineMedium?.copyWith(
                color: context.appOnSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check your connection and try again.',
              style: context.appTextTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _rowKeys.remove(_active);
                });
                _rowKeys[_active] = _tabs[_active]!();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
