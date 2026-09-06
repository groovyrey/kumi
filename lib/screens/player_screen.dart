import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../config.dart';
import '../theme/app_theme.dart';
import '../widgets/embed_ad_guard.dart';

/// A Netflix-style immersive full-screen player. The CineSrc provider is
/// autoplayed on entry and the in-page ad layer is stripped by the guard.
class PlayerScreen extends StatefulWidget {
  const PlayerScreen({
    super.key,
    required this.title,
    required this.id,
    required this.media,
  });

  final String title;
  final int id;
  final String media;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late WebViewController _controller;
  bool _loading = true;
  bool _controlsVisible = true;
  Timer? _hideTimer;
  Timer? _auditTimer;
  String? _auditReport;
  bool _auditOpen = true;

  @override
  void initState() {
    super.initState();
    // Immersive: hide the Android system bars while watching, so the embed
    // player gets the whole screen and its controls (settings, share) are
    // fully reachable.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _controller = _buildController(_url());
    _scheduleHide();
    if (AppConfig.kDebugAdAudit) {
      unawaited(_runAudit());
      _auditTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        unawaited(_runAudit());
      });
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _hideTimer?.cancel();
    _auditTimer?.cancel();
    EmbedAdGuard.detach();
    super.dispose();
  }

  Future<void> _runAudit() async {
    final raw = await EmbedAdGuard.audit(_controller);
    if (!mounted || raw == null) return;
    final report = _formatAudit(raw);
    if (report == _auditReport) return;
    setState(() => _auditReport = report);
  }

  String _formatAudit(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return raw.length > 300 ? raw.substring(0, 300) : raw;
      }
      final lines = <String>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final id = item['id'] ?? '';
        final cls = item['cls'] ?? '';
        final src = item['src'] ?? '';
        final z = item['z'];
        final w = item['w'] ?? 0;
        final h = item['h'] ?? 0;
        final text = item['text'] ?? '';
        final summary = [
          '${item['tag']}',
          if (id.toString().isNotEmpty) '#$id',
          if (cls.toString().isNotEmpty) '.$cls',
          if (src.toString().isNotEmpty) '->$src',
          'z=${z ?? 'auto'}',
          '${item['pos']} $w x $h',
        ].join(' ');
        lines.add(summary);
        if (text.toString().isNotEmpty) {
          lines.add('   "$text"');
        }
      }
      return lines.join('\n');
    } catch (_) {
      return raw.length > 300 ? raw.substring(0, 300) : raw;
    }
  }

  String _url() {
    final src = EmbedSources.sources.first;
    return src.$2(id: widget.id, media: widget.media);
  }

  WebViewController _buildController(String url) {
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final controller = WebViewController.fromPlatformCreationParams(params);
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            setState(() => _loading = true);
            EmbedAdGuard.strip(controller);
          },
          onPageFinished: (_) {
            setState(() => _loading = false);
            EmbedAdGuard.strip(controller);
          },
          onWebResourceError: (_) => setState(() => _loading = false),
          onNavigationRequest: EmbedAdGuard.guardNavigation,
        ),
      );

    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(false);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    controller.loadRequest(Uri.parse(url));
    EmbedAdGuard.attach(controller);
    return controller;
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _controlsVisible = false);
    });
  }

  void _toggleControls() {
    setState(() {
      _controlsVisible = !_controlsVisible;
      if (_controlsVisible) _scheduleHide();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleControls,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _toggleControls,
                  child: WebViewWidget(controller: _controller),
                ),
              ),
              if (_loading)
                const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              IgnorePointer(
                ignoring: !_controlsVisible,
                child: AnimatedOpacity(
                  opacity: _controlsVisible ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: _topBar(context),
                ),
              ),
              if (AppConfig.kDebugAdAudit && _auditOpen && _auditReport != null)
                Positioned(
                  top: 64,
                  right: 12,
                  child: Container(
                    width: 280,
                    constraints: const BoxConstraints(maxHeight: 300),
                    padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.78),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              PhosphorIcons.warningCircle(),
                              color: Colors.amber.shade400,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            const Expanded(
                              child: Text(
                                'AD AUDIT - top overlays',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  setState(() => _auditOpen = false),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                  minWidth: 32, minHeight: 32),
                              icon: Icon(
                                PhosphorIcons.x(),
                                color: Colors.white70,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                        Flexible(
                          child: SingleChildScrollView(
                            child: Text(
                              _auditReport!,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                height: 1.4,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.85),
              Colors.transparent,
            ],
          ),
        ),
        padding: const EdgeInsets.only(left: 4, right: 16, top: 6, bottom: 18),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(PhosphorIcons.arrowLeft(), color: Colors.white, size: 26),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.appTextTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
