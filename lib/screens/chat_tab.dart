import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'package:ums/auth/auth_service.dart';

class ChatTab extends StatefulWidget {
  const ChatTab({Key? key}) : super(key: key);

  @override
  _ChatTabState createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // final FirebaseAuth _auth = FirebaseAuth.instance;
  // bool _isSigningIn = false; // For showing a loading indicator

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      body: Center(
        child: const Text('Comming Soon'),
      ),
    );
  }

  // @override
  // Widget build(BuildContext context) {
  //   super.build(context);

  //   return Scaffold(
  //     appBar: AppBar(
  //       title: const Text('Chat Tab'),
  //     ),
  //     body: Center(
  //       child: _isSigningIn
  //           ? const CircularProgressIndicator()
  //           : ElevatedButton(
  //               onPressed: _signInWithGoogle,
  //               child: const Text('Sign in with Google'),
  //             ),
  //     ),
  //   );
  // }

  // Future<void> _signInWithGoogle() async {
  //   setState(() {
  //     _isSigningIn = true;
  //   });

  //   try {
  //     User? user = await AuthService().signInWithGoogle();
  //     if (user != null) {
  //       // Navigate to another screen, like a chat screen
  //       Navigator.pushReplacementNamed(context, '/chat_screen');
  //     }
  //hy
  //   } catch (e) {
  //     // Show an error message
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Sign in failed: $e')),
  //     );
  //   } finally {
  //     setState(() {
  //       _isSigningIn = false;
  //     });
  //   }
  // }
}
