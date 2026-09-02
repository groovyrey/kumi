import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'widgets/kumi_mark.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KumiApp());
}

class KumiApp extends StatelessWidget {
  const KumiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState()..init(),
      child: Consumer<AppState>(
        builder: (context, state, _) {
          final brightness = state.themeMode == ThemeMode.system
              ? WidgetsBinding.instance.platformDispatcher.platformBrightness
              : state.themeMode == ThemeMode.dark
                  ? Brightness.dark
                  : Brightness.light;
          AppColors.setThemeBrightness(brightness);

          return MaterialApp(
            title: 'Kumi',
            theme: buildAppTheme(),
            darkTheme: buildDarkTheme(),
            themeMode: state.themeMode,
            debugShowCheckedModeBanner: false,
            home: const SplashGate(),
          );
        },
      ),
    );
  }
}

class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        setState(() => _showSplash = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: _showSplash
          ? const SplashScreen(key: ValueKey('splash'))
          : const HomeScreen(key: ValueKey('home')),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _scale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: const KumiMark(size: 120),
              ),
            ),
            const SizedBox(height: 26),
            FadeTransition(
              opacity: _fade,
              child: Text(
                'Kumi',
                style: context.appTextTheme.displayMedium?.copyWith(
                  color: context.appOnSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}