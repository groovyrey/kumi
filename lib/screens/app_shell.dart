import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/kumi_mark.dart';
import 'about_screen.dart';
import 'browse_screen.dart';
import 'home_screen.dart';
import 'schedule_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';

/// Application shell: a persistent sidebar (NavigationRail) plus the selected
/// destination. The rail expands into a full sidebar with labels on wide
/// screens and stays as a compact icon rail on phones. Destinations are built
/// on first visit and kept alive, so each lazy grid keeps its scroll state.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  final List<Widget?> _screens = List<Widget?>.filled(6, null);

  @override
  void initState() {
    super.initState();
    _screens[0] = const HomeScreen();
  }

  static const _titles = <(IconData, IconData, String)>[
    (Icons.home_outlined, Icons.home_rounded, 'Home'),
    (Icons.explore_outlined, Icons.explore_rounded, 'Browse'),
    (Icons.search_outlined, Icons.search_rounded, 'Search'),
    (Icons.event_outlined, Icons.event_rounded, 'Schedule'),
    (Icons.settings_outlined, Icons.settings_rounded, 'Settings'),
    (Icons.info_outline, Icons.info_rounded, 'About'),
  ];

  void _select(int index) {
    if (_screens[index] == null) {
      _screens[index] = switch (index) {
        0 => const HomeScreen(),
        1 => BrowseScreen(),
        2 => const SearchScreen(),
        3 => const ScheduleScreen(),
        4 => const SettingsScreen(),
        _ => const AboutScreen(),
      };
    }
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 840;
        return Scaffold(
          body: SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                    for (final (icon, selectedIcon, label) in _titles)
                      NavigationRailDestination(
                        icon: Icon(icon),
                        selectedIcon: Icon(selectedIcon),
                        label: Text(label),
                      ),
                  ],
                ),
                Container(width: 1, color: AppColors.cardBorder),
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