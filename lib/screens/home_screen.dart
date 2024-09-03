import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'ums_tab.dart';
import 'classroom_tab.dart';
import 'keep_tab.dart';
import 'map_tab.dart';
import 'chat_tab.dart';
// import 'help_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  Color _appBarColor = const Color.fromRGBO(15, 23, 42, 1);
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _handleTabSelection();
  }

  void _handleTabSelection() {
    setState(() {
      switch (_selectedIndex) {
        case 0:
          _appBarColor = const Color.fromRGBO(15, 23, 42, 1); // UMS
          SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
            statusBarColor: _appBarColor,
            statusBarIconBrightness: Brightness.light, // White icons
          ));
          break;
        case 1:
          _appBarColor = const Color.fromARGB(255, 255, 255, 255); // Classroom
          SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
            statusBarColor: _appBarColor,
            statusBarIconBrightness: Brightness.dark, // Dark icons
          ));
          break;
        case 2:
          _appBarColor = const Color.fromARGB(255, 255, 255, 255); // Mail
          SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
            statusBarColor: _appBarColor,
            statusBarIconBrightness: Brightness.dark, // Dark icons
          ));
          break;
        case 3:
          _appBarColor = const Color.fromARGB(255, 255, 255, 255); // Map
          SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
            statusBarColor: _appBarColor,
            statusBarIconBrightness: Brightness.dark, // Dark icons
          ));
          break;
        case 4:
          _appBarColor = const Color.fromARGB(255, 255, 255, 255); // Chat
          SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
            statusBarColor: _appBarColor,
            statusBarIconBrightness: Brightness.dark, // Dark icons
          ));
          break;
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.jumpToPage(index);
    _handleTabSelection();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: const [
            UmsTab(),
            ClassroomTab(),
            KeepTab(),
            MapTab(),
            ChatTab(),
            // HelpTab(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: _appBarColor,
        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
        child: GNav(
          gap: 8,
          backgroundColor: _appBarColor,
          color: Colors.grey[400],
          activeColor: Colors.black,
          tabBackgroundColor: Colors.grey[100]!,
          padding: const EdgeInsets.all(16),
          onTabChange: _onItemTapped,
          selectedIndex: _selectedIndex,
          tabs: [
            GButton(
              icon: Icons.school, // This will be replaced by the image
              text: 'UMS',
              leading: Image.asset(
                'assets/TabBarLogo/seuinver.png', // Path to your image
                width: 24, // Width of the image
                height: 24, // Height of the image
                color: _selectedIndex == 0
                    ? Colors.black
                    : Colors.grey, // Optional: to tint the image
              ),
            ),
            GButton(
              icon: Icons.school, // This will be replaced by the image
              text: 'Classroom',
              leading: Image.asset(
                'assets/TabBarLogo/google_classroom_white.png', // Path to your image
                width: 24, // Width of the image
                height: 24, // Height of the image
                color: _selectedIndex == 0
                    ? Colors.grey
                    : Colors.grey, // Optional: to tint the image
              ),
            ),
            const GButton(
              icon: Icons.add,
              text: 'Add',
            ),
            const GButton(
              icon: Icons.location_on,
              text: 'Map',
            ),
            const GButton(
              icon: Icons.chat,
              text: 'Chat',
            ),
          ],
        ),
      ),
    );
  }
}
