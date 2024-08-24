import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart';

void main() {
  // Ensure that the framework is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set the status bar
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: const Color.fromRGBO(15, 23, 42, 1), // Status bar color
    statusBarIconBrightness: Brightness.light, // Light icons on status bar
  ));

  runApp(
    const MyApp(),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebView in TabBar'),
        backgroundColor: const Color.fromRGBO(15, 23, 42, 1),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.web), text: 'WebView'),
            Tab(icon: Icon(Icons.home), text: 'Home'),
            Tab(icon: Icon(Icons.settings), text: 'Settings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(), // Disable swipe gesture
        children: const [
          WebViewScreen(),
          HomeTab(),
          SettingsTab(),
        ],
      ),
    );
  }
}

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({Key? key}) : super(key: key);

  @override
  _WebViewScreenState createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen>
    with AutomaticKeepAliveClientMixin {
  late WebViewController _webViewController;
  String initialUrl = 'https://ums.seu.edu.bd/';

  @override
  bool get wantKeepAlive => true;

  Future<void> _reloadWebView() async {
    if (_webViewController != null) {
      await _webViewController.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(
        context); // Call super.build to ensure the keep-alive mechanism is applied

    return Stack(
      children: [
        WebView(
          initialUrl: initialUrl,
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
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: _reloadWebView,
            child: Icon(Icons.refresh),
            backgroundColor: const Color.fromRGBO(15, 23, 42, 1),
          ),
        ),
      ],
    );
  }
}

class HomeTab extends StatelessWidget {
  const HomeTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Home Tab',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}

class SettingsTab extends StatelessWidget {
  const SettingsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Settings Tab',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}
