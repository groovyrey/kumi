import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../config.dart';
import '../theme/app_theme.dart';
import '../widgets/embed_ad_guard.dart';

/// A Netflix-style immersive full-screen player. The default provider is
/// autoplayed on entry; providers can be swapped while watching.
class PlayerScreen extends StatefulWidget {
  const PlayerScreen({
    super.key,
    required this.title,
    required this.id,
    required this.media,
    this.initialIndex = 0,
  });

  final String title;
  final int id;
  final String media;
  final int initialIndex;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late WebViewController _controller;
  late int _index;
  bool _loading = true;
  bool _controlsVisible = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = _buildController(_urlForIndex(_index));
    _scheduleHide();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    EmbedAdGuard.detach();
    super.dispose();
  }

  String _urlForIndex(int index) {
    final src = EmbedSources.sources[index];
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

    final controller = WebViewController.fromPlatformCreationParams(params)
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

  void _switchSource(int index) {
    if (index == _index) return;
    setState(() {
      _index = index;
      _loading = true;
    });
    _controller.loadRequest(Uri.parse(_urlForIndex(index)));
    _scheduleHide();
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
              AnimatedOpacity(
                opacity: _controlsVisible ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: _topBar(context),
              ),
              AnimatedOpacity(
                opacity: _controlsVisible ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: _bottomBar(context),
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
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 26),
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

  Widget _bottomBar(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.85),
              Colors.transparent,
            ],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(12, 20, 12, 10),
        child: Row(
          children: [
            for (var i = 0; i < EmbedSources.sources.length; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _SourceChip(
                    label: EmbedSources.sources[i].$1,
                    active: i == _index,
                    onTap: () => _switchSource(i),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: context.appTextTheme.bodyMedium?.copyWith(
            color: active ? Colors.black : Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
