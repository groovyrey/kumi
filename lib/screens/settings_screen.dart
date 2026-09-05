import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';

/// App preferences: theme mode and accent color. Picked via the sidebar, all
/// choices are persisted through [AppState] and applied app-wide.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _themeModes = <(String, String, IconData, ThemeMode)>[
    ('Light', 'Sunny surfaces', Icons.light_mode_outlined, ThemeMode.light),
    ('Dark', 'Warm near-black', Icons.dark_mode_outlined, ThemeMode.dark),
    ('System', 'Follow the device', Icons.brightness_auto_outlined, ThemeMode.system),
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 2),
            child: Text(
              'Settings',
              style: context.appTextTheme.titleLarge?.copyWith(
                letterSpacing: -0.5,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 4),
            child: Text(
              'Make Kumi yours.',
              style: context.appTextTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 8),
          _sectionLabel(context, 'Appearance'),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: context.appSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              children: [
                for (var i = 0; i < _themeModes.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      indent: 14,
                      endIndent: 14,
                      color: AppColors.cardBorder,
                    ),
                  _choiceRow(
                    context,
                    label: _themeModes[i].$1,
                    subtitle: _themeModes[i].$2,
                    icon: _themeModes[i].$3,
                    selected: state.themeMode == _themeModes[i].$4,
                    onTap: () => state.setThemeMode(_themeModes[i].$4),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          _sectionLabel(context, 'Accent color'),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            decoration: BoxDecoration(
              color: context.appSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                for (final option in AccentOption.values)
                  _accentSwatch(context, option,
                      isDark: isDark, selected: state.accent == option),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            child: Center(
              child: Text(
                'Kumi  ·  a quiet place to watch',
                style: context.appTextTheme.bodyMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Text(
        label,
        style: context.appTextTheme.titleMedium?.copyWith(
          color: context.appAccent,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _choiceRow(
    BuildContext context, {
    required String label,
    required String subtitle,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: selected
                  ? context.appAccent
                  : context.appOnSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: context.appTextTheme.titleMedium?.copyWith(
                      color: context.appOnSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: context.appTextTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, size: 20, color: context.appAccent),
          ],
        ),
      ),
    );
  }

  Widget _accentSwatch(BuildContext context, AccentOption option,
      {required bool isDark, required bool selected}) {
    final palette = isDark ? option.dark : option.light;
    return Tooltip(
      message: option.label,
      child: InkWell(
        onTap: () => context.read<AppState>().setAccent(option),
        customBorder: const CircleBorder(),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: palette.accent,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? context.appAccent : AppColors.cardBorder,
              width: selected ? 2 : 1,
            ),
          ),
          child: selected
              ? Icon(Icons.check, size: 22, color: palette.onAccent)
              : null,
        ),
      ),
    );
  }
}