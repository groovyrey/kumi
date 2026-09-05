import 'dart:async';

import 'package:webview_flutter/webview_flutter.dart';

/// Blocks the ad "click layer" that embed pages (CineSrc, PlayAPI, Peachify,
/// VidGod) lay over the video viewport. Everything runs inside the page: no
/// network requests are intercepted, so playback stays as reliable as the
/// plain webview_flutter player. Deliberately conservative — it only removes
/// elements that match known ad markers and never touches the player itself.
class EmbedAdGuard {
  EmbedAdGuard._();

  /// Host suffixes a top-level navigation is allowed to reach. Any other
  /// main-frame navigation is treated as an ad/redirect escape and prevented.
  static const List<String> allowedNavHostSuffixes = [
    // Embed origins.
    'cinesrc.st',
    'cineflix.st',
    'playapi.eu.cc',
    'peachify.top',
    'vidgod.net',
    // Video / manifest CDNs.
    'akamaized.net',
    'cloudfront.net',
    'amazonaws.com',
    'fastly.net',
    'b-cdn.net',
    'cdn.dev',
    'googlevideo.com',
    'vimeocdn.com',
    'vimeo.com',
    'bitmovin.com',
  ];

  /// Conservative in-page ad-layer stripper.
  ///
  /// Removes iframes that load from a known ad network, plus elements whose
  /// id/class clearly mark them as ad layers (ad/banner/popup/interstitial) as
  /// long as they are not the player or player internals. A MutationObserver
  /// tears down anything the ad SDK re-injects; the periodic Dart ticker is a
  /// backstop for layers that attach without DOM re-insertion.
  static const String stripperScript = r'''
(function () {
  'use strict';
  var AD_HOSTS = [
    'doubleclick.net', 'googlesyndication.com', 'googleadservices.com',
    'adservice.google.com', '2mdn.net', 'pagead2.googlesyndication.com',
    'adsterra.com', 'popads.net', 'propellerads.com', 'exoclick.com',
    'juicyads.com', 'onclickads.net', 'trafficjunky.net', 'adnxs.com',
    'pubmatic.com', 'criteo.com', 'outbrain.com', 'taboola.com'
  ];
  var MARKER = /(^|[^\w-])(ad|ads|advert|adblock|adcontainer|banner|popup|interstitial)(?=[^\w-]|$)/i;

  function isAdHost(host) {
    for (var i = 0; i < AD_HOSTS.length; i++) {
      if (host === AD_HOSTS[i] || host.slice(-(AD_HOSTS[i].length + 1)) === '.' + AD_HOSTS[i]) {
        return true;
      }
    }
    return false;
  }

  function stripAdFrames() {
    var frames = document.querySelectorAll('iframe');
    for (var i = 0; i < frames.length; i++) {
      var src = frames[i].getAttribute('src') || '';
      if (!src) continue;
      var host = '';
      try {
        host = new URL(src, location.href).host.toLowerCase();
      } catch (e) { continue; }
      if (isAdHost(host)) frames[i].remove();
    }
  }

  function stripAdLayers() {
    var els = document.querySelectorAll(
      '[id*="ad"], [class*="ad"], [id*="banner"], [class*="banner"], ' +
      '[id*="popup"], [class*="popup"], [id*="interstitial"], [class*="interstitial"], ' +
      '[data-ad], [aria-label*="ad"], [aria-label*="Advertisement"], [role="dialog"]'
    );
    for (var i = 0; i < els.length; i++) {
      var el = els[i];
      if (el === document.body || el === document.documentElement) continue;
      if (el.tagName === 'VIDEO') continue;
      var label = (el.getAttribute('aria-label') || '').toLowerCase();
      var marked = MARKER.test(el.className || '') || MARKER.test(el.id || '') ||
        el.hasAttribute('data-ad') ||
        label.indexOf('advert') !== -1 || label.indexOf('advertisement') !== -1;
      if (!marked) continue;
      if (el.querySelector('video')) continue;
      if (el.parentNode) el.parentNode.removeChild(el);
    }
  }

  function strip() {
    try {
      stripAdFrames();
      stripAdLayers();
    } catch (e) { /* never break the page */ }
  }

  if (!window.__kumiAdGuard) {
    window.__kumiAdGuard = true;
    function installObserver() {
      var target = document.body || document.documentElement;
      if (!target) return;
      var obs = new MutationObserver(function () { strip(); });
      obs.observe(target, { childList: true, subtree: true });
    }
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', installObserver);
    } else {
      installObserver();
    }
  }
  strip();
})();
''';

  static Timer? _ticker;

  /// Runs the stripper immediately in [controller] (page start/finish hook).
  static void strip(WebViewController controller) {
    unawaited(controller.runJavaScript(stripperScript));
  }

  /// Starts a periodic backstop that re-runs the stripper inside [controller].
  static void attach(WebViewController controller) {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      unawaited(controller.runJavaScript(stripperScript));
    });
    strip(controller);
  }

  /// Stops the periodic backstop (call from the player's dispose).
  static void detach() {
    _ticker?.cancel();
    _ticker = null;
  }

  /// Prevents top-level navigations that leave the player into ad/redirect
  /// targets; in-frame navigations are always allowed.
  static NavigationDecision guardNavigation(NavigationRequest request) {
    if (!request.isForMainFrame) return NavigationDecision.navigate;
    final host = Uri.tryParse(request.url)?.host.toLowerCase();
    if (host == null || host.isEmpty) return NavigationDecision.navigate;
    final allowed = allowedNavHostSuffixes
        .any((suffix) => host == suffix || host.endsWith('.$suffix'));
    return allowed ? NavigationDecision.navigate : NavigationDecision.prevent;
  }
}