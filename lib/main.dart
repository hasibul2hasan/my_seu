import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart';

void main() {
  // Ensure that the framework is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set the status bar to be transparent
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

class WebViewScreen extends StatelessWidget {
  const WebViewScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: const WebView(
          initialUrl: 'https://ums.seu.edu.bd/',
          javascriptMode: JavascriptMode.unrestricted,
        ),
      ),
    );
  }
}
