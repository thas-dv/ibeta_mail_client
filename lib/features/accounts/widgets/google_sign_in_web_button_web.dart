import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart' as google_web;

Widget buildGoogleSignInWebButton({
  required double width,
  required double height,
}) {
  return google_web.renderButton(
    configuration: google_web.GSIButtonConfiguration(
      theme: google_web.GSIButtonTheme.filledBlue,
      shape: google_web.GSIButtonShape.rectangular,
      size: google_web.GSIButtonSize.large,
      text: google_web.GSIButtonText.continueWith,
   
    ),
  );
}
