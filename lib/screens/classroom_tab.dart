import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/web_iframe_stub.dart'
    if (dart.library.html) '../services/web_iframe_web.dart';

class ClassroomTab extends StatefulWidget {
  const ClassroomTab({super.key});

  @override
  _ClassroomTabState createState() => _ClassroomTabState();
}

class _ClassroomTabState extends State<ClassroomTab>
    with AutomaticKeepAliveClientMixin {
  static const _viewType = 'classroom-iframe';
  static const _url =
      'https://accounts.google.com/ServiceLogin?continue=https%3A%2F%2Fclassroom.google.com&passive=true';

  WebViewController? _webViewController;
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      // Pre-register the iframe so it's ready when the widget builds.
      registerIframeView(_viewType, _url);
      return;
    }
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (url) {
            setState(() => _isLoading = false);
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
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: _reloadWebView,
              backgroundColor: const Color.fromARGB(255, 66, 133, 244),
              child: const Icon(Icons.refresh, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
