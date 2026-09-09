import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

import '../services/watch_history.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/web_controls.dart';

/// App preferences: theme, playback behaviour, update channel and data
/// housekeeping. Picked via the sidebar; all choices are persisted through
/// [AppState] and applied app-wide.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _speeds = <double>[
    0.5,
    0.75,
    1.0,
    1.25,
    1.5,
    1.75,
    2.0,
  ];

  static const _subtitleLanguages = <String>[
    'English',
    'Spanish',
    'French',
    'German',
    'Italian',
    'Portuguese',
    'Turkish',
    'Arabic',
    'Dutch',
    'Swedish',
    'Polish',
    'Russian',
    'Hindi',
    'Chinese',
    'Japanese',
    'Korean',
  ];

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
                  PhosphorIcons.sun(),
                  size: 18,
                  color: context.appAccent,
                ),
              ),
              AppDropdownOption(
                ThemeMode.dark,
                'Dark',
                leading: Icon(
                  PhosphorIcons.moon(),
                  size: 18,
                  color: context.appAccent,
                ),
              ),
              AppDropdownOption(
                ThemeMode.system,
                'System',
                leading: Icon(
                  PhosphorIcons.monitor(),
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
          _eyebrow(context, 'Playback'),
          const SizedBox(height: 10),
          SurfaceCard(
            padding: const EdgeInsets.all(0),
            child: Column(
              children: [
                _dropdownRow(
                  context,
                  title: 'Playback engine',
                  hint: 'Playback engine',
                  trailing: AppDropdown<PlaybackEngine>(
                    value: state.engine,
                    hint: 'Playback engine',
                    onChanged: (v) {
                      if (v != null) state.setEngine(v);
                    },
                    options: const [
                      AppDropdownOption(
                        PlaybackEngine.native,
                        'Native first',
                      ),
                      AppDropdownOption(
                        PlaybackEngine.embed,
                        'Embeds only',
                      ),
                    ],
                  ),
                  caption: 'Native plays direct files with mpv; the embed is '
                      'used as a fallback when nothing resolves.',
                ),
                _switchRow(
                  context,
                  title: 'Hardware decode',
                  caption: 'Off by default; enable if video stutters.',
                  value: state.hardwareDecode,
                  onChanged: state.setHardwareDecode,
                ),
                _dropdownRow(
                  context,
                  title: 'Default speed',
                  hint: 'Speed',
                  trailing: AppDropdown<double>(
                    value: state.defaultSpeed,
                    hint: 'Speed',
                    onChanged: (v) {
                      if (v != null) state.setDefaultSpeed(v);
                    },
                    options: [
                      for (final s in _speeds)
                        AppDropdownOption(s, '${s.toStringAsFixed(2)}x'),
                    ],
                  ),
                ),
                _dropdownRow(
                  context,
                  title: 'Preferred subtitles',
                  hint: 'Subtitles',
                  trailing: AppDropdown<String>(
                    value: state.preferredSubtitle,
                    hint: 'Subtitles',
                    onChanged: (v) {
                      if (v != null) state.setPreferredSubtitle(v);
                    },
                    options: [
                      const AppDropdownOption('', 'None'),
                      for (final language in _subtitleLanguages)
                        AppDropdownOption(language, language),
                    ],
                  ),
                  caption: 'Auto-selects this track from the source when '
                      'available.',
                ),
                _dropdownRow(
                  context,
                  title: 'Controls auto-hide',
                  hint: 'Auto-hide',
                  trailing: AppDropdown<ControlsTimeout>(
                    value: state.controlsTimeout,
                    hint: 'Auto-hide',
                    onChanged: (v) {
                      if (v != null) state.setControlsTimeout(v);
                    },
                    options: const [
                      AppDropdownOption(
                        ControlsTimeout.short,
                        'After 4s',
                      ),
                      AppDropdownOption(
                        ControlsTimeout.long,
                        'After 8s',
                      ),
                      AppDropdownOption(
                        ControlsTimeout.never,
                        'Never',
                      ),
                    ],
                  ),
                ),
                _switchRow(
                  context,
                  title: 'Keep screen awake',
                  caption: 'Prevents the screen from sleeping while playing.',
                  value: state.keepAwake,
                  onChanged: state.setKeepAwake,
                ),
              ],
            ),
          ),
          const SizedBox(height: 34),
          _eyebrow(context, 'Sources'),
          const SizedBox(height: 10),
          SurfaceCard(
            padding: const EdgeInsets.all(0),
            child: Column(
              children: [
                _dropdownRow(
                  context,
                  title: 'Preferred source',
                  hint: 'Source',
                  trailing: AppDropdown<SourceOrder>(
                    value: state.sourceOrder,
                    hint: 'Source',
                    onChanged: (v) {
                      if (v != null) state.setSourceOrder(v);
                    },
                    options: const [
                      AppDropdownOption(SourceOrder.auto, 'Auto'),
                      AppDropdownOption(SourceOrder.vidlink, 'VidLink'),
                      AppDropdownOption(SourceOrder.vidlove, '111Movies'),
                    ],
                    fieldLeading: Icon(
                      PhosphorIcons.trayArrowUp(),
                      size: 18,
                      color: context.appOnSurfaceVariant,
                    ),
                  ),
                  caption: 'Which direct-file provider is tried first.',
                ),
                _dropdownRow(
                  context,
                  title: 'Preferred quality',
                  hint: 'Quality',
                  trailing: AppDropdown<QualityPreference>(
                    value: state.quality,
                    hint: 'Quality',
                    onChanged: (v) {
                      if (v != null) state.setQuality(v);
                    },
                    options: [
                      for (final q in QualityPreference.values)
                        AppDropdownOption(q, q.label),
                    ],
                    fieldLeading: Icon(
                      PhosphorIcons.gauge(),
                      size: 18,
                      color: context.appOnSurfaceVariant,
                    ),
                  ),
                  caption: 'Used when the source exposes that tier.',
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: _ResolverField(initial: state.resolverOverride),
                ),
              ],
            ),
          ),
          const SizedBox(height: 34),
          _eyebrow(context, 'Updates'),
          const SizedBox(height: 10),
          SurfaceCard(
            padding: const EdgeInsets.all(0),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: _rowText(
                          context,
                          title: 'Update channel',
                          caption: 'Beta includes rolling pre-releases.',
                        ),
                      ),
                      Segmented(
                        labels: const ['Stable', 'Beta'],
                        selectedIndex: state.updateChannel ==
                                UpdateChannel.beta
                            ? 1
                            : 0,
                        onChanged: (i) =>
                            state.setUpdateChannel(UpdateChannel.values[i]),
                      ),
                    ],
                  ),
                ),
                _switchRow(
                  context,
                  title: 'Check for updates',
                  caption: 'Shows the banner when a newer build is out.',
                  value: state.autoCheckUpdates,
                  onChanged: state.setAutoCheckUpdates,
                ),
              ],
            ),
          ),
          const SizedBox(height: 34),
          _eyebrow(context, 'Data'),
          const SizedBox(height: 10),
          SurfaceCard(
            padding: const EdgeInsets.all(0),
            child: Column(
              children: [
                _actionRow(
                  context,
                  icon: PhosphorIcons.clockCounterClockwise(),
                  title: 'Clear watch history',
                  caption: 'Remove all Continue Watching entries.',
                  onTap: () => _confirmClearHistory(context),
                ),
                _actionRow(
                  context,
                  icon: PhosphorIcons.arrowsClockwise(),
                  title: 'Reset all settings',
                  caption: 'Restore every preference to its default.',
                  onTap: () => _confirmReset(context),
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

  Future<void> _confirmClearHistory(BuildContext context) async {
    final confirmed = await _confirm(
      context,
      title: 'Clear watch history?',
      message: 'This removes every title from Continue Watching.',
      action: 'Clear',
    );
    if (confirmed) await WatchHistory.instance.clear();
  }

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await _confirm(
      context,
      title: 'Reset all settings?',
      message: 'Theme, playback and source preferences go back to defaults. '
          'Favorites and watch history stay.',
      action: 'Reset',
    );
    if (confirmed) {
      await context.read<AppState>().resetAll();
    }
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String action,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.appSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        title: Text(
          title,
          style: context.appTextTheme.titleMedium?.copyWith(
            color: context.appOnSurface,
          ),
        ),
        content: Text(
          message,
          style: context.appTextTheme.bodyMedium?.copyWith(
            color: context.appOnSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              action,
              style: TextStyle(color: context.appAccent),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Widget _dropdownRow(
    BuildContext context, {
    required String title,
    required String hint,
    required Widget trailing,
    String? caption,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: _rowText(context, title: title, caption: caption)),
              const SizedBox(width: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 190),
                child: trailing,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _switchRow(
    BuildContext context, {
    required String title,
    required String caption,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 14),
      child: Row(
        children: [
          Expanded(
            child: _rowText(context, title: title, caption: caption),
          ),
          Switch(
            value: value,
            activeThumbColor: context.appAccent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _rowText(
    BuildContext context, {
    required String title,
    String? caption,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: context.appTextTheme.bodyMedium?.copyWith(
            color: context.appOnSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (caption != null) ...[
          const SizedBox(height: 2),
          Text(
            caption,
            style: context.appTextTheme.bodySmall?.copyWith(
              color: context.appOnSurfaceVariant,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }

  Widget _actionRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String caption,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: context.appAccent),
            const SizedBox(width: 14),
            Expanded(child: _rowText(context, title: title, caption: caption)),
            Icon(
              PhosphorIcons.caretRight(),
              size: 16,
              color: context.appOnSurfaceVariant,
            ),
          ],
        ),
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

/// Text field for the custom resolver worker URL. Saves on every change and
/// trims the trailing slash, so [ResolverService] can use it verbatim.
class _ResolverField extends StatefulWidget {
  const _ResolverField({required this.initial});

  final String initial;

  @override
  State<_ResolverField> createState() => _ResolverFieldState();
}

class _ResolverFieldState extends State<_ResolverField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resolver worker URL',
          style: context.appTextTheme.bodyMedium?.copyWith(
            color: context.appOnSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Leave empty for the built-in worker. The URL must end in /api/kumi.',
          style: context.appTextTheme.bodySmall?.copyWith(
            color: context.appOnSurfaceVariant,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _controller,
          keyboardType: TextInputType.url,
          style: context.appTextTheme.bodyMedium?.copyWith(
            color: context.appOnSurface,
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: 'https://…/api/kumi',
            hintStyle: context.appTextTheme.bodyMedium?.copyWith(
              color: context.appOnSurfaceVariant,
            ),
            filled: true,
            fillColor: context.appSurfaceVariant.withValues(alpha: 0.4),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.control),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (value) {
            context.read<AppState>().setResolverOverride(value);
          },
        ),
      ],
    );
  }
}