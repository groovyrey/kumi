import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../models/media_item.dart';
import '../services/favorites.dart';
import '../theme/app_theme.dart';

class MediaPoster extends StatelessWidget {
  const MediaPoster({
    super.key,
    required this.item,
    this.width = 130,
    this.onTap,
  });

  final MediaItem item;
  final double width;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final height = width * 1.5;
    return SizedBox(
      width: width,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
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
                  child: item.posterUrl.isEmpty
                      ? _placeholder(context)
                      : Image.network(
                          item.posterUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(context),
                        ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: ListenableBuilder(
                    listenable: Favorites.instance,
                    builder: (context, _) {
                      final saved = Favorites.instance.contains(item);
                      return _FavoriteButton(item: item, saved: saved);
                    },
                  ),
                ),
              ],
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

  Widget _placeholder(BuildContext context) {
    return Center(
      child: Icon(
        PhosphorIcons.filmSlate(),
        size: 32,
        color: context.appOnSurfaceVariant,
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.item, required this.saved});

  final MediaItem item;
  final bool saved;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Favorites.instance.toggle(item),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          shape: BoxShape.circle,
          border: Border.all(
            color: saved ? Colors.white : Colors.white.withValues(alpha: 0.55),
            width: saved ? 1.4 : 1,
          ),
        ),
        child: Icon(
          saved ? PhosphorIcons.heart(PhosphorIconsStyle.fill) : PhosphorIcons.heart(),
          size: 16,
          color: Colors.white,
        ),
      ),
    );
  }
}
