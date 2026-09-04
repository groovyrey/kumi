import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../theme/app_theme.dart';

/// An embeddable webview player. Rebuild it with a different [url] to swap
/// the active source. Keeps a single controller so playback state persists.
class PlayerView extends StatefulWidget {
  const PlayerView({super.key, required this.url});

  final String url;

  @override
  State<PlayerView> createState() => _PlayerViewState();
}

class _PlayerViewState extends State<PlayerView> {
  late WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = _buildController(widget.url);
  }

  @override
  void didUpdateWidget(PlayerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      setState(() => _loading = true);
      _controller = _buildController(widget.url);
    }
  }

  WebViewController _buildController(String url) {
    return WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _loading = true),
          onPageFinished: (_) => setState(() => _loading = false),
        ),
      )
      ..loadRequest(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: WebViewWidget(controller: _controller)),
        if (_loading)
          const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
      ],
    );
  }
}

/// Full-screen player route, used when tapping a source.
class PlayerScreen extends StatelessWidget {
  const PlayerScreen({
    super.key,
    required this.title,
    required this.url,
  });

  final String title;
  final String url;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.appTextTheme.bodyLarge?.copyWith(
            color: Colors.white,
          ),
        ),
      ),
      body: PlayerView(url: url),
    );
  }
}
