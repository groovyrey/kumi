import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/web_controls.dart';

/// App preferences: theme mode and accent color. Picked via the sidebar, all
/// choices are persisted through [AppState] and applied app-wide.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  int _themeIndex(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 0,
        ThemeMode.dark => 1,
        ThemeMode.system => 2,
      };

  ThemeMode _modeAt(int index) => switch (index) {
        0 => ThemeMode.light,
        1 => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: context.appTextTheme.titleLarge?.copyWith(
              color: context.appOnSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text('Make Kumi yours.', style: TextStyle(height: 1.4)),
          const SizedBox(height: 28),
          _eyebrow(context, 'Theme'),
          const SizedBox(height: 10),
          SurfaceCard(
            child: Segmented(
              labels: const ['Light', 'Dark', 'System'],
              selectedIndex: _themeIndex(state.themeMode),
              onChanged: (i) => state.setThemeMode(_modeAt(i)),
            ),
          ),
          const SizedBox(height: 28),
          _eyebrow(context, 'Accent color'),
          const SizedBox(height: 10),
          SurfaceCard(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final option in AccentOption.values)
                  _accentSwatch(
                    context,
                    option,
                    isDark: isDark,
                    selected: state.accent == option,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 34),
          Center(
            child: Text(
              'Kumi  ·  a quiet place to watch',
              style: context.appTextTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _eyebrow(BuildContext context, String label) {
    return Text(
      label.toUpperCase(),
      style: context.appTextTheme.labelSmall?.copyWith(
        color: context.appAccent,
      ),
    );
  }

  Widget _accentSwatch(
    BuildContext context,
    AccentOption option, {
    required bool isDark,
    required bool selected,
  }) {
    final palette = isDark ? option.dark : option.light;
    return Tooltip(
      message: option.label,
      child: InkWell(
        onTap: () => context.read<AppState>().setAccent(option),
        customBorder: const CircleBorder(),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: palette.accent,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? context.appAccent : AppColors.cardBorder,
              width: selected ? 2.5 : 1,
            ),
          ),
          child: selected
              ? Icon(
                  Symbols.check_rounded,
                  size: 21,
                  color: palette.onAccent,
                )
              : null,
        ),
      ),
    );
  }
}