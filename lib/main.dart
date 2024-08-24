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
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color.fromRGBO(15, 23, 42, 1),
          elevation: 0,
          // title: const Text(
          //   'WebView in TabBar',
          //   style: TextStyle(color: Colors.white),
          // ),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(20.0), // Adjust as needed
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(),
              tabs: const [
                Tab(icon: Icon(Icons.web), text: 'SEU UMS'),
                Tab(icon: Icon(Icons.home), text: 'ClassRoom'),
                Tab(icon: Icon(Icons.settings), text: 'Mail'),
                Tab(icon: Icon(Icons.settings), text: 'Map'),
                Tab(icon: Icon(Icons.settings), text: 'Chat'),
                Tab(icon: Icon(Icons.settings), text: 'Help'),
              ],
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,

          physics:
              const NeverScrollableScrollPhysics(), // Disable swipe gesture
          children: const [
            UmsTab(),
            ClassroomTab(),
            MailTab(),
            MapTab(),
            ChatTab(),
            HelpTab(),
          ],
        ),
      ),
    );
  }
}

//UMS tab here###########################################################################

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

// ClassRoom tab here ###########################################################################
class ClassroomTab extends StatefulWidget {
  const ClassroomTab({Key? key}) : super(key: key);

  @override
  _ClassroomTabState createState() => _ClassroomTabState();
}

class _ClassroomTabState extends State<ClassroomTab>
    with AutomaticKeepAliveClientMixin {
  late WebViewController _webViewController;
  String initialUrl = 'https://classroom.google.com/';

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

// Mail tab here ###########################################################################

class MailTab extends StatefulWidget {
  const MailTab({Key? key}) : super(key: key);

  @override
  _MailTabState createState() => _MailTabState();
}

class _MailTabState extends State<MailTab> with AutomaticKeepAliveClientMixin {
  late WebViewController _webViewController;
  String initialUrl = 'https://mail.google.com/mail/u/0/#inbox';

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

// Map tab here ###########################################################################

class MapTab extends StatelessWidget {
  const MapTab({Key? key}) : super(key: key);

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

// Chat tab here ###########################################################################

class ChatTab extends StatelessWidget {
  const ChatTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Chat Tab',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}

// Help tab here ###########################################################################

class HelpTab extends StatelessWidget {
  const HelpTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Help Tab',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}
