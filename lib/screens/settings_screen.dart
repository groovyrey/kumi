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
          AppDropdown<ThemeMode>(
            value: state.themeMode,
            hint: 'Theme',
            onChanged: (mode) {
              if (mode != null) state.setThemeMode(mode);
            },
            options: [
              AppDropdownOption(
                ThemeMode.light,
                'Light',
                leading: Icon(
                  Symbols.light_mode_rounded,
                  size: 18,
                  color: context.appAccent,
                ),
              ),
              AppDropdownOption(
                ThemeMode.dark,
                'Dark',
                leading: Icon(
                  Symbols.dark_mode_rounded,
                  size: 18,
                  color: context.appAccent,
                ),
              ),
              AppDropdownOption(
                ThemeMode.system,
                'System',
                leading: Icon(
                  Symbols.brightness_auto_rounded,
                  size: 18,
                  color: context.appAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          _eyebrow(context, 'Accent color'),
          const SizedBox(height: 10),
          AppDropdown<AccentOption>(
            value: state.accent,
            hint: 'Accent',
            onChanged: (accent) {
              if (accent != null) state.setAccent(accent);
            },
            options: [
              for (final option in AccentOption.values)
                AppDropdownOption(
                  option,
                  option.label,
                  leading: _accentDot(context, option, isDark: isDark),
                ),
            ],
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

  Widget _accentDot(
    BuildContext context,
    AccentOption option, {
    required bool isDark,
  }) {
    final palette = isDark ? option.dark : option.light;
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: palette.accent,
        shape: BoxShape.circle,
        border: Border.all(
          color: context.appOnSurface.withValues(alpha: 0.2),
        ),
      ),
    );
  }
}