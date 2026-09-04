import 'package:flutter/material.dart';

import '../models/media_item.dart';
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
        Icons.local_movies_outlined,
        size: 32,
        color: context.appOnSurfaceVariant,
      ),
    );
  }
}
