import 'dart:async';
import 'dart:typed_data';
import 'dart:html' as html;
// ignore: uri_does_not_exist
import 'dart:js' as js;
// ignore: uri_does_not_exist
import 'dart:js_util' as js_util;

const _tesseractScriptUrls = <String>[
  'https://cdn.jsdelivr.net/npm/tesseract.js@4/dist/tesseract.min.js',
  'https://unpkg.com/tesseract.js@4/dist/tesseract.min.js',
  'https://cdnjs.cloudflare.com/ajax/libs/tesseract.js/4.0.2/tesseract.min.js',
];

Future<void> _ensureTesseractLoaded({Duration timeout = const Duration(seconds: 60)}) async {
  if (js_util.hasProperty(js.context, 'Tesseract')) return;

  // If a script tag already exists, wait for it to finish loading
  final existing = html.document.querySelectorAll('script').where((el) {
    final src = (el as html.ScriptElement).src;
    return src.contains('tesseract');
  }).cast<html.ScriptElement>().toList();
  if (existing.isNotEmpty) {
    // Give it a short window to load
    final completer = Completer<void>();
    final timer = Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.completeError('Timed out loading Tesseract.js');
      }
    });
    // Poll until available or timeout
    void check() {
      if (js_util.hasProperty(js.context, 'Tesseract')) {
        if (!completer.isCompleted) completer.complete();
        timer.cancel();
      } else {
        html.window.requestAnimationFrame((_) => check());
      }
    }
    check();
    await completer.future;
    return;
  }

  // Try multiple CDNs sequentially
  Object? lastError;
  for (final url in _tesseractScriptUrls) {
    final script = html.ScriptElement()
      ..type = 'application/javascript'
      ..src = url
      ..crossOrigin = 'anonymous';
    final completer = Completer<void>();
    late StreamSubscription loadSub;
    late StreamSubscription errorSub;
    loadSub = script.onLoad.listen((_) {
      loadSub.cancel();
      errorSub.cancel();
      if (!completer.isCompleted) completer.complete();
    });
    errorSub = script.onError.listen((e) {
      loadSub.cancel();
      errorSub.cancel();
      if (!completer.isCompleted) {
        completer.completeError('Failed to load Tesseract.js from $url');
      }
    });
    html.document.head?.append(script);

    try {
      await completer.future.timeout(timeout, onTimeout: () {
        throw 'Timed out loading Tesseract.js from $url';
      });
      // Confirm global available
      if (js_util.hasProperty(js.context, 'Tesseract')) {
        return;
      } else {
        lastError = 'Tesseract loaded from $url but global not found';
      }
    } catch (e) {
      lastError = e;
      // Remove failed script tag before trying next
      script.remove();
      continue;
    }
  }
  throw 'Unable to load Tesseract.js. Last error: $lastError';
}

Future<String> webRecognizeImageBytes(Uint8List bytes) async {
  await _ensureTesseractLoaded();
  final tesseract = js.context['Tesseract'];
  if (tesseract == null) {
    throw 'Tesseract.js is not loaded on the page.';
  }

  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  try {
    // Create an isolated worker for recognition
    final worker = js_util.callMethod(tesseract, 'createWorker', [js_util.jsify({})]);
    await js_util.promiseToFuture(js_util.callMethod(worker, 'load', []));
    await js_util.promiseToFuture(js_util.callMethod(worker, 'loadLanguage', ['eng']));
    await js_util.promiseToFuture(js_util.callMethod(worker, 'initialize', ['eng']));

    final result = await js_util.promiseToFuture<Object?>(
      js_util.callMethod(worker, 'recognize', [url]),
    );
    final data = js_util.getProperty<Object?>(result as Object, 'data');
    final text = js_util.getProperty<String?>(data as Object, 'text');

    await js_util.promiseToFuture(js_util.callMethod(worker, 'terminate', []));
    return text ?? '';
  } finally {
    html.Url.revokeObjectUrl(url);
  }
}
