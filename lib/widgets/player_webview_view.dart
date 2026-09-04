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
  });

  final String url;
  final ValueChanged<bool> onLoadChanged;

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
      case 'onPageStarted':
        widget.onLoadChanged(true);
        break;
      case 'onPageFinished':
      case 'onPageError':
        widget.onLoadChanged(false);
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
