import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'screens/ums_tab.dart';
import 'screens/classroom_tab.dart';
import 'screens/keep_tab.dart';
import 'screens/map_tab.dart';
import 'screens/services_tab.dart';

// ─── Breakpoints ────────────────────────────────────────────────────────────
// < 600 px   → mobile  → BottomNavigationBar
// 600–719 px → tablet  → NavigationRail (icon only)
// ≥ 720 px   → desktop → Full sidebar with labels
const double _kTabletBreak  = 600;
const double _kDesktopBreak = 720;
const double _kSidebarWidth = 220;
const double _kRailWidth    =  72;

// ─── Nav items ──────────────────────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const _NavItem(this.icon, this.selectedIcon, this.label);
}

const _navItems = [
  _NavItem(Icons.menu_outlined,       Icons.menu,            'Services'),
  _NavItem(Icons.school_outlined,     Icons.school,          'Classroom'),
  _NavItem(Icons.add_circle_outline,  Icons.add_circle,      'Keep'),
  _NavItem(Icons.location_on_outlined,Icons.location_on,     'Map'),
  _NavItem(Icons.account_circle_outlined, Icons.account_circle, 'UMS'),
];

// ─── App bar colors per tab ──────────────────────────────────────────────────
const _tabColors = [
  Color.fromARGB(255, 255, 255, 255), // Services
  Color.fromARGB(255, 255, 255, 255), // Classroom
  Color.fromARGB(255, 255, 255, 255), // Keep
  Color.fromARGB(255, 255, 255, 255), // Map
  Color.fromRGBO(15, 23, 42, 1),      // UMS
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _selectedIndex = 0;

  Color get _currentTabColor => _tabColors[_selectedIndex];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _applySystemUiOverlay();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _applySystemUiOverlay() {
    if (kIsWeb) return; // no-op on web
    final isDark = _selectedIndex == 4; // UMS tab is dark
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: _currentTabColor,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    ));
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
    _pageController.jumpToPage(index);
    _applySystemUiOverlay();
  }

  // ─── Pages ────────────────────────────────────────────────────────────────
  static const _pages = <Widget>[
    ServicesTab(),
    ClassroomTab(),
    KeepTab(),
    MapTab(),
    UmsTab(),
  ];

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    if (width < _kTabletBreak) {
      return _buildMobileLayout();
    } else if (width < _kDesktopBreak) {
      return _buildRailLayout(compact: true);
    } else {
      return _buildRailLayout(compact: false);
    }
  }

  // ── Mobile: bottom nav bar (original look) ──────────────────────────────
  Widget _buildMobileLayout() {
    return Scaffold(
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: _pages,
        ),
      ),
      bottomNavigationBar: Container(
        color: _currentTabColor,
        child: SafeArea(
          top: false,
          child: NavigationBar(
            backgroundColor: _currentTabColor,
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onItemTapped,
            indicatorColor: Colors.grey[200],
            labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
            destinations: [
              for (final item in _navItems)
                NavigationDestination(
                  icon: Icon(item.icon, color: Colors.grey[500]),
                  selectedIcon: Icon(item.selectedIcon, color: Colors.black87),
                  label: item.label,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tablet / Desktop: side rail or full sidebar ─────────────────────────
  Widget _buildRailLayout({required bool compact}) {
    final isDarkTab = _selectedIndex == 4; // UMS
    final railBg = isDarkTab
        ? const Color.fromRGBO(15, 23, 42, 1)
        : Colors.white;
    final labelColor = isDarkTab ? Colors.white70 : Colors.grey[700]!;
    final selectedColor = isDarkTab ? Colors.white : Colors.black87;
    final indicatorColor = isDarkTab
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.grey[200]!;

    return Scaffold(
      body: Row(
        children: [
          // ── Sidebar / Rail ──────────────────────────────────────────────
          Container(
            width: compact ? _kRailWidth : _kSidebarWidth,
            color: railBg,
            child: SafeArea(
              child: Column(
                children: [
                  // Logo / branding
                  if (!compact) ...[
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/TabBarLogo/seu.png',
                            width: 32,
                            height: 32,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.school_rounded,
                              size: 32,
                              color: isDarkTab ? Colors.white : Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'MY SEU',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: isDarkTab ? Colors.white : const Color.fromRGBO(15, 23, 42, 1),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Divider(
                      color: isDarkTab ? Colors.white12 : Colors.grey[200],
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                    ),
                    const SizedBox(height: 8),
                  ] else ...[
                    const SizedBox(height: 20),
                    Icon(
                      Icons.school_rounded,
                      size: 28,
                      color: isDarkTab ? Colors.white : Colors.blue,
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Nav items
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: _navItems.length,
                      itemBuilder: (context, i) {
                        final item = _navItems[i];
                        final selected = _selectedIndex == i;
                        return _SidebarItem(
                          icon: selected ? item.selectedIcon : item.icon,
                          label: item.label,
                          selected: selected,
                          compact: compact,
                          selectedColor: selectedColor,
                          labelColor: labelColor,
                          indicatorColor: indicatorColor,
                          onTap: () => _onItemTapped(i),
                          // Custom leading for Classroom and UMS
                          customIcon: i == 1
                              ? Image.asset(
                                  selected
                                    ? 'assets/TabBarLogo/google_classroom_black.png'
                                    : 'assets/TabBarLogo/google_classroom_white.png',
                                  width: 22,
                                  height: 22,
                                  errorBuilder: (_, __, ___) =>
                                      Icon(item.icon, size: 22, color: selected ? selectedColor : labelColor),
                                )
                              : i == 4
                                  ? Image.asset(
                                      'assets/TabBarLogo/seuinver.png',
                                      width: 22,
                                      height: 22,
                                      color: selected ? selectedColor : labelColor,
                                      errorBuilder: (_, __, ___) =>
                                          Icon(item.icon, size: 22, color: selected ? selectedColor : labelColor),
                                    )
                                  : null,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Thin divider line
          VerticalDivider(
            width: 1,
            color: isDarkTab ? Colors.white12 : Colors.grey[200],
          ),

          // ── Page content ─────────────────────────────────────────────────
          Expanded(
            child: SafeArea(
              left: false,
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: _pages,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sidebar nav item widget ─────────────────────────────────────────────────
class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool compact;
  final Color selectedColor;
  final Color labelColor;
  final Color indicatorColor;
  final VoidCallback onTap;
  final Widget? customIcon;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.compact,
    required this.selectedColor,
    required this.labelColor,
    required this.indicatorColor,
    required this.onTap,
    this.customIcon,
  });

  @override
  Widget build(BuildContext context) {
    final iconWidget = customIcon ?? Icon(icon, size: 22, color: selected ? selectedColor : labelColor);

    if (compact) {
      // Rail mode: icon only with tooltip
      return Tooltip(
        message: label,
        preferBelow: false,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: _kRailWidth,
            height: 56,
            decoration: selected
                ? BoxDecoration(
                    color: indicatorColor,
                    borderRadius: BorderRadius.circular(12),
                  )
                : null,
            child: Center(child: iconWidget),
          ),
        ),
      );
    }

    // Full sidebar mode: icon + label
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: selected
            ? BoxDecoration(
                color: indicatorColor,
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Row(
          children: [
            iconWidget,
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? selectedColor : labelColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
