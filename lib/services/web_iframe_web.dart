// Web-only implementation using dart:html + ui_web to embed an iframe.
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/widgets.dart';
// ignore: uri_does_not_exist
import 'dart:ui_web' as ui_web;

bool _registered(String viewType) => _registeredTypes.contains(viewType);
final _registeredTypes = <String>{};

void registerIframeView(String viewType, String url) {
  if (_registered(viewType)) return;
  _registeredTypes.add(viewType);
  // ignore: undefined_prefixed_name
  ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
    final iframe = html.IFrameElement()
      ..src = url
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..allow = 'fullscreen'
      ..setAttribute('allowfullscreen', 'true');
    return iframe;
  });
}

Widget buildIframeView(String viewType, String url) {
  registerIframeView(viewType, url);
  return HtmlElementView(viewType: viewType);
}

bool get iframeSupported => true;

