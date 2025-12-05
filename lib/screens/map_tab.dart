import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:permission_handler/permission_handler.dart'; // For Android runtime permissions
import 'package:geolocator/geolocator.dart'; // For iOS location permissions
import 'dart:io' show Platform;
import 'package:url_launcher/url_launcher.dart';

class MapTab extends StatefulWidget {
  const MapTab({super.key});

  @override
  _MapTabState createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> with AutomaticKeepAliveClientMixin {
  WebViewController? _webViewController;
  String initialUrl =
      'https://www.google.com/maps/place/Southeast+University,+251%2FA+Tejgaon+I%2FA,+Dhaka+1208';
  bool isLoading = true; // For the loading indicator
  bool hasError = false; // For displaying an error message

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _initializeWebView();
      _requestLocationPermission();
    }
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              isLoading = true;
              hasError = false;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              isLoading = false;
            });
            _webViewController?.runJavaScript(
              "document.querySelector('meta[name=viewport]').setAttribute('content', 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no');",
            );
          },
          onWebResourceError: (error) {
            setState(() {
              isLoading = false;
              hasError = true;
            });
            print("WebView resource error: ${error.description}");
          },
        ),
      )
      ..loadRequest(Uri.parse(initialUrl));
  }

  Future<void> _requestLocationPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.location.request();
      if (status.isDenied) {
        print("Location permission denied on Android");
      } else if (status.isPermanentlyDenied) {
        openAppSettings();
      } else if (status.isGranted) {
        _getCurrentLocation();
      }
    } else if (Platform.isIOS) {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        _getCurrentLocation();
      } else {
        print("Location permission denied on iOS");
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      String currentLocationUrl =
          'https://www.google.com/maps/dir/?api=1&origin=${position.latitude},${position.longitude}&destination=23.7693568,90.4048154'; // Example destination coordinates
      _webViewController?.loadRequest(Uri.parse(currentLocationUrl));
    } catch (e) {
      print("Error getting current location: $e");
    }
  }

  Future<void> _reloadWebView() async {
    if (_webViewController != null) {
      setState(() {
        isLoading = true; // Show loading indicator when reloading
        hasError = false; // Reset error state
      });
      await _webViewController!.reload();
    } else {
      print("WebViewController is not initialized");
    }
  }

  Future<bool> _onWillPop() async {
    if (await _webViewController?.canGoBack() ?? false) {
      _webViewController?.goBack();
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
              InkWell(
                onTap: () async {
                  final uri = Uri.parse(initialUrl);
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                borderRadius: BorderRadius.circular(12),
                child: const FlutterLogo(size: 64),
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

    return WillPopScope(
      onWillPop: _onWillPop, // Ensure onWillPop is correctly set here
      child: Stack(
        children: [
          if (_webViewController != null)
            WebViewWidget(controller: _webViewController!),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(), // Loading indicator
            ),
          if (hasError)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    "Failed to load map.",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _reloadWebView,
                    child: const Text("Retry"),
                  ),
                ],
              ),
            ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: _reloadWebView,
              backgroundColor: const Color.fromARGB(255, 0, 150, 136),
              child: const Icon(Icons.refresh, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
