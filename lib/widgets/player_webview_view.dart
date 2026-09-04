import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Factory id registered natively in AndroidMainActivity (PlayerWebViewFactory).
const _kViewType = 'player-webview';

/// A native WebView used as the in-app player (normal browser behavior with
/// popup/new-tab blocking). It renders with `AndroidView` and routes load state
/// back to [onLoadChanged] over a per-instance method channel.
class PlayerWebView extends StatefulWidget {
  const PlayerWebView({
    super.key,
    required this.url,
    required this.onLoadChanged,
    this.onDiagnostics,
  });

  final String url;
  final ValueChanged<bool> onLoadChanged;

  /// Debug callback receiving (kind, message) where kind is 'page', 'req',
  /// or 'error'. Used by the player screen to show live network diagnostics
  /// on-device without logcat.
  final void Function(String kind, String message)? onDiagnostics;

  @override
  State<PlayerWebView> createState() => _PlayerWebViewState();
}

class _PlayerWebViewState extends State<PlayerWebView> {
  late final String _channelName = 'kumi/player_${_sharedCounter()}';
  MethodChannel? _channel;

  static int _c = 0;
  static int _sharedCounter() => ++_c;

  @override
  void initState() {
    super.initState();
    _channel = MethodChannel(_channelName);
    _channel!.setMethodCallHandler(_onNativeEvent);
  }

  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }

  Future<dynamic> _onNativeEvent(MethodCall call) async {
    switch (call.method) {
      case 'onReady':
        widget.onDiagnostics?.call(
            'page', 'READY view created${call.arguments != null ? ' url=${call.arguments}' : ''}');
        break;
      case 'onPageStarted':
        widget.onLoadChanged(true);
        widget.onDiagnostics?.call('page', call.arguments?.toString() ?? '');
        break;
      case 'onPageFinished':
        widget.onLoadChanged(false);
        widget.onDiagnostics?.call('page', call.arguments?.toString() ?? '');
        break;
      case 'onRequest':
        widget.onDiagnostics?.call('req', call.arguments?.toString() ?? '');
        break;
      case 'onPageError':
        widget.onLoadChanged(false);
        final map = call.arguments as Map<dynamic, dynamic>? ?? const {};
        final code = map['code']?.toString() ?? '';
        final url = map['url']?.toString() ?? '';
        final desc = map['desc']?.toString() ?? '';
        widget.onDiagnostics
            ?.call('error', '$code | $url${desc.isNotEmpty ? ' | $desc' : ''}');
        break;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AndroidView(
      viewType: _kViewType,
      key: ValueKey(_channelName),
      creationParams: <String, Object?>{
        'url': widget.url,
        'channel': _channelName,
      },
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: (_) {},
    );
  }
}
