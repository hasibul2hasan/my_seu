import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io' show Platform;

import '../services/web_iframe_stub.dart'
    if (dart.library.html) '../services/web_iframe_web.dart';
import '../app_config.dart';

// SEU campus coordinates
const _kSeuLat = 23.7693568;
const _kSeuLng = 90.4048154;

// The Maps Embed API URL is explicitly designed for iframes — no SAMEORIGIN block
String _embedUrl({double? userLat, double? userLng}) {
  const key = AppConfig.mapsApiKey;
  if (userLat != null && userLng != null) {
    // Show directions from user location to SEU
    return 'https://www.google.com/maps/embed/v1/directions'
        '?key=$key'
        '&origin=$userLat,$userLng'
        '&destination=$_kSeuLat,$_kSeuLng'
        '&mode=driving';
  }
  // Show SEU campus pinned on map
  return 'https://www.google.com/maps/embed/v1/place'
      '?key=$key'
      '&q=Southeast+University,Dhaka'
      '&center=$_kSeuLat,$_kSeuLng'
      '&zoom=17';
}

const _kNativeUrl =
    'https://www.google.com/maps/place/Southeast+University,+251%2FA+Tejgaon+I%2FA,+Dhaka+1208';

class MapTab extends StatefulWidget {
  const MapTab({super.key});

  @override
  _MapTabState createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> with AutomaticKeepAliveClientMixin {
  // ── Web state ──────────────────────────────────────────────────────────────
  String _webViewType = 'map-iframe-campus'; // updated when directions load
  String _currentEmbedUrl = _embedUrl();
  bool _webLocLoading = false;

  // ── Native state ───────────────────────────────────────────────────────────
  WebViewController? _webViewController;
  bool isLoading = true;
  bool hasError = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      registerIframeView(_webViewType, _currentEmbedUrl);
      return;
    }
    _initNativeWebView(_kNativeUrl);
    _requestLocationPermission();
  }

  // ── Native WebView ─────────────────────────────────────────────────────────
  void _initNativeWebView(String url) {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() { isLoading = true; hasError = false; }),
        onPageFinished: (_) {
          setState(() => isLoading = false);
          _webViewController?.runJavaScript(
            "document.querySelector('meta[name=viewport]')?.setAttribute('content',"
            "'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no');",
          );
        },
        onWebResourceError: (_) => setState(() { isLoading = false; hasError = true; }),
      ))
      ..loadRequest(Uri.parse(url));
  }

  Future<void> _requestLocationPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.location.request();
      if (status.isGranted) _getCurrentLocationNative();
    } else if (Platform.isIOS) {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.whileInUse || perm == LocationPermission.always) {
        _getCurrentLocationNative();
      }
    }
  }

  Future<void> _getCurrentLocationNative() async {
    try {
      const settings = LocationSettings(accuracy: LocationAccuracy.high);
      final pos = await Geolocator.getCurrentPosition(locationSettings: settings);
      final dirUrl =
          'https://www.google.com/maps/dir/?api=1'
          '&origin=${pos.latitude},${pos.longitude}'
          '&destination=$_kSeuLat,$_kSeuLng';
      _webViewController?.loadRequest(Uri.parse(dirUrl));
    } catch (_) {}
  }

  Future<void> _reloadNative() async {
    setState(() { isLoading = true; hasError = false; });
    await _webViewController?.reload();
  }

  Future<bool> _onWillPop() async {
    if (await _webViewController?.canGoBack() ?? false) {
      _webViewController?.goBack();
      return false;
    }
    return true;
  }

  // ── Web: get location via browser geolocation ──────────────────────────────
  Future<void> _getWebLocation() async {
    setState(() => _webLocLoading = true);
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final newUrl = _embedUrl(userLat: pos.latitude, userLng: pos.longitude);
      const newViewType = 'map-iframe-directions';
      registerIframeView(newViewType, newUrl);
      setState(() {
        _webViewType = newViewType;
        _currentEmbedUrl = newUrl;
        _webLocLoading = false;
      });
    } catch (_) {
      setState(() => _webLocLoading = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (kIsWeb) return _buildWebMap();
    return _buildNativeMap();
  }

  Widget _buildWebMap() {
    final hasKey = AppConfig.hasMapsKey;

    if (!hasKey) {
      // Show a clear call-to-action when key isn't set yet
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.map_outlined, size: 64, color: Colors.teal[300]),
              const SizedBox(height: 20),
              const Text(
                'Maps API key not configured',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Add your MAPS_EMBED_API_KEY to .env and start the app with:\n./run.sh -d chrome',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        // The iframe map
        buildIframeView(_webViewType, _currentEmbedUrl),

        // "Get directions" FAB
        Positioned(
          bottom: 16,
          right: 16,
          child: _webLocLoading
              ? const CircularProgressIndicator()
              : FloatingActionButton.extended(
                  onPressed: _getWebLocation,
                  backgroundColor: const Color.fromARGB(255, 0, 150, 136),
                  icon: const Icon(Icons.my_location, color: Colors.white),
                  label: const Text(
                    'Directions to SEU',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildNativeMap() {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Stack(
        children: [
          if (_webViewController != null)
            WebViewWidget(controller: _webViewController!),
          if (isLoading)
            const Center(child: CircularProgressIndicator()),
          if (hasError)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to load map.',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _reloadNative,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: _reloadNative,
              backgroundColor: const Color.fromARGB(255, 0, 150, 136),
              child: const Icon(Icons.refresh, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
