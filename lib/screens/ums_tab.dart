import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../services/web_iframe_stub.dart'
    if (dart.library.html) '../services/web_iframe_web.dart';
import '../app_config.dart';

class UmsTab extends StatefulWidget {
  const UmsTab({super.key});

  @override
  _UmsTabState createState() => _UmsTabState();
}

class _UmsTabState extends State<UmsTab> with AutomaticKeepAliveClientMixin {
  static const _viewType = 'ums-iframe';
  // Uses the Cloudflare Worker proxy URL when configured, falls back to direct URL
  static String get _url => AppConfig.umsProxyUrl;

  WebViewController? _webViewController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      registerIframeView(_viewType, _url);
      return;
    }
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            _webViewController?.runJavaScript(
              "document.querySelector('meta[name=viewport]')?.setAttribute('content',"
              "'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no');",
            );
          },
        ),
      )
      ..loadRequest(Uri.parse(_url));
  }

  Future<void> _reloadWebView() async {
    await _webViewController?.reload();
  }

  Future<bool> _onWillPop() async {
    if (_webViewController != null && await _webViewController!.canGoBack()) {
      _webViewController!.goBack();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // ── Web: render an iframe ──────────────────────────────────────────────
    if (kIsWeb) {
      return buildIframeView(_viewType, _url);
    }

    // ── Native mobile / desktop: render WebViewWidget ─────────────────────
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Stack(
        children: [
          if (_webViewController != null)
            WebViewWidget(controller: _webViewController!),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: _reloadWebView,
              backgroundColor: const Color.fromRGBO(15, 23, 42, 1),
              child: const Icon(Icons.refresh, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
