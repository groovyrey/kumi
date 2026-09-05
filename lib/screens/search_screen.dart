import 'package:flutter/material.dart';

import '../models/media_item.dart';
import '../services/tmdb_service.dart';
import '../theme/app_theme.dart';
import '../widgets/media_poster.dart';
import 'detail_screen.dart';

/// Query-driven search with lazy pagination: typing/resubmitting starts a new
/// page 1 fetch; scrolling to the bottom fetches the next combined page of
/// movie and series results.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _tmdb = TmdbService();
  final _controller = TextEditingController();
  String _query = '';
  final List<MediaItem> _results = [];
  int _page = 0;
  bool _hasMore = true;
  bool _loading = false;
  bool _failed = false;

  Future<void> _search(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      setState(() {
        _query = '';
        _results.clear();
        _page = 0;
        _hasMore = true;
        _failed = false;
        _loading = false;
      });
      return;
    }
    _query = q;
    _results.clear();
    _page = 0;
    _hasMore = true;
    _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore || _query.isEmpty) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final result = await _tmdb.searchPage(_query, page: _page + 1);
      if (!mounted) return;
      if (result.page == 1 && _page > 0) return;
      setState(() {
        _page = result.page;
        _hasMore = result.hasMore;
        _results.addAll(result.items);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onSubmitted: _search,
            style: context.appTextTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: 'Search movies & series',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _controller.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _controller.clear();
                        _search('');
                      },
                    ),
              filled: true,
              fillColor: context.appSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.cardBorder),
              ),
            ),
          ),
        ),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    if (_query.isEmpty) {
      return Center(
        child: Text(
          'Find something to watch',
          style: context.appTextTheme.bodyMedium,
        ),
      );
    }
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.axis == Axis.vertical &&
            notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - 600) {
          _loadMore();
        }
        return false;
      },
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 160,
          mainAxisSpacing: 18,
          crossAxisSpacing: 14,
          childAspectRatio: 0.5,
        ),
        itemCount: _results.length + 1,
        itemBuilder: (context, i) {
          if (i == _results.length) return _footer(context);
          final item = _results[i];
          return MediaPoster(
            item: item,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DetailScreen(item: item)),
            ),
          );
        },
      ),
    );
  }

  Widget _footer(BuildContext context) {
    Widget child;
    if (_loading) {
      child = const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else if (_failed) {
      child = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Could not load more.',
            style: context.appTextTheme.bodyMedium,
          ),
          TextButton(onPressed: _loadMore, child: const Text('Retry')),
        ],
      );
    } else if (_results.isEmpty) {
      child = Text(
        'No results for "$_query"',
        style: context.appTextTheme.bodyMedium,
      );
    } else if (!_hasMore) {
      child = Text(
        'You reached the end.',
        style: context.appTextTheme.bodyMedium,
      );
    } else {
      child = const SizedBox(height: 8);
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 18),
        child: child,
      ),
    );
  }
}