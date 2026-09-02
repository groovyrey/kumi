import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';

class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final (icon, label) = switch (state.themeMode) {
      ThemeMode.light => (Icons.light_mode, 'Light'),
      ThemeMode.dark => (Icons.dark_mode, 'Dark'),
      ThemeMode.system => (Icons.brightness_auto, 'System'),
    };

    return Tooltip(
      message: 'Theme: $label',
      child: IconButton(
        onPressed: state.cycleTheme,
        icon: Icon(icon, size: 22),
        style: IconButton.styleFrom(
          backgroundColor:
              Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
          foregroundColor: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}