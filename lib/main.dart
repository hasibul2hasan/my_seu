import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart';

void main() {
  // Ensure that the framework is initialized
  WidgetsFlutterBinding.ensureInitialized();

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
  Color _appBarColor = const Color.fromRGBO(15, 23, 42, 1);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(_handleTabSelection);
  }

  void _handleTabSelection() {
    setState(() {
      switch (_tabController.index) {
        case 0:
          _appBarColor = const Color.fromRGBO(15, 23, 42, 1); // UMS
          break;
        case 1:
          _appBarColor = const Color.fromARGB(255, 255, 255, 255); // Classroom
          break;
        case 2:
          _appBarColor = const Color.fromARGB(255, 255, 255, 255); // Mail
          break;
        case 3:
          _appBarColor = const Color.fromRGBO(33, 150, 243, 1); // Map
          break;
        case 4:
          _appBarColor = const Color.fromRGBO(156, 39, 176, 1); // Chat
          break;
        case 5:
          _appBarColor = const Color.fromRGBO(255, 193, 7, 1); // Help
          break;
      }

      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: _appBarColor, // Status bar color
        statusBarIconBrightness: Brightness.light, // Light icons on status bar
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: _appBarColor,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(20.0), // Adjust as needed
            child: TabBar(
              controller: _tabController,
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(
                  color: const Color.fromARGB(
                      255, 126, 0, 0), // Set your desired color here
                  width: 2.0, // Set the thickness of the underline
                ),
              ),
              tabs: [
                //Tab(icon: Icon(Icons.web), text: 'SEU UMS'),
                Tab(
                  icon: Image.asset("assets/TabBarLogo/ums.png"),
                  //text: 'ClassRoom'
                ),
                Tab(
                  icon: Image.asset("assets/TabBarLogo/google_classroom.png"),
                  // text: 'ClassRoom',
                ),
                Tab(icon: Icon(Icons.mail), text: 'Note'),
                Tab(icon: Icon(Icons.map), text: 'Map'),
                Tab(icon: Icon(Icons.chat), text: 'Chat'),
                Tab(icon: Icon(Icons.help), text: 'Help'),
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
            KeepTab(),
            MapTab(),
            ChatTab(),
            HelpTab(),
          ],
        ),
      ),
    );
  }
}

// UMS tab here
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
            child: const Icon(Icons.refresh, color: Colors.white),
            backgroundColor: const Color.fromRGBO(15, 23, 42, 1),
          ),
        ),
      ],
    );
  }
}

// Classroom tab here
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
            child: const Icon(Icons.refresh, color: Colors.black),
            backgroundColor: const Color.fromARGB(255, 255, 255, 255),
          ),
        ),
      ],
    );
  }
}

// Note tab here
class KeepTab extends StatefulWidget {
  const KeepTab({Key? key}) : super(key: key);

  @override
  _KeepTabState createState() => _KeepTabState();
}

class _KeepTabState extends State<KeepTab> with AutomaticKeepAliveClientMixin {
  late WebViewController _webViewController;
  String initialUrl = 'https://keep.google.com/';

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
            child: const Icon(Icons.refresh, color: Colors.black),
            backgroundColor: const Color.fromARGB(255, 255, 255, 255),
          ),
        ),
      ],
    );
  }
}

// Map tab here
class MapTab extends StatelessWidget {
  const MapTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Map Tab',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}

// Chat tab here
class ChatTab extends StatelessWidget {
  const ChatTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Chat Tab',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}

// Help tab here
class HelpTab extends StatelessWidget {
  const HelpTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Help Tab',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}
