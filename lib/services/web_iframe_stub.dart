// Stub for non-web platforms.
import 'package:flutter/widgets.dart';

Widget buildIframeView(String viewType, String url) {
  throw UnsupportedError('buildIframeView is only available on web.');
}

void registerIframeView(String viewType, String url) {
  throw UnsupportedError('registerIframeView is only available on web.');
}

bool get iframeSupported => false;
