import 'dart:ui';

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

/// Application shell: a minimal top bar plus a floating bottom navigation
/// bar. The bar sits above the content with a rounded pill shape and a soft
/// backdrop, giving the app a modern, lightweight feel. Destinations are
/// built on first visit and kept alive so scroll state is preserved.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  int _index = 0;
  final List<Widget?> _screens = List<Widget?>.filled(5, null);

  static const _items = <(IconData, String)>[
    (Symbols.home_rounded, 'Home'),
    (Symbols.explore_rounded, 'Browse'),
    (Symbols.event_rounded, 'Schedule'),
    (Symbols.settings_rounded, 'Settings'),
    (Symbols.info_rounded, 'About'),
  ];

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
      ScreenTime.instance.switchSection(_items[index].$2);
    }
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appSurface,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: 8,
                right: 4,
              ),
              child: KumiMark(size: 24),
            ),
            const SizedBox(width: 6),
            Text(
              _items[_index].$2,
              style: context.appTextTheme.titleMedium?.copyWith(
                color: context.appOnSurface,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _index,
          children: [
            for (final screen in _screens)
              screen ?? const SizedBox.shrink(),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: _FloatingNavBar(
          items: _items,
          selectedIndex: _index,
          onTap: _select,
        ),
      ),
    );
  }
}

class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({
    required this.items,
    required this.selectedIndex,
    required this.onTap,
  });

  final List<(IconData, String)> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: context.appSurface.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: AppColors.cardBorder.withValues(alpha: 0.6),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _NavBarItem(
                    icon: items[i].$1,
                    label: items[i].$2,
                    selected: i == selectedIndex,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? context.appAccentSoft.withValues(alpha: 0.8)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: selected
                  ? context.appAccent
                  : context.appOnSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: context.appTextTheme.labelSmall?.copyWith(
                color: selected
                    ? context.appAccent
                    : context.appOnSurfaceVariant,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 10,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}