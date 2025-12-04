import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class MyInventoryPage extends StatefulWidget {
  final String scheduleAssetPath;

  const MyInventoryPage({super.key, required this.scheduleAssetPath});

  @override
  State<MyInventoryPage> createState() => _MyInventoryPageState();
}

class _MyInventoryPageState extends State<MyInventoryPage> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  Map<String, dynamic> _scheduleMap = {};

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    await Future.wait([
      _loadInventory(),
      _loadSchedule(),
    ]);
    setState(() => _loading = false);
  }

  Future<void> _loadInventory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('my_courses');
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _items = decoded
              .whereType<Map<String, dynamic>>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        } else {
          _items = [];
        }
      } else {
        _items = [];
      }
    } catch (_) {
      _items = [];
    }
  }

  Future<void> _loadSchedule() async {
    try {
      final jsonStr = await DefaultAssetBundle.of(context).loadString(widget.scheduleAssetPath);
      final decoded = jsonDecode(jsonStr);
      if (decoded is List) {
        final Map<String, dynamic> map = {};
        final codePattern = RegExp(r'^([A-Z]{3,4}\d{3})\.(\d+)$');
        for (final item in decoded) {
          if (item is Map) {
            final courseCode = item['Course Code'];
            if (courseCode is String) {
              final match = codePattern.firstMatch(courseCode.trim());
              if (match != null) {
                final base = match.group(1)!;
                final section = match.group(2)!;
                final key = '${base}_${section}';
                final start = item['Start Time'];
                final end = item['End Time'];
                map[key] = {
                  'date': item['Date'],
                  'courseTitle': item['Course Title'],
                  'faculty': item['Faculty'],
                  'time24': _combineTime(start, end),
                  'time12': _combineTime(_to12Hour(start), _to12Hour(end)),
                };
              }
            }
          }
        }
        _scheduleMap = map;
      } else if (decoded is Map<String, dynamic>) {
        _scheduleMap = decoded;
      } else {
        _scheduleMap = {};
      }
    } catch (_) {
      _scheduleMap = {};
    }
  }

  String _combineTime(dynamic start, dynamic end) {
    final s = start?.toString().trim();
    final e = end?.toString().trim();
    if (s == null || s.isEmpty) return e ?? '';
    if (e == null || e.isEmpty) return s;
    return '$s - $e';
  }

  String? _to12Hour(dynamic time) {
    if (time == null) return null;
    final t = time.toString().trim();
    if (t.isEmpty) return null;
    final parts = t.split(':');
    if (parts.isEmpty) return t;
    int hour = int.tryParse(parts[0]) ?? 0;
    final minutes = parts.length > 1 ? parts[1].padLeft(2, '0') : '00';
    final suffix = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    return '$hour:$minutes $suffix';
  }

  Future<void> _removeItem(int index) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _items.removeAt(index);
    });
    // Persist
    await prefs.setString('my_courses', jsonEncode(_items));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Courses')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_items.isEmpty)
              ? const Center(child: Text('No courses in inventory'))
              : ListView.separated(
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final course = item['course'] ?? item['Course Code'] ?? '';
                    final section = item['section'] ?? item['Section'] ?? '';
                    final key = '${course}_${section}';
                    final sched = _scheduleMap[key] ?? {};
                    final title = sched['courseTitle'] ?? '';
                    final faculty = sched['faculty'] ?? '';
                    final date = sched['date'] ?? '';
                    final time12 = sched['time12'] ?? '';
                    return ListTile(
                      title: Text('$course${section != '' ? '.$section' : ''}'),
                      subtitle: Text([
                        if (title.toString().isNotEmpty) title,
                        if (faculty.toString().isNotEmpty) 'Faculty: $faculty',
                        if (date.toString().isNotEmpty) 'Date: $date',
                        if (time12.toString().isNotEmpty) 'Time: $time12',
                      ].join('\n')),
                      trailing: IconButton(
                        tooltip: 'Remove',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _removeItem(index),
                      ),
                    );
                  },
                ),
    );
  }
}
