import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ums_tab.dart';
import 'classroom_tab.dart';
import 'keep_tab.dart';
import 'map_tab.dart';
import 'chat_tab.dart';
//import 'help_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Color _appBarColor = const Color.fromRGBO(15, 23, 42, 1);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_handleTabSelection);
    // Initialize the app bar color
    _handleTabSelection();
  }

  void _handleTabSelection() {
    setState(() {
      switch (_tabController.index) {
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
        // case 5:
        //   _appBarColor = const Color.fromARGB(255, 255, 255, 255); // Help
        //   SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        //     statusBarColor: _appBarColor,
        //     statusBarIconBrightness: Brightness.dark, // Dark icons
        //   ));
        //   break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DefaultTabController(
        length: 5,
        child: Scaffold(
          body: TabBarView(
            controller: _tabController,
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
          bottomNavigationBar: Material(
            elevation: 0,
            color: _appBarColor,
            child: Container(
              height: 60,
              child: TabBar(
                controller: _tabController,

                // Set the indicator to null to remove it
                indicator: null,

                tabs: [
                  Tab(
                    icon: SizedBox(
                      width: 35.0, // Set the width you want
                      height: 35.0, // Set the height you want
                      child: Image.asset(
                        _tabController.index == 0
                            ? "assets/TabBarLogo/SeuTabBarLogoInver.png"
                            : "assets/TabBarLogo/SeuTabBarLogoInver.png",
                        color: _tabController.index == 0
                            ? Colors.black
                            : Colors.grey,
                      ),
                    ),
                  ),
                  Tab(
                    icon: SizedBox(
                      width: 35.0, // Set the width you want
                      height: 35.0, // Set the height you want
                      child: Image.asset(
                        _tabController.index == 1
                            ? "assets/TabBarLogo/google_classroom_white.png"
                            : "assets/TabBarLogo/google_classroom_black.png",
                        color: _tabController.index == 1
                            ? Colors.black
                            : Colors.grey,
                      ),
                    ),
                  ),
                  Tab(
                    icon: Icon(
                      _tabController.index == 2
                          ? Icons.add
                          : Icons.add, // Same icon for selected and unselected
                      color: _tabController.index == 2
                          ? Colors.black
                          : Colors.grey,
                      size: 35,
                    ),
                  ),
                  Tab(
                    icon: Icon(
                      _tabController.index == 3
                          ? Icons.location_on
                          : Icons
                              .location_on_outlined, // Same icon for selected and unselected
                      color: _tabController.index == 3
                          ? Colors.black
                          : Colors.grey,
                      size: 35,
                    ),
                  ),
                  Tab(
                    icon: Icon(
                      _tabController.index == 4
                          ? Icons.menu_sharp
                          : Icons.menu, // Same icon for selected and unselected
                      color: _tabController.index == 4
                          ? Colors.black
                          : Colors.grey,
                      size: 35,
                    ),
                  ),
                  // Tab(
                  //   icon: Image.asset(
                  //     _tabController.index == 5
                  //         ? "assets/TabBarLogo/help_selected.png"
                  //         : "assets/TabBarLogo/help.png",
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
