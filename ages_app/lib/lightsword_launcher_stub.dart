import 'package:url_launcher/url_launcher.dart';

Future<bool> launchLightSwordReference(String reference, Uri uri) {
  return launchUrl(uri, webOnlyWindowName: '_blank');
}