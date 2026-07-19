import 'dart:js_interop';

import 'package:url_launcher/url_launcher.dart';

@JS('window.agesPwa')
external _AgesPwa? get _agesPwa;

extension type _AgesPwa(JSObject _) implements JSObject {
  external JSPromise<JSBoolean> openLightSwordReference(
    String reference,
    String url,
  );
}

Future<bool> launchLightSwordReference(String reference, Uri uri) async {
  final agesPwa = _agesPwa;
  if (agesPwa != null) {
    try {
      final launched = await agesPwa
          .openLightSwordReference(reference, uri.toString())
          .toDart;
      return launched.toDart;
    } catch (_) {
      // Fall back to the normal URL launcher path below.
    }
  }

  return launchUrl(uri, webOnlyWindowName: '_blank');
}