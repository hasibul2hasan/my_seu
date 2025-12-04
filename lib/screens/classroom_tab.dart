import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ClassroomTab extends StatefulWidget {
  const ClassroomTab({Key? key}) : super(key: key);

  @override
  _ClassroomTabState createState() => _ClassroomTabState();
}

class _ClassroomTabState extends State<ClassroomTab>
    with AutomaticKeepAliveClientMixin {
  WebViewController? _webViewController;
  String initialUrl =
      'https://accounts.google.com/ServiceLogin?continue=https%3A%2F%2Fclassroom.google.com&passive=true';

  bool _isLoading = true; // Tracks the loading state

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Avoid initializing WebView on web where there's no platform implementation
    if (kIsWeb) return;
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            _webViewController?.runJavaScript(
              "document.querySelector('meta[name=viewport]').setAttribute('content', 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no');",
            );
          },
        ),
      )
      ..loadRequest(Uri.parse(initialUrl));
  }

  Future<void> _reloadWebView() async {
    await _webViewController?.reload();
  }

  Future<bool> _onWillPop() async {
    if (_webViewController != null && await _webViewController!.canGoBack()) {
      _webViewController!.goBack();
      return false; // Prevent the app from closing.
    }
    return true; // Allow the app to close if there's no back history.
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // On web, show a placeholder page instead of WebView
    if (kIsWeb) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Download the app to use this feature',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              // Tappable logo that redirects to the website
              InkWell(
                onTap: () async {
                  final uri = Uri.parse(initialUrl);
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  // Using FlutterLogo as a safe placeholder if asset logo name is unknown
                  child: const FlutterLogo(size: 64),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () async {
                  final uri = Uri.parse(initialUrl);
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                child: const Text('Open in browser'),
              ),
            ],
          ),
        ),
      );
    }

    // Mobile/desktop native: show the WebView
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Stack(
        children: [
          if (_webViewController != null)
            WebViewWidget(controller: _webViewController!),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: _reloadWebView,
              child: const Icon(Icons.refresh, color: Colors.white),
              backgroundColor: const Color.fromARGB(255, 66, 133, 244),
            ),
          ),
        ],
      ),
    );
  }
}
