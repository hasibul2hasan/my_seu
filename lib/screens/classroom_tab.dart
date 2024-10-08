import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ClassroomTab extends StatefulWidget {
  const ClassroomTab({Key? key}) : super(key: key);

  @override
  _ClassroomTabState createState() => _ClassroomTabState();
}

class _ClassroomTabState extends State<ClassroomTab>
    with AutomaticKeepAliveClientMixin {
  late WebViewController _webViewController;
  String initialUrl =
      'https://accounts.google.com/ServiceLogin?continue=https%3A%2F%2Fclassroom.google.com&passive=true';

  bool _isLoading = true; // Tracks the loading state

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
            onPageStarted: (String url) {
              setState(() {
                _isLoading =
                    true; // Show loading indicator when page starts loading
              });
            },
            onPageFinished: (String url) {
              setState(() {
                _isLoading =
                    false; // Hide loading indicator when page finishes loading
              });
              _webViewController.runJavascript(
                  "document.querySelector('meta[name=viewport]').setAttribute('content', 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no');");
            },
          ),
          // Show the loading indicator if the page is still loading
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
