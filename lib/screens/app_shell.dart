import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import '../services/screen_time.dart';
import '../theme/app_theme.dart';
import '../widgets/kumi_mark.dart';
import 'about_screen.dart';
import 'browse_screen.dart';
import 'home_screen.dart';
import 'schedule_screen.dart';
import 'settings_screen.dart';

/// Application shell: a global top bar (app title plus quick actions, like the
/// classic layout) above an optional sidebar. The sidebar is a NavigationRail
/// that expands into a labeled sidebar on wide screens, stays as a compact
/// icon rail on phones, and can be hidden entirely with the menu button in the
/// top bar. Destinations are built on first visit and kept alive, so each lazy
/// grid keeps its scroll state. Search lives inside the Browse page.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  int _index = 0;
  bool _railOpen = true;
  final List<Widget?> _screens = List<Widget?>.filled(5, null);

  static const _titles = <(IconData, String)>[
    (Symbols.home_rounded, 'Home'),
    (Symbols.explore_rounded, 'Browse'),
    (Symbols.event_rounded, 'Schedule'),
    (Symbols.settings_rounded, 'Settings'),
    (Symbols.info_rounded, 'About'),
  ];
  static const _labels = ['Home', 'Browse', 'Schedule', 'Settings', 'About'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _screens[0] = const HomeScreen();
    ScreenTime.instance.ensureLoaded();
    ScreenTime.instance.setActive(true);
    ScreenTime.instance.switchSection('Home');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ScreenTime.instance.setActive(state == AppLifecycleState.resumed);
  }

  void _select(int index) {
    if (_screens[index] == null) {
      _screens[index] = switch (index) {
        0 => const HomeScreen(),
        1 => BrowseScreen(),
        2 => const ScheduleScreen(),
        3 => const SettingsScreen(),
        _ => const AboutScreen(),
      };
    }
    if (index != _index) {
      ScreenTime.instance.switchSection(_labels[index]);
    }
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 840;
        return Scaffold(
          backgroundColor: context.appSurface,
          appBar: AppBar(
            backgroundColor: context.appSurface,
            foregroundColor: context.appOnSurface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              tooltip: _railOpen ? 'Hide sidebar' : 'Show sidebar',
              onPressed: () => setState(() => _railOpen = !_railOpen),
              icon: const Icon(Symbols.menu_rounded),
            ),
            title: Text(
              'Kumi',
              style: context.appTextTheme.titleLarge?.copyWith(
                color: context.appOnSurface,
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'Browse',
                onPressed: () => _select(1),
                icon: const Icon(Symbols.grid_view_rounded),
              ),
            ],
          ),
          body: SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_railOpen) ...[
                  NavigationRail(
                    selectedIndex: _index,
                    onDestinationSelected: _select,
                    extended: wide,
                    labelType: wide
                        ? NavigationRailLabelType.all
                        : NavigationRailLabelType.none,
                    leading: Padding(
                      padding: const EdgeInsets.only(top: 14, bottom: 6),
                      child: Center(
                        child: KumiMark(size: wide ? 30 : 26),
                      ),
                    ),
                    destinations: [
                      for (final (icon, label) in _titles)
                        NavigationRailDestination(
                          icon: Icon(icon),
                          selectedIcon: Icon(icon),
                          label: Text(label),
                        ),
                    ],
                  ),
                  Container(width: 1, color: AppColors.cardBorder),
                ],
                Expanded(
                  child: IndexedStack(
                    index: _index,
                    children: [
                      for (final screen in _screens)
                        screen ?? const SizedBox.shrink(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}