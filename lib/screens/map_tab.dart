import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:permission_handler/permission_handler.dart'; // For Android runtime permissions
import 'package:geolocator/geolocator.dart'; // For iOS location permissions
import 'dart:io' show Platform;

class MapTab extends StatefulWidget {
  const MapTab({Key? key}) : super(key: key);

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
    _requestLocationPermission();
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
      if (_webViewController != null) {
        await _webViewController!.loadUrl(currentLocationUrl);
      } else {
        setState(() {
          initialUrl = currentLocationUrl;
        });
      }
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
            if (initialUrl.isNotEmpty && _webViewController != null) {
              _webViewController!.loadUrl(initialUrl);
            }
          },
          onPageStarted: (String url) {
            setState(() {
              isLoading = true; // Start loading indicator
              hasError = false; // Reset error state
            });
          },
          onPageFinished: (String url) {
            setState(() {
              isLoading = false; // Stop loading indicator
            });
            _webViewController?.runJavascript(
                "document.querySelector('meta[name=viewport]').setAttribute('content', 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no');");
          },
          onWebResourceError: (error) {
            setState(() {
              isLoading = false; // Stop loading indicator
              hasError = true; // Set error state
            });
            print("WebView resource error: ${error.description}");
          },
        ),
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
            child: const Icon(Icons.refresh, color: Colors.white),
            backgroundColor: const Color.fromARGB(255, 0, 150, 136),
          ),
        ),
      ],
    );
  }
}
