import 'package:flutter/material.dart';

Widget buildGoogleSignInButton({
  required VoidCallback onPressed,
  required bool loading,
}) {
  return SizedBox(
    width: double.infinity,
    height: 50,
    child: FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF1E8238),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: loading ? null : onPressed,
      icon: loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.login_rounded),
      label: Text(
        loading ? 'Connecting...' : 'Sign in with Google',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
  );
}
