import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

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

/// One entry in an [AppDropdown]: a value, a label, and an optional leading
/// widget (an icon or a color dot) shown in both the field and the menu.
class AppDropdownOption<T> {
  const AppDropdownOption(this.value, this.label, {this.leading});

  final T value;
  final String label;
  final Widget? leading;
}

/// A web-style select: a hairline field with an optional leading widget, a
/// quiet hint when nothing is chosen, and a bottom-sheet option list that
/// highlights the current value. Reusable for any single-choice preference
/// or filter (categories, theme, accent, ...).
class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.options,
    required this.onChanged,
    this.value,
    this.hint = 'Select',
    this.fieldLeading,
  });

  final List<AppDropdownOption<T>> options;
  final ValueChanged<T?> onChanged;
  final T? value;
  final String hint;
  final Widget? fieldLeading;

  AppDropdownOption<T>? _selected() {
    for (final option in options) {
      if (option.value == value) return option;
    }
    return null;
  }

  Future<void> _open(BuildContext context) async {
    final picked = await showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (sheetContext) => _AppDropdownSheet<T>(
        title: hint,
        options: options,
        value: value,
      ),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected();
    final leading = fieldLeading ?? selected?.leading;
    final label = selected?.label;
    return GestureDetector(
      onTap: () => _open(context),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(AppRadius.field),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              SizedBox(width: 26, height: 26, child: Center(child: leading)),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                label ?? hint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.appTextTheme.bodyMedium?.copyWith(
                  color: label != null
                      ? context.appOnSurface
                      : context.appOnSurfaceVariant,
                  fontWeight: label != null
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Symbols.expand_more_rounded,
              size: 20,
              color: context.appOnSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _AppDropdownSheet<T> extends StatelessWidget {
  const _AppDropdownSheet({
    required this.title,
    required this.options,
    required this.value,
  });

  final String title;
  final List<AppDropdownOption<T>> options;
  final T? value;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appSurface,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadius.card),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
              child: Text(
                title.toUpperCase(),
                style: context.appTextTheme.labelSmall?.copyWith(
                  color: context.appAccent,
                ),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                children: [
                  for (final option in options) _tile(context, option),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, AppDropdownOption<T> option) {
    final selected = option.value == value;
    return InkWell(
      onTap: () => Navigator.pop(context, option.value),
      borderRadius: BorderRadius.circular(AppRadius.control),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? context.appAccentSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
        child: Row(
          children: [
            if (option.leading != null) ...[
              SizedBox(width: 26, height: 26, child: Center(child: option.leading)),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                option.label,
                style: context.appTextTheme.bodyMedium?.copyWith(
                  color: selected
                      ? context.appAccent
                      : context.appOnSurface,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            if (selected)
              Icon(Symbols.check_rounded, size: 18, color: context.appAccent),
          ],
        ),
      ),
    );
  }
}