import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';

class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final (icon, label) = switch (state.themeMode) {
      ThemeMode.light => (PhosphorIcons.sun, 'Light'),
      ThemeMode.dark => (PhosphorIcons.moon, 'Dark'),
      ThemeMode.system => (PhosphorIcons.sunDim, 'System'),
    };

    return Tooltip(
      message: 'Theme: $label',
      child: IconButton(
        onPressed: state.cycleTheme,
        icon: PhosphorIcon(icon, size: 22),
        style: IconButton.styleFrom(
          backgroundColor:
              Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
          foregroundColor: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}