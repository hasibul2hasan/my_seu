import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class UmsTab extends StatefulWidget {
  const UmsTab({Key? key}) : super(key: key);

  @override
  _UmsTabState createState() => _UmsTabState();
}

class _UmsTabState extends State<UmsTab> with AutomaticKeepAliveClientMixin {
  late WebViewController _webViewController;
  String initialUrl = 'https://ums.seu.edu.bd/';

  @override
  bool get wantKeepAlive => true;

  Future<void> _reloadWebView() async {
    await _webViewController.reload();
  }

  Future<bool> _onWillPop() async {
    if (await _webViewController.canGoBack()) {
      _webViewController.goBack();
      return false; // Prevent the app from closing.
    }
    return true; // Allow the app to close if there's no back history.
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Stack(
        children: [
          WebView(
            initialUrl: initialUrl,
            javascriptMode: JavascriptMode.unrestricted,
            onWebViewCreated: (WebViewController webViewController) {
              _webViewController = webViewController;
            },
            onPageFinished: (String url) {
              _webViewController.runJavascript(
                  "document.querySelector('meta[name=viewport]').setAttribute('content', 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no');");
            },
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: _reloadWebView,
              child: const Icon(Icons.refresh, color: Colors.white),
              backgroundColor: const Color.fromRGBO(15, 23, 42, 1),
            ),
          ),
        ],
      ),
    );
  }
}
