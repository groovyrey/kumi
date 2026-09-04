import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Factory id registered natively in AndroidMainActivity (AdBlockWebViewFactory).
const _kViewType = 'adblock-webview';

/// A native, ad-filtered WebView. It renders with `AndroidView` and routes load
/// state back to [onLoadChanged] over a per-instance method channel.
class AdBlockPlayerView extends StatefulWidget {
  const AdBlockPlayerView({
    super.key,
    required this.url,
    required this.onLoadChanged,
  });

  final String url;
  final ValueChanged<bool> onLoadChanged;

  @override
  State<AdBlockPlayerView> createState() => _AdBlockPlayerViewState();
}

class _AdBlockPlayerViewState extends State<AdBlockPlayerView> {
  late final String _channelName = 'kumi/adblock_${_sharedCounter()}';
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
