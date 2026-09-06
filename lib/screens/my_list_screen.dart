import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../services/favorites.dart';
import '../theme/app_theme.dart';
import '../widgets/media_poster.dart';
import 'detail_screen.dart';

/// The user's saved titles as a grid, newest first.
///
/// Renders straight from the local [Favorites] store — no paging needed — and
/// reacts live whenever a heart is toggled anywhere in the app.
class MyListScreen extends StatefulWidget {
  const MyListScreen({super.key});

  @override
  State<MyListScreen> createState() => _MyListScreenState();
}

class _MyListScreenState extends State<MyListScreen> {
  final Favorites _favorites = Favorites.instance;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _favorites,
      builder: (context, _) {
        final items = _favorites.items;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Text(
                'My List',
                style: context.appTextTheme.titleLarge?.copyWith(
                  letterSpacing: -0.5,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 2, 20, 12),
              child: Text(
                items.isEmpty
                    ? 'Titles you save stay here.'
                    : '${items.length} saved'
                        '${items.length == 1 ? '' : ' titles'}',
                style: context.appTextTheme.bodyMedium,
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? _emptyState(context)
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
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
                            MaterialPageRoute(
                              builder: (_) => DetailScreen(item: item),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: context.appAccentSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                PhosphorIcons.heart(PhosphorIconsStyle.fill),
                size: 30,
                color: context.appAccent,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Nothing saved yet',
              textAlign: TextAlign.center,
              style: context.appTextTheme.titleMedium?.copyWith(
                color: context.appOnSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap the heart on any movie or series to keep it here.',
              textAlign: TextAlign.center,
              style: context.appTextTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}