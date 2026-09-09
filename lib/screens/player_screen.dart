import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../config.dart';
import '../services/resolver_service.dart';
import '../theme/app_theme.dart';
import '../widgets/embed_ad_guard.dart';

/// Immersive full-screen player. Native direct-file sources (VidLink,
/// 111Movies) are resolved through the worker and played with media_kit. When
/// no native source resolves for a title, playback falls back to the CineSrc
/// embed in the WebView with the ad layer stripped by the guard.
class PlayerScreen extends StatefulWidget {
  const PlayerScreen({
    super.key,
    required this.title,
    required this.id,
    required this.media,
    this.preferredProvider,
    this.forceEmbed = false,
  });

  final String title;
  final int id;
  final String media;

  /// When set, this native provider ('vidlink' | 'vidlove') is tried first.
  final String? preferredProvider;

  /// When true, skip native sources and go straight to the embed.
  final bool forceEmbed;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final ResolverService _resolver = ResolverService();

  _PlayerMode _mode = _PlayerMode.loading;
  Player? _player;
  VideoController? _videoController;
  StreamSubscription<String>? _errorSub;
  WebViewController? _web;
  String _nativeLabel = '';
  String _fallbackNotice = '';
  final List<String> _failures = [];
  bool _nativeFailed = false;
  bool _controlsVisible = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _start();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _hideTimer?.cancel();
    unawaited(_errorSub?.cancel());
    _errorSub = null;
    EmbedAdGuard.detach();
    final player = _player;
    _player = null;
    _videoController = null;
    if (player != null) unawaited(player.dispose());
    super.dispose();
  }

  String get _type => widget.media == 'tvplay' ? 'tv' : 'movie';

  String _embedUrl() {
    final src = EmbedSources.sources.first;
    return src.$2(id: widget.id, media: widget.media);
  }

  List<({String name, String label})> _providers = const [];
  int _providerIndex = 0;

  /// Native-first: try every direct-file provider, then fall back to embed.
  /// An explicit [PlayerScreen.preferredProvider] is attempted first (and
  /// removed from the later pass so it is not tried twice).
  Future<void> _start() async {
    if (widget.forceEmbed) {
      _fallbackToEmbed();
      return;
    }
    var providers = NativeSources.providers;
    final preferred = widget.preferredProvider;
    if (preferred != null) {
      final others = providers
          .where((p) => p.name != preferred)
          .toList();
      final preferredItem =
          providers.where((p) => p.name == preferred).firstOrNull;
      providers = [
        if (preferredItem != null) preferredItem,
        ...others,
      ];
    }
    _providers = providers;
    _providerIndex = 0;
    await _tryNextProvider();
  }

  Future<void> _tryNextProvider() async {
    while (_providerIndex < _providers.length) {
      final provider = _providers[_providerIndex++];
      try {
        final source = await _resolver.resolve(
          provider: provider.name,
          type: _type,
          id: widget.id,
        );
        if (!mounted) return;
        final started = await _playNative(source, provider.label);
        if (!mounted) return;
        if (started) return;
      } catch (error) {
        if (!mounted) return;
        _failures.add('${provider.label}: $error');
      }
    }
    if (!mounted) return;
    _fallbackToEmbed(
      notice:
          'None of the direct sources could play (${_failures.join('; ')}) — using the embed source instead.',
    );
  }

  /// Starts native playback; returns true when the media actually opened.
  Future<bool> _playNative(ResolvedSource source, String label) async {
    final player = Player();
    final controller = VideoController(
      player,
      // Software decode avoids MediaCodec failures seen on some devices with
      // both H.264 and HEVC hardware decoding.
      configuration: const VideoControllerConfiguration(
        enableHardwareAcceleration: false,
      ),
    );
    final errorSub = player.stream.error.listen((message) {
      if (!mounted || !identical(_player, player)) return;
      _failures.add('$label: $message');
      debugPrint('[player] native error: $message');
      unawaited(_retryAfterRuntimeError());
    });
    _errorSub = errorSub;
    setState(() {
      _mode = _PlayerMode.loading;
      _nativeLabel = label;
      _nativeFailed = false;
    });
    try {
      await player.open(Media(source.playUrl));
      if (!mounted) {
        unawaited(errorSub.cancel());
        unawaited(player.dispose());
        return false;
      }
      setState(() {
        _player = player;
        _videoController = controller;
        _mode = _PlayerMode.native;
      });
      _scheduleHide();
      return true;
    } catch (error) {
      _failures.add('$label: $error');
      unawaited(errorSub.cancel());
      unawaited(player.dispose());
      return false;
    }
  }

  /// Tears down the failed native player and tries the next provider, so a
  /// source that opens but fails at decode time is automatically superseded.
  Future<void> _retryAfterRuntimeError() async {
    final broken = _player;
    final brokenSub = _errorSub;
    setState(() {
      _player = null;
      _videoController = null;
      _mode = _PlayerMode.loading;
    });
    _errorSub = null;
    unawaited(brokenSub?.cancel());
    await broken?.dispose();
    if (!mounted) return;
    await _tryNextProvider();
  }

  void _fallbackToEmbed({String? notice}) {
    if (!mounted) return;
    final controller = _buildController(_embedUrl());
    setState(() {
      _web = controller;
      _mode = _PlayerMode.embed;
      _nativeFailed = notice != null;
      _fallbackNotice =
          notice ?? '';
    });
    _scheduleHide();
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
            EmbedAdGuard.strip(controller);
          },
          onPageFinished: (_) {
            EmbedAdGuard.strip(controller);
          },
          onWebResourceError: (_) {},
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
      _scheduleHide();
    });
  }

  Widget _videoBody() {
    final player = _player;
    final controller = _videoController;
    if (player == null || controller == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    return Center(
      child: Video(
        controller: controller,
        controls: NoVideoControls,
        fit: BoxFit.contain,
        fill: const Color(0xFF000000),
      ),
    );
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
              Positioned.fill(child: _buildPlayerArea()),
              if (_nativeFailed)
                Positioned(
                  top: 10,
                  left: 12,
                  right: 12,
                  child: _fallbackBanner(context),
                ),
              IgnorePointer(
                ignoring: !_controlsVisible,
                child: AnimatedOpacity(
                  opacity: _controlsVisible ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: _topBar(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerArea() {
    switch (_mode) {
      case _PlayerMode.loading:
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      case _PlayerMode.native:
        return _videoBody();
      case _PlayerMode.embed:
        final web = _web;
        if (web == null) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggleControls,
          child: WebViewWidget(controller: web),
        );
    }
  }

  Widget _fallbackBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(PhosphorIcons.info(), size: 16, color: context.appAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _fallbackNotice,
              style: context.appTextTheme.bodySmall?.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    final subtitle = _mode == _PlayerMode.native
        ? 'Playing via $_nativeLabel'
        : null;
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.appTextTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.appTextTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
enum _PlayerMode { loading, native, embed }