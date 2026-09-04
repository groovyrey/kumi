import 'package:flutter/material.dart';

import '../models/media_item.dart';
import '../services/tmdb_service.dart';
import '../theme/app_theme.dart';
import '../widgets/media_poster.dart';
import 'detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _tmdb = TmdbService();
  final _controller = TextEditingController();
  List<MediaItem> _results = [];
  bool _loading = false;
  String? _error;

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _error = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await _tmdb.search(query);
      if (!mounted) return;
      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not reach TMDB. Check your connection.';
        _loading = false;
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
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text(_error!, style: context.appTextTheme.bodyMedium),
      );
    }
    if (_controller.text.isEmpty) {
      return Center(
        child: Text(
          'Find something to watch',
          style: context.appTextTheme.bodyMedium,
        ),
      );
    }
    if (_results.isEmpty) {
      return Center(
        child: Text(
          'No results for "${_controller.text}"',
          style: context.appTextTheme.bodyMedium,
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 160,
        mainAxisSpacing: 18,
        crossAxisSpacing: 14,
        childAspectRatio: 0.5,
      ),
      itemCount: _results.length,
      itemBuilder: (context, i) {
        final item = _results[i];
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
}
