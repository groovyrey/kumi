import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Web-style selection components (shadcn RadioGroup / ToggleGroup look):
/// flat hairline containers, accent-tinted active pills, quiet inactive text.
/// Kept intentionally generic so any preference or filter can reuse them.

/// A segmented radio-group: one choice active at a time, filling its width.
class Segmented extends StatelessWidget {
  const Segmented({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.appSurfaceVariant.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(child: _segment(context, i)),
          ],
        ],
      ),
    );
  }

  Widget _segment(BuildContext context, int index) {
    final selected = index == selectedIndex;
    return GestureDetector(
      onTap: () => onChanged(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? context.appAccentSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: selected
                ? context.appAccent.withValues(alpha: 0.4)
                : Colors.transparent,
          ),
        ),
        child: Center(
          child: Text(
            labels[index],
            style: context.appTextTheme.bodyMedium?.copyWith(
              color: selected
                  ? context.appAccent
                  : context.appOnSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
            ),
          ),
        ),
      ),
    );
  }
}

/// Flat border card with the app's surface color and main radius, used to
/// group a preference block like a shadcn Card.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: child,
    );
  }
}