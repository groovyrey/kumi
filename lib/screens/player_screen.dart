import 'package:flutter/material.dart';

import '../config.dart';
import '../theme/app_theme.dart';
import '../widgets/player_webview_view.dart';

/// A Netflix-style immersive full-screen player backed by a native ad-filtered
/// WebView. The default provider is autoplayed on entry; providers can be
/// swapped while watching (recreating the native view for the new source).
///
/// Taps on the video surface are left to the embed's own player controls; a
/// persistent top bar (back + title) and bottom provider switcher stay
/// available so the app never traps the user.
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
  late int _index;
  late String _url;
  late int _loadKey;
  bool _loading = true;
  bool _showDiag = false;
  final List<String> _diag = [];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _url = _urlForIndex(_index);
    _loadKey = 0;
  }

  void _pushDiag(String kind, String message) {
    if (!mounted) return;
    final label = switch (kind) {
      'error' => 'ERR',
      'req' => 'REQ',
      _ => 'PAGE',
    };
    setState(() {
      _diag.add('$label: $message');
      if (_diag.length > 40) _diag.removeAt(0);
    });
  }

  String _urlForIndex(int index) {
    final src = EmbedSources.sources[index];
    return src.$2(id: widget.id, media: widget.media);
  }

  void _switchSource(int index) {
    if (index == _index) return;
    setState(() {
      _index = index;
      _url = _urlForIndex(index);
      _loadKey++; // force a fresh native view for the new source
      _loading = true;
      _diag.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
                  child: PlayerWebView(
                    key: ValueKey(_loadKey),
                    url: _url,
                    onLoadChanged: (loading) {
                      if (mounted && loading != _loading) {
                        setState(() => _loading = loading);
                      }
                    },
                    onDiagnostics: _pushDiag,
                  ),
            ),
            if (_loading)
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            if (_showDiag) Positioned.fill(child: _diagOverlay(context)),
            Positioned(top: 0, left: 0, right: 0, child: _topBar(context)),
            Positioned(left: 0, right: 0, bottom: 0, child: _bottomBar(context)),
          ],
        ),
      ),
    );
  }

  Widget _diagOverlay(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      padding: const EdgeInsets.fromLTRB(16, 70, 16, 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Network diagnostics',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _showDiag = false),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                ),
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Close'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _diag.isEmpty
                ? const Center(
                    child: Text(
                      'Waiting for requests...',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                : ListView.builder(
                    itemCount: _diag.length,
                    itemBuilder: (_, i) {
                      final isErr = _diag[i].startsWith('ERR');
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          _diag[i],
                          style: TextStyle(
                            color: isErr ? Colors.redAccent : Colors.lightBlueAccent,
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.8),
            Colors.black.withValues(alpha: 0.0),
          ],
        ),
      ),
      padding: const EdgeInsets.only(left: 4, right: 16, top: 6, bottom: 20),
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
          IconButton(
            onPressed: () => setState(() => _showDiag = !_showDiag),
            icon: const Icon(Icons.bug_report_outlined,
                color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.8),
            Colors.black.withValues(alpha: 0.0),
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
