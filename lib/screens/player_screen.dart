import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../config.dart';
import '../services/resolver_service.dart';
import '../state/app_state.dart';
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
  double? _dragSeconds;
  String? _nativeSourceName;
  List<SubtitleInfo> _subtitles = const [];
  String? _activeSubtitleUrl;

  // Settings snapshot taken when the player opens.
  PlaybackEngine _engine = PlaybackEngine.native;
  bool _hardwareDecode = false;
  double _defaultRate = 1.0;
  String _preferredSubtitle = '';
  ControlsTimeout _controlsTimeout = ControlsTimeout.short;
  SourceOrder _sourceOrder = SourceOrder.auto;
  bool _keepAwake = true;
  String _quality = 'auto';

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    final app = context.read<AppState>();
    _engine = app.engine;
    _hardwareDecode = app.hardwareDecode;
    _defaultRate = app.defaultSpeed;
    _preferredSubtitle = app.preferredSubtitle;
    _controlsTimeout = app.controlsTimeout;
    _sourceOrder = app.sourceOrder;
    _keepAwake = app.keepAwake;
    _quality = app.quality.value;
    _start();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    unawaited(WakelockPlus.disable());
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
    if (widget.forceEmbed || _engine == PlaybackEngine.embed) {
      _fallbackToEmbed();
      return;
    }
    final preferred = widget.preferredProvider ??
        (_sourceOrder == SourceOrder.auto ? null : _sourceOrder.name);
    await _startWithPreferred(preferred);
  }

  /// Rebuilds the native provider queue with [preferred] first and runs it.
  /// Also used when the user switches source mid-playback.
  Future<void> _startWithPreferred(String? preferred) async {
    _providers = [
      for (final p in NativeSources.providers)
        if (p.name == preferred) p,
      for (final p in NativeSources.providers)
        if (p.name != preferred) p,
    ];
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
          quality: _quality,
        );
        if (!mounted) return;
        final started = await _playNative(source, provider.name, provider.label);
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
  Future<bool> _playNative(ResolvedSource source, String name, String label) async {
    final player = Player();
    final controller = VideoController(
      player,
      // Hardware decode can be enabled in Settings; off by default because
      // MediaCodec has been flaky for both H.264 and HEVC on some devices.
      configuration: VideoControllerConfiguration(
        enableHardwareAcceleration: _hardwareDecode,
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
      _nativeSourceName = name;
      _subtitles = source.subtitles;
      _activeSubtitleUrl = null;
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
      if (_defaultRate != 1.0) unawaited(player.setRate(_defaultRate));
      _applyPreferredSubtitle(player);
      if (_keepAwake) unawaited(WakelockPlus.enable());
      _scheduleHide();
      return true;
    } catch (error) {
      _failures.add('$label: $error');
      unawaited(errorSub.cancel());
      unawaited(player.dispose());
      return false;
    }
  }

  /// When the user set a preferred subtitle language in Settings, pick the
  /// first source track whose language mentions it.
  void _applyPreferredSubtitle(Player player) {
    if (_preferredSubtitle.isEmpty) return;
    final pref = _preferredSubtitle.toLowerCase();
    SubtitleInfo? match;
    for (final s in _subtitles) {
      if (s.label.toLowerCase().contains(pref)) {
        match = s;
        break;
      }
    }
    if (match == null) return;
    setState(() => _activeSubtitleUrl = match.url);
    unawaited(player.setSubtitleTrack(
      SubtitleTrack.uri(
        match.url,
        title: match.label,
        language: match.label,
      ),
    ));
  }

  /// Tears down the failed native player and tries the next provider, so a
  /// source that opens but fails at decode time is automatically superseded.
  Future<void> _retryAfterRuntimeError() async {
    final broken = _player;
    final brokenSub = _errorSub;
    setState(() {
      _player = null;
      _videoController = null;
      _nativeSourceName = null;
      _subtitles = const [];
      _activeSubtitleUrl = null;
      _mode = _PlayerMode.loading;
    });
    _errorSub = null;
    unawaited(brokenSub?.cancel());
    await broken?.dispose();
    if (!mounted) return;
    await _tryNextProvider();
  }

  /// The name of the source currently on screen ('vidlink' | 'vidlove' |
  /// 'CineSrc'), used to highlight the active item in the switch sheet.
  String? _currentSourceName() {
    if (_mode == _PlayerMode.embed) return EmbedSources.sources.first.$1;
    if (_mode == _PlayerMode.native) return _nativeSourceName;
    return null;
  }

  /// Tears down whatever is playing and starts the requested source over.
  void _switchSource(String name) {
    if (name == _currentSourceName()) return;
    _hideTimer?.cancel();
    final broken = _player;
    final brokenSub = _errorSub;
    setState(() {
      _failures.clear();
      _nativeFailed = false;
      _fallbackNotice = '';
      _player = null;
      _videoController = null;
      _nativeSourceName = null;
      _subtitles = const [];
      _activeSubtitleUrl = null;
      _web = null;
      _mode = _PlayerMode.loading;
    });
    _errorSub = null;
    unawaited(brokenSub?.cancel());
    unawaited(broken?.dispose());
    if (name == EmbedSources.sources.first.$1) {
      _fallbackToEmbed();
    } else {
      unawaited(_startWithPreferred(name));
    }
  }

  void _showSourceSheet(BuildContext context) {
    final current = _currentSourceName();
    final items = [
      for (final p in NativeSources.providers)
        (name: p.name, label: p.label, current: p.name == current),
      (
        name: EmbedSources.sources.first.$1,
        label: EmbedSources.sources.first.$1,
        current: EmbedSources.sources.first.$1 == current,
      ),
    ];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.appSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Switch source',
                  style: context.appTextTheme.titleMedium?.copyWith(
                    color: context.appOnSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            for (final item in items)
              ListTile(
                leading: Icon(
                  item.current
                      ? PhosphorIcons.checkCircle()
                      : PhosphorIcons.playCircle(),
                  color: item.current
                      ? context.appAccent
                      : context.appOnSurfaceVariant,
                ),
                title: Text(
                  item.label,
                  style: context.appTextTheme.bodyMedium?.copyWith(
                    color: context.appOnSurface,
                  ),
                ),
                trailing:
                    item.current ? Icon(PhosphorIcons.check(), color: context.appAccent) : null,
                onTap: () {
                  Navigator.pop(sheetContext);
                  if (!item.current) _switchSource(item.name);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
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
    if (_controlsTimeout == ControlsTimeout.never) return;
    final delay = _controlsTimeout == ControlsTimeout.long
        ? const Duration(seconds: 8)
        : const Duration(seconds: 4);
    _hideTimer = Timer(delay, () {
      if (mounted) setState(() => _controlsVisible = false);
    });
  }

  void _toggleControls() {
    setState(() {
      _controlsVisible = !_controlsVisible;
      _scheduleHide();
    });
  }

  String _fmtTime(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    String two(int v) => v.toString().padLeft(2, '0');
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }

  Widget _bottomControls(BuildContext context) {
    final player = _player;
    if (_mode != _PlayerMode.native || player == null) {
      return const SizedBox.shrink();
    }
    return Container(
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
      padding: const EdgeInsets.only(left: 8, right: 16, top: 18, bottom: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _timeText(context, player.stream.position, player.state.position),
              Expanded(child: _seekBar(context, player)),
              _timeText(context, player.stream.duration, player.state.duration),
            ],
          ),
          Row(
            children: [
              _speedButton(context, player),
              const SizedBox(width: 4),
              _subtitleButton(context, player),
              const SizedBox(width: 4),
              _audioButton(context, player),
              const Spacer(),
              Text(
                _nativeLabel.isNotEmpty ? _nativeLabel : 'Native',
                style: context.appTextTheme.labelMedium?.copyWith(
                  color: Colors.white38,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Big central transport cluster: rewind 10s, play/pause, forward 10s.
  Widget _centerControls(BuildContext context) {
    final player = _player;
    if (_mode != _PlayerMode.native || player == null) {
      return const SizedBox.shrink();
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          padding: const EdgeInsets.all(10),
          iconSize: 40,
          onPressed: () {
            _hideTimer?.cancel();
            _seekBy(player, -10);
            _scheduleHide();
          },
          icon: Icon(Icons.replay_10, color: Colors.white),
        ),
        _centerPlayPauseButton(context, player),
        IconButton(
          padding: const EdgeInsets.all(10),
          iconSize: 40,
          onPressed: () {
            _hideTimer?.cancel();
            _seekBy(player, 10);
            _scheduleHide();
          },
          icon: Icon(Icons.forward_10, color: Colors.white),
        ),
      ],
    );
  }

  void _seekBy(Player player, int seconds) {
    var target = player.state.position + Duration(seconds: seconds);
    if (target < Duration.zero) target = Duration.zero;
    unawaited(player.seek(target));
  }

  Widget _centerPlayPauseButton(BuildContext context, Player player) {
    return StreamBuilder<bool>(
      stream: player.stream.playing,
      initialData: player.state.playing,
      builder: (context, snap) {
        final playing = snap.data ?? player.state.playing;
        final completed = player.state.completed;
        return IconButton(
          padding: const EdgeInsets.all(12),
          iconSize: 72,
          onPressed: () {
            _hideTimer?.cancel();
            if (completed) {
              unawaited(player.seek(Duration.zero));
              unawaited(player.play());
            } else {
              unawaited(player.playOrPause());
            }
            _scheduleHide();
          },
          icon: Icon(
            completed
                ? PhosphorIcons.arrowsClockwise()
                : (playing
                    ? PhosphorIcons.pause()
                    : PhosphorIcons.play()),
            color: Colors.white,
          ),
        );
      },
    );
  }

  Widget _timeText(
    BuildContext context,
    Stream<Duration> stream,
    Duration initial,
  ) {
    return StreamBuilder<Duration>(
      stream: stream,
      initialData: initial,
      builder: (context, snap) {
        final value = snap.data ?? Duration.zero;
        return Text(
          _fmtTime(value),
          style: context.appTextTheme.bodySmall?.copyWith(color: Colors.white70),
        );
      },
    );
  }

  Widget _seekBar(BuildContext context, Player player) {
    return StreamBuilder<Duration>(
      stream: player.stream.position,
      initialData: player.state.position,
      builder: (context, snapPos) {
        return StreamBuilder<Duration>(
          stream: player.stream.duration,
          initialData: player.state.duration,
          builder: (context, snapDur) {
            final duration = snapDur.data ?? Duration.zero;
            final max = duration.inMilliseconds > 0
                ? duration.inMilliseconds.toDouble()
                : 1.0;
            final drag = _dragSeconds;
            final value = (drag != null
                    ? drag * 1000
                    : (snapPos.data ?? Duration.zero).inMilliseconds.toDouble())
                .clamp(0.0, max);
            return Slider(
              value: value,
              min: 0,
              max: max,
              activeColor: context.appAccent,
              inactiveColor: Colors.white24,
              onChangeStart: (_) => _hideTimer?.cancel(),
              onChanged: (v) => setState(() => _dragSeconds = v / 1000),
              onChangeEnd: (v) {
                setState(() => _dragSeconds = null);
                unawaited(player.seek(Duration(milliseconds: v.round())));
                _scheduleHide();
              },
            );
          },
        );
      },
    );
  }

  void _showSpeedMenu(BuildContext context, Player player) {
    const speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.appSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final s in speeds)
              ListTile(
                title: Text(
                  '${s.toStringAsFixed(2)}x',
                  style: context.appTextTheme.bodyMedium?.copyWith(
                    color: context.appOnSurface,
                  ),
                ),
                trailing: player.state.rate == s
                    ? Icon(PhosphorIcons.check(), color: context.appAccent)
                    : null,
                onTap: () {
                  Navigator.pop(sheetContext);
                  unawaited(player.setRate(s));
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _speedButton(BuildContext context, Player player) {
    return StreamBuilder<double>(
      stream: player.stream.rate,
      initialData: player.state.rate,
      builder: (context, snap) {
        final rate = snap.data ?? 1.0;
        return InkWell(
          onTap: () => _showSpeedMenu(context, player),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              '${rate.toStringAsFixed(2)}x',
              style: context.appTextTheme.labelMedium?.copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }

  /// 'CC' button; only shown when the resolved source ships subtitle tracks.
  Widget _subtitleButton(BuildContext context, Player player) {
    if (_subtitles.isEmpty) return const SizedBox.shrink();
    return InkWell(
      onTap: () => _showSubtitleSheet(context, player),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          'CC',
          style: context.appTextTheme.labelMedium?.copyWith(
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// Audio-track picker; only shown when the source exposes more than one.
  Widget _audioButton(BuildContext context, Player player) {
    return StreamBuilder<Tracks>(
      stream: player.stream.tracks,
      initialData: player.state.tracks,
      builder: (context, snap) {
        final tracks = snap.data ?? player.state.tracks;
        // Ignore the 'auto'/'no' placeholders; only show when several real
        // audio tracks are available to switch between.
        final realAudio = tracks.audio
            .where((a) => a.id != 'auto' && a.id != 'no');
        if (realAudio.length < 2) return const SizedBox.shrink();
        return InkWell(
          onTap: () => _showAudioSheet(context, player),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              'Audio',
              style: context.appTextTheme.labelMedium?.copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSubtitleSheet(BuildContext context, Player player) {
    final items = <({bool isOff, String label, SubtitleInfo? sub})>[
      (isOff: true, label: 'Off', sub: null),
      for (final s in _subtitles)
        (isOff: false, label: s.label, sub: s),
    ];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.appSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Subtitles',
                  style: context.appTextTheme.titleMedium?.copyWith(
                    color: context.appOnSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            for (final item in items)
              ListTile(
                title: Text(
                  item.label,
                  style: context.appTextTheme.bodyMedium?.copyWith(
                    color: context.appOnSurface,
                  ),
                ),
                trailing: _activeSubtitleUrl == null && item.isOff
                    ? Icon(PhosphorIcons.check(), color: context.appAccent)
                    : (item.sub != null &&
                            item.sub!.url == _activeSubtitleUrl)
                        ? Icon(PhosphorIcons.check(),
                            color: context.appAccent)
                        : null,
                onTap: () {
                  Navigator.pop(sheetContext);
                  final sub = item.sub;
                  if (sub == null) {
                    setState(() => _activeSubtitleUrl = null);
                    unawaited(player.setSubtitleTrack(SubtitleTrack.no()));
                  } else {
                    setState(() => _activeSubtitleUrl = sub.url);
                    unawaited(player.setSubtitleTrack(
                      SubtitleTrack.uri(
                        sub.url,
                        title: sub.label,
                        language: sub.label,
                      ),
                    ));
                  }
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showAudioSheet(BuildContext context, Player player) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.appSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => StreamBuilder<Tracks>(
        stream: player.stream.tracks,
        initialData: player.state.tracks,
        builder: (context, snapTracks) {
          return StreamBuilder<Track>(
            stream: player.stream.track,
            initialData: player.state.track,
            builder: (context, snapTrack) {
              final tracks = snapTracks.data ?? player.state.tracks;
              final selectedId = snapTrack.data?.audio.id;
              final realAudio = [
                for (final a in tracks.audio)
                  if (a.id != 'auto' && a.id != 'no') a,
              ];
              return SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Audio',
                          style: context.appTextTheme.titleMedium?.copyWith(
                            color: context.appOnSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    for (final audio in realAudio)
                      ListTile(
                        title: Text(
                          audio.title ?? audio.id,
                          style: context.appTextTheme.bodyMedium?.copyWith(
                            color: context.appOnSurface,
                          ),
                        ),
                        trailing: audio.id == selectedId
                            ? Icon(PhosphorIcons.check(), color: context.appAccent)
                            : null,
                        onTap: () {
                          Navigator.pop(sheetContext);
                          unawaited(player.setAudioTrack(audio));
                        },
                      ),
                    const SizedBox(height: 8),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
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
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  ignoring: !_controlsVisible,
                  child: AnimatedOpacity(
                    opacity: _controlsVisible ? 1 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: _topBar(context),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: 0,
                child: IgnorePointer(
                  ignoring: !_controlsVisible,
                  child: AnimatedOpacity(
                    opacity: _controlsVisible ? 1 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Center(child: _centerControls(context)),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  ignoring: !_controlsVisible,
                  child: AnimatedOpacity(
                    opacity: _controlsVisible ? 1 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: _bottomControls(context),
                  ),
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
    return Container(
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
      padding: const EdgeInsets.only(left: 4, right: 8, top: 6, bottom: 18),
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
          IconButton(
            onPressed: () => _showSourceSheet(context),
            tooltip: 'Switch source',
            icon: Icon(
              PhosphorIcons.arrowsClockwise(),
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}
enum _PlayerMode { loading, native, embed }