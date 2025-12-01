import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'package:ums/auth/auth_service.dart';
import 'package:ums/screens/mid_exam.dart';

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

  void _navigateToPage(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Tab'),
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Select an Option',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () => _navigateToPage( ExamScheduleExtractorPage()),
                icon: const Icon(Icons.person),
                label: const Text('Exam Schedule'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 15),
              ElevatedButton.icon(
                onPressed: () => _navigateToPage( ExamScheduleExtractorPage()),
                icon: const Icon(Icons.message),
                label: const Text('Messages'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 15),
              ElevatedButton.icon(
                onPressed: () => _navigateToPage( ExamScheduleExtractorPage()),
                icon: const Icon(Icons.notifications),
                label: const Text('Notifications'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 15),
              ElevatedButton.icon(
                onPressed: () => _navigateToPage( ExamScheduleExtractorPage()),
                icon: const Icon(Icons.settings),
                label: const Text('Settings'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
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
