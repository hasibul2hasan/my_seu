import 'package:flutter/material.dart';
import 'package:google_sign_in_web/web_only.dart' as gsi_web;

Widget buildGoogleSignInButton({
  required VoidCallback onPressed,
  required bool loading,
}) {
  return Center(
    child: gsi_web.renderButton(
      configuration: gsi_web.GSIButtonConfiguration(
        type: gsi_web.GSIButtonType.standard,
        theme: gsi_web.GSIButtonTheme.outline,
        size: gsi_web.GSIButtonSize.large,
        text: gsi_web.GSIButtonText.signinWith,
        shape: gsi_web.GSIButtonShape.pill,
        logoAlignment: gsi_web.GSIButtonLogoAlignment.left,
      ),
    ),
  );
}
