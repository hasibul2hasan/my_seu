import 'package:flutter/material.dart';
import 'package:ums/screens/subPages/mid_exam.dart';

class ServicesTab extends StatefulWidget {
  const ServicesTab({Key? key}) : super(key: key);

  @override
  _ServicesTabState createState() => _ServicesTabState();
}

class _ServicesTabState extends State<ServicesTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            const Text(
              'Fall 2025',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select a Service',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.25,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _GridButton(
                  icon: Icons.calendar_month,
                  label: 'MidTerm \nExam Schedule',
                  color: Colors.blue,
                  onTap: () => _navigateToPage(const ExamScheduleExtractorPage(
                    scheduleAssetPath: 'assets/data/exam_schedule.json',
                    pageTitle: 'Midterm Schedule Finder',
                  )),
                ),
                _GridButton(
                  icon: Icons.calendar_month,
                  label: 'Final \nExam Schedule',
                  color: Colors.purple,
                  onTap: () => _navigateToPage(const ExamScheduleExtractorPage(
                    scheduleAssetPath: 'assets/data/final_exam_schedule.json',
                    pageTitle: 'Final Exam Schedule Finder',
                  )),
                ),
               
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GridButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _GridButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
