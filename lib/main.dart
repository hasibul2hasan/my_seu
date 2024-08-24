import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart';

void main() {
  // Ensure that the framework is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set the status bar
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor:
        const Color.fromRGBO(15, 23, 42, 1), // Transparent status bar
    statusBarIconBrightness: Brightness.light, // Light icons on status bar
  ));

  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WebViewScreen(),
    ),
  );
}

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({Key? key}) : super(key: key);

  @override
  _WebViewScreenState createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late WebViewController _webViewController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: WebView(
          initialUrl: 'https://ums.seu.edu.bd/',
          javascriptMode: JavascriptMode.unrestricted,
          onWebViewCreated: (WebViewController webViewController) {
            _webViewController = webViewController;
          },
          onPageFinished: (String url) {
            // Inject JavaScript to disable zooming
            _webViewController.runJavascript(
                "document.querySelector('meta[name=viewport]').setAttribute('content', 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no');");
          },
        ),
      ),
    );
  }
}
