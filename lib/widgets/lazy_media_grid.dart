import 'package:flutter/material.dart';

import '../models/media_item.dart';
import '../screens/detail_screen.dart';
import '../services/tmdb_service.dart';
import '../theme/app_theme.dart';
import 'media_poster.dart';

/// A lazily-paginated vertical poster grid.
///
/// Builds only visible cells and requests the next TMDB page when the user
/// scrolls near the bottom, appending the results. Pages are fetched on
/// demand with a loading footer and a retry footer on failure, so long lists
/// stay cheap no matter how far the user scrolls.
class LazyMediaGrid extends StatefulWidget {
  const LazyMediaGrid({
    super.key,
    required this.fetch,
    this.maxCrossAxisExtent = 160,
    this.aspectRatio = 0.5,
    this.horizontalPadding = 20,
    this.verticalPadding = 8,
    this.loadBeneath = 800,
  });

  /// Fetches page [page] (1-based). Returned `MediaPage.hasMore` drives
  /// further loads.
  final Future<MediaPage> Function(int page) fetch;

  final double maxCrossAxisExtent;
  final double aspectRatio;
  final double horizontalPadding;
  final double verticalPadding;
  final double loadBeneath;

  @override
  State<LazyMediaGrid> createState() => _LazyMediaGridState();
}

class _LazyMediaGridState extends State<LazyMediaGrid> {
  final List<MediaItem> _items = [];
  int _page = 0;
  bool _hasMore = true;
  bool _loading = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final result = await widget.fetch(_page + 1);
      if (!mounted) return;
      setState(() {
        _page = result.page;
        _hasMore = result.hasMore;
        _items.addAll(result.items);
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
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.axis == Axis.vertical &&
            notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - widget.loadBeneath) {
          _loadMore();
        }
        return false;
      },
      child: GridView.builder(
        padding: EdgeInsets.fromLTRB(
          widget.horizontalPadding,
          widget.verticalPadding,
          widget.horizontalPadding,
          24,
        ),
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: widget.maxCrossAxisExtent,
          mainAxisSpacing: 20,
          crossAxisSpacing: 14,
          childAspectRatio: widget.aspectRatio,
        ),
        itemCount: _items.length + 1,
        itemBuilder: (context, i) {
          if (i == _items.length) return _footer(context);
          final item = _items[i];
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
            'Could not load titles.',
            style: context.appTextTheme.bodyMedium,
          ),
          TextButton(onPressed: _loadMore, child: const Text('Retry')),
        ],
      );
    } else if (_items.isEmpty) {
      child = Text(
        'No titles found.',
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
    return Center(child: Padding(padding: const EdgeInsets.only(top: 18), child: child));
  }
}