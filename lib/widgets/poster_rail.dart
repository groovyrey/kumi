import 'package:flutter/material.dart';

import '../models/media_item.dart';
import '../screens/detail_screen.dart';
import '../services/tmdb_service.dart';
import 'media_poster.dart';

/// A lazily-paginated horizontal poster rail.
///
/// Builds only the posters currently in view and requests the next TMDB page
/// when the user nears the right edge, so every category section grows
/// incrementally instead of loading its whole catalog up front.
class PosterRail extends StatefulWidget {
  const PosterRail({
    super.key,
    required this.fetch,
    this.posterWidth = 130,
    this.loadBeneath = 500,
  });

  final Future<MediaPage> Function(int page) fetch;
  final double posterWidth;
  final double loadBeneath;

  @override
  State<PosterRail> createState() => _PosterRailState();
}

class _PosterRailState extends State<PosterRail> {
  static const _footerKey = ValueKey('poster-rail-footer');

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
    final posterHeight = widget.posterWidth * 1.5;
    final railHeight = posterHeight + 46;
    return SizedBox(
      height: railHeight,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.axis == Axis.horizontal &&
              notification.metrics.pixels >=
                  notification.metrics.maxScrollExtent -
                      widget.loadBeneath) {
            _loadMore();
          }
          return false;
        },
        child: ListView.builder(
          key: _footerKey,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _items.length + 1,
          itemBuilder: (context, i) {
            if (i == _items.length) return _railFooter(railHeight);
            final item = _items[i];
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: MediaPoster(
                item: item,
                width: widget.posterWidth,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DetailScreen(item: item)),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _railFooter(double railHeight) {
    Widget child;
    if (_loading) {
      child = const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else if (_failed) {
      child = IconButton(
        tooltip: 'Retry',
        onPressed: _loadMore,
        icon: Icon(Icons.refresh,
            size: 22, color: Theme.of(context).colorScheme.onSurfaceVariant),
      );
    } else if (_items.isEmpty) {
      child = const SizedBox.shrink();
    } else {
      child = const SizedBox(width: 4);
    }
    return SizedBox(
      width: 44,
      height: railHeight,
      child: Center(child: child),
    );
  }
}