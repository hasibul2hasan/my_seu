import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MapTab extends StatefulWidget {
  const MapTab({Key? key}) : super(key: key);

  @override
  _MapTabState createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> with AutomaticKeepAliveClientMixin {
  late WebViewController _webViewController;
  String initialUrl =
      'https://www.google.com/maps/place/Southeast+University,+251%2FA+Tejgaon+I%2FA,+Dhaka+1208/@23.7691563,90.4050302,17z/data=!4m6!3m5!1s0x3755c70e4508a1f7:0x4e6fd719b838721!8m2!3d23.7693568!4d90.4048154!16s%2Fm%2F027nclr';

  @override
  bool get wantKeepAlive => true;

  Future<void> _reloadWebView() async {
    if (_webViewController != null) {
      await _webViewController.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Stack(
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
            backgroundColor: const Color.fromARGB(255, 0, 150, 136),
          ),
        ),
      ],
    );
  }
}
