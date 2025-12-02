import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class MyInventoryPage extends StatefulWidget {
  const MyInventoryPage({super.key});

  @override
  State<MyInventoryPage> createState() => _MyInventoryPageState();
}

class _MyInventoryPageState extends State<MyInventoryPage> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    setState(() => _loading = true);
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
    setState(() => _loading = false);
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
                    final title = item['courseTitle'] ?? item['Course Title'] ?? '';
                    final faculty = item['faculty'] ?? item['Faculty'] ?? '';
                    final date = item['date'] ?? item['Date'] ?? '';
                    final time12 = item['time12'] ?? '';
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
