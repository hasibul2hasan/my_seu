import 'package:flutter/material.dart';
import 'package:my_seu/screens/subPages/mid_exam.dart';

class ServicesTab extends StatefulWidget {
  const ServicesTab({super.key});

  @override
  _ServicesTabState createState() => _ServicesTabState();
}

class _ServicesTabState extends State<ServicesTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  void _showComingSoonSnack() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        backgroundColor: isDark ? Colors.grey[850] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.blue, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Coming soon',
                    style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'We’re polishing this feature. Stay tuned!',
                    style: TextStyle(color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'Nice',
          textColor: Colors.blue,
          onPressed: () {},
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _navigateToPage(Widget page) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.ease;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final now = DateTime.now();
    final monthName = _getMonthName(now.month);
    final academicYear = '${now.year}-${now.year + 1}';

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // App Bar Section
          SliverAppBar(
            backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
            elevation: 0,
            expandedHeight: 180,
            floating: true,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDarkMode
                        ? [
                            Colors.blueGrey[900]!,
                            Colors.grey[900]!,
                          ]
                        : [
                            Colors.blue[50]!,
                            Colors.white,
                          ],
                ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDarkMode ? Colors.blue[800] : Colors.blue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Academic Services',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: isDarkMode ? Colors.white : Colors.blue[900],
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Essential tools for your academic journey',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Current Term Info
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isDarkMode
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                  border: Border.all(
                    color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.blue[900] : Colors.blue[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.calendar_month_rounded,
                        color: isDarkMode ? Colors.blue[200] : Colors.blue[700],
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Term',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Fall 2025',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDarkMode ? Colors.white : Colors.blue[900],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$monthName ${now.day}, ${now.year} • Academic Year $academicYear',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Services Grid Section
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.9,
              ),
              delegate: SliverChildListDelegate([
                _ServiceCard(
                  icon: Icons.assignment_turned_in_rounded,
                  label: 'Midterm\nExam Schedule',
                  description: 'Find your midterm dates & times',
                  color: Colors.blue,
                  accentColor: Colors.blueAccent,
                  onTap: () => _navigateToPage(const ExamScheduleExtractorPage(
                    scheduleAssetPath: 'assets/data/mid_exam.json',
                    pageTitle: 'Midterm Schedule Finder',
                  )),
                ),
                _ServiceCard(
                  icon: Icons.assignment_rounded,
                  label: 'Final\nExam Schedule',
                  description: 'Final exam dates & locations',
                  color: Colors.purple,
                  accentColor: Colors.purpleAccent,
                  onTap: () => _navigateToPage(const ExamScheduleExtractorPage(
                    scheduleAssetPath: 'assets/data/final_exam.json',
                    pageTitle: 'Final Exam Schedule Finder',
                  )),
                ),
                _ServiceCard(
                  icon: Icons.schedule_rounded,
                  label: 'Class\nSchedule',
                  description: 'View your weekly timetable',
                  color: Colors.green,
                  accentColor: Colors.greenAccent,
                  onTap: _showComingSoonSnack,
                  comingSoon: true,
                ),
                _ServiceCard(
                  icon: Icons.library_books_rounded,
                  label: 'Course\nCatalog',
                  description: 'Browse available courses',
                  color: Colors.orange,
                  accentColor: Colors.orangeAccent,
                  onTap: _showComingSoonSnack,
                  comingSoon: true,
                ),
                _ServiceCard(
                  icon: Icons.grade_rounded,
                  label: 'Grade\nTracker',
                  description: 'Monitor your grades',
                  color: Colors.red,
                  accentColor: Colors.redAccent,
                  onTap: _showComingSoonSnack,
                  comingSoon: true,
                ),
                _ServiceCard(
                  icon: Icons.event_note_rounded,
                  label: 'Academic\nCalendar',
                  description: 'Important dates & deadlines',
                  color: Colors.teal,
                  accentColor: Colors.tealAccent,
                  onTap: _showComingSoonSnack,
                  comingSoon: true,
                ),
              ]),
            ),
          ),

         
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final Color accentColor;
  final VoidCallback onTap;
  final bool comingSoon;

  const _ServiceCard({
    super.key,
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.accentColor,
    required this.onTap,
    this.comingSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Stack(
          children: [
            if (comingSoon)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.amber[700] : Colors.amber[600],
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.hourglass_bottom_rounded, size: 14, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'Coming soon',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDarkMode
                  ? [
                      color.withOpacity(0.15),
                      color.withOpacity(0.08),
                    ]
                  : [
                      color.withOpacity(0.08),
                      color.withOpacity(0.03),
                    ],
            ),
            border: Border.all(
              color: isDarkMode ? color.withOpacity(0.3) : color.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDarkMode 
                    ? Colors.black.withOpacity(0.4)
                    : color.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              highlightColor: color.withOpacity(0.1),
              splashColor: color.withOpacity(0.2),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon Container
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            color.withOpacity(0.9),
                            accentColor.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Service Label
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDarkMode ? Colors.white : color.withOpacity(0.9),
                        height: 1.2,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Description
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Arrow Indicator
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDarkMode ? color.withOpacity(0.2) : color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: color,
                          size: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ),
          ],
        ),
      ),
    );
  }
}