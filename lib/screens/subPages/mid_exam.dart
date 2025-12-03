import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import './my_inventory_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import '../../services/web_ocr_stub.dart'
  if (dart.library.html) '../../services/web_ocr_web.dart';

class ExamScheduleExtractorPage extends StatefulWidget {
  final String scheduleAssetPath;
  final String pageTitle;

  const ExamScheduleExtractorPage({
    Key? key,
    this.scheduleAssetPath = "assets/data/exam_schedule.json",
    this.pageTitle = "Midterm Schedule Finder",
  }) : super(key: key);

  @override
  _ExamScheduleExtractorPageState createState() =>
      _ExamScheduleExtractorPageState();
}

class _ExamScheduleExtractorPageState extends State<ExamScheduleExtractorPage> {
  final ImagePicker _picker = ImagePicker();
  bool isProcessing = false;
  String? errorMessage;
  bool _scheduleUnavailable = false;

  List<Map<String, dynamic>> finalResults = [];
  final TextEditingController _courseController = TextEditingController();
  List<Map<String, dynamic>> myInventory = [];
  bool showInventoryHints = true;
  Map<String, dynamic>? _scheduleCache;
  bool hasSearched = false;
  Timer? _searchDebounce;

  Future<void> pickImage() async {
    try {
      setState(() {
        isProcessing = true;
        errorMessage = null;
        finalResults.clear();
      });

      XFile? image = await _picker.pickImage(source: ImageSource.gallery);

      if (image == null) {
        setState(() {
          isProcessing = false;
          errorMessage = "No image selected.";
        });
        return;
      }

      await extractTextFromFile(image);
    } catch (e) {
      setState(() {
        isProcessing = false;
        errorMessage = "Unexpected error: $e";
      });
    }
  }

  Future<void> extractText(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final textRecognizer = TextRecognizer();

      RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);

      String extractedText = recognizedText.text;

      await textRecognizer.close();

      if (extractedText.trim().isEmpty) {
        setState(() {
          isProcessing = false;
          errorMessage = "Could not read any text. Try a clearer screenshot.";
        });
        return;
      }

      await parseAndMatch(extractedText);
    } catch (e) {
      setState(() {
        isProcessing = false;
        errorMessage = "Failed to process image. Error: $e";
      });
    }
  }

  Future<void> extractTextFromFile(XFile image) async {
    try {
      String extractedText = '';
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        extractedText = await webRecognizeImageBytes(bytes);
      } else {
        if (!_isTextRecognitionSupported()) {
          setState(() {
            isProcessing = false;
            errorMessage =
                "Text recognition is not supported on this platform. Please run on Android or iOS.";
          });
          return;
        }

        final inputImage = InputImage.fromFilePath(image.path);
        final textRecognizer = TextRecognizer();
        final recognizedText = await textRecognizer.processImage(inputImage);
        extractedText = recognizedText.text;
        await textRecognizer.close();
      }

      if (extractedText.trim().isEmpty) {
        setState(() {
          isProcessing = false;
          errorMessage = "Could not read any text. Try a clearer screenshot.";
        });
        return;
      }

      await parseAndMatch(extractedText);
    } catch (e) {
      setState(() {
        isProcessing = false;
        errorMessage = "Failed to process image. Error: $e";
      });
    }
  }

  bool _isTextRecognitionSupported() {
    if (kIsWeb) return true; // Web handled via Tesseract.js
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<void> parseAndMatch(String extractedText) async {
    try {
      final codeRegex = RegExp(
        r'([A-Za-z]{3,4})\s*(\d{3})(?:[\.|\-|_|/|\s]*([\d\s]{1,3}))?',
        caseSensitive: false,
      );
      final matches = codeRegex.allMatches(extractedText).toList();

      if (matches.isEmpty) {
        setState(() {
          isProcessing = false;
          errorMessage =
              "Couldn't detect any course codes. Upload a clearer screenshot.";
        });
        return;
      }

      final schedule = _scheduleCache ?? await loadExamJson();
      _scheduleCache ??= schedule;
      final results = <Map<String, dynamic>>[];
      final seenKeys = <String>{};

      for (final m in matches) {
        final dept = (m.group(1) ?? '').toUpperCase();
        final num = (m.group(2) ?? '');
        final base = '$dept$num';
        String? section = m.group(3);
        if (section != null) {
          section = section.replaceAll(RegExp(r'\s+'), '');
          section = section.replaceFirst(RegExp(r'^0+'), '');
          if (section.isEmpty) section = '0';
        }
        if (section != null) {
          final key = '${base}_${section}';
          if (schedule.containsKey(key) && !seenKeys.contains(key)) {
            seenKeys.add(key);
            results.add({
              'course': base,
              'section': section,
              'date': schedule[key]['date'],
              'courseTitle': schedule[key]['courseTitle'],
              'faculty': schedule[key]['faculty'],
              'time24': schedule[key]['time24'],
              'time12': schedule[key]['time12'],
            });
          }
        } else {
          final possible = schedule.keys
              .where((k) => k.startsWith(base + '_'))
              .toList();
          for (final key in possible) {
            if (!seenKeys.contains(key)) {
              seenKeys.add(key);
              final parts = key.split('_');
              final sec = parts.length > 1 ? parts[1] : '';
              results.add({
                'course': base,
                'section': sec,
                'date': schedule[key]['date'],
                'courseTitle': schedule[key]['courseTitle'],
                'faculty': schedule[key]['faculty'],
                'time24': schedule[key]['time24'],
                'time12': schedule[key]['time12'],
              });
            }
          }
        }
      }

      if (results.isEmpty) {
        setState(() {
          isProcessing = false;
          errorMessage =
              'No matching exam schedule found for the detected course codes.';
        });
        return;
      }

      setState(() {
        finalResults = results;
        isProcessing = false;
      });
    } catch (e) {
      setState(() {
        isProcessing = false;
        errorMessage = "Parsing error: $e";
      });
    }
  }

  Future<void> _loadInventory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('my_courses');
    if (raw != null && raw.isNotEmpty) {
      final List<dynamic> decoded = json.decode(raw);
      myInventory = decoded.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      myInventory = [];
    }
    setState(() {});
  }

  Future<void> _addToInventory(Map<String, dynamic> item) async {
    final key = "${item['course']}.${item['section']}";
    final exists = myInventory.any((e) => "${e['course']}.${e['section']}" == key);
    if (!exists) {
      myInventory.add({
        'course': item['course'],
        'section': item['section'],
        'date': item['date'],
        'courseTitle': item['courseTitle'],
        'faculty': item['faculty'],
        'time24': item['time24'],
        'time12': item['time12'],
      });
      setState(() {});
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString('my_courses', json.encode(myInventory));
      });
    }
  }

  Future<void> _removeFromInventory(String course, String section) async {
    myInventory.removeWhere((e) => "${e['course']}.${e['section']}" == "$course.$section");
    setState(() {});
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('my_courses', json.encode(myInventory));
    });
  }

  // _clearInventory removed from header per request; keep helpers minimal.

  @override
  void initState() {
    super.initState();
    _loadInventory();
    // Preload cache so first search is fast
    loadExamJson().then((map) {
      _scheduleCache = map;
      _scheduleUnavailable = map.isEmpty;
      // Show all courses on entering the page
      manualSearch();
    }).catchError((error) {
      // Mark unavailable and show message
      _scheduleUnavailable = true;
      setState(() {
        isProcessing = false;
        errorMessage = "Not published yet";
      });
    });
  }
  Future<void> manualSearch() async {
    setState(() {
      isProcessing = true;
      errorMessage = null;
      finalResults.clear();
      hasSearched = true;
    });

    try {
      if (_scheduleUnavailable) {
        setState(() {
          isProcessing = false;
          errorMessage = "Not published yet";
        });
        return;
      }
      final rawCourse = _courseController.text.trim();
      final schedule = _scheduleCache ?? await loadExamJson();
      _scheduleCache ??= schedule;
      if ((schedule.isEmpty)) {
        _scheduleUnavailable = true;
        setState(() {
          isProcessing = false;
          errorMessage = "Not published yet";
        });
        return;
      }
      final results = <Map<String, dynamic>>[];

      if (rawCourse.isEmpty) {
        for (final key in schedule.keys) {
          final parts = key.split('_');
          final base = parts.isNotEmpty ? parts.first : '';
          final sec = parts.length > 1 ? parts[1] : '';
          results.add({
            'course': base,
            'section': sec,
            'date': schedule[key]['date'],
            'courseTitle': schedule[key]['courseTitle'],
            'faculty': schedule[key]['faculty'],
            'time24': schedule[key]['time24'],
            'time12': schedule[key]['time12'],
          });
        }
      } else {
        // dot-format like CSE281.11
        final dotPattern = RegExp(r'^\s*([A-Za-z]{3,4})\s*([\.-_\s]?)\s*(\d{3})\s*\.\s*(\d+)\s*$', caseSensitive: false);
        final dotMatch = dotPattern.firstMatch(rawCourse);
        if (dotMatch != null) {
          final dept = (dotMatch.group(1) ?? '').toUpperCase();
          final num = (dotMatch.group(3) ?? '');
          final sec = (dotMatch.group(4) ?? '');
          final normalizedCourse = '$dept$num';
          final key = '${normalizedCourse}_${sec}';
          if (schedule.containsKey(key)) {
            results.add({
              'course': normalizedCourse,
              'section': sec,
              'date': schedule[key]['date'],
              'courseTitle': schedule[key]['courseTitle'],
              'faculty': schedule[key]['faculty'],
              'time24': schedule[key]['time24'],
              'time12': schedule[key]['time12'],
            });
          }
        } else {
          // Normalize course code: allow inputs like cse 263 or CSE-263
          final normalizedCourse = rawCourse
              .toUpperCase()
              .replaceAll(RegExp(r'[^A-Z0-9]'), '');

          final courseMatch = RegExp(r'^[A-Z]{3,4}\d{3}$').hasMatch(normalizedCourse);
          if (!courseMatch) {
            setState(() {
              isProcessing = false;
              errorMessage = "Invalid course code. Use e.g., CSE263 or CSE263.11";
            });
            return;
          }

          final possible = schedule.keys
              .where((k) => k.startsWith(normalizedCourse + '_'))
              .toList();
          for (final key in possible) {
            final parts = key.split('_');
            final sec = parts.length > 1 ? parts[1] : '';
            results.add({
              'course': normalizedCourse,
              'section': sec,
              'date': schedule[key]['date'],
              'courseTitle': schedule[key]['courseTitle'],
              'faculty': schedule[key]['faculty'],
              'time24': schedule[key]['time24'],
              'time12': schedule[key]['time12'],
            });
          }
        }
      }

      if (results.isEmpty) {
        setState(() {
          isProcessing = false;
          errorMessage = 'No matching exam found for input.';
        });
        return;
      }

      results.sort((a, b) {
        final ac = (a['course'] ?? '').toString();
        final bc = (b['course'] ?? '').toString();
        final cmp = ac.compareTo(bc);
        if (cmp != 0) return cmp;
        final as = int.tryParse((a['section'] ?? '0').toString()) ?? 0;
        final bs = int.tryParse((b['section'] ?? '0').toString()) ?? 0;
        return as.compareTo(bs);
      });

      setState(() {
        finalResults = results;
        isProcessing = false;
      });
    } catch (e) {
      setState(() {
        isProcessing = false;
        errorMessage = "Manual search failed: $e";
      });
    }
  }

  Future<Map<String, dynamic>> loadExamJson() async {
    try {
      String jsonStr =
          await rootBundle.loadString(widget.scheduleAssetPath);
      final decoded = json.decode(jsonStr);
      // The JSON file is an array of objects, not a map. We need to
      // build a lookup map keyed like COURSECODE_SECTION (e.g. CSE263_12)
      // from entries whose "Course Code" looks like CSE263.12
      if (decoded is List) {
        final Map<String, dynamic> scheduleMap = {};
        final codePattern = RegExp(r'^([A-Z]{3,4}\d{3})\.(\d+)$');
        for (final item in decoded) {
          if (item is Map) {
            final courseCode = item['Course Code'];
            if (courseCode is String) {
              final match = codePattern.firstMatch(courseCode.trim());
              if (match != null) {
                final base = match.group(1)!; // e.g. CSE263
                final section = match.group(2)!; // e.g. 12
                final key = '${base}_${section}';
                // Normalize into the structure expected by parseAndMatch
                final start = item['Start Time'];
                final end = item['End Time'];
                final time24 = _combineTime(start, end);
                final time12 = _combineTime(_to12Hour(start), _to12Hour(end));
                scheduleMap[key] = {
                  'date': item['Date'],
                  'courseTitle': item['Course Title'],
                  'faculty': item['Faculty'],
                  'time24': time24,
                  'time12': time12,
                };
              }
            }
          }
        }
        return scheduleMap;
      } else if (decoded is Map<String, dynamic>) {
        return decoded;
      } else {
        throw 'Unexpected exam schedule JSON format';
      }
    } catch (e) {
      // Treat missing or unreadable asset as "not published yet"
      return {};
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
    // Expect formats like HH:MM or HH:MM:SS
    final parts = t.split(':');
    if (parts.isEmpty) return t;
    int hour = int.tryParse(parts[0]) ?? 0;
    final rest = parts.length > 2
        ? '${parts[1]}:${parts[2]}'
        : (parts.length > 1 ? parts[1] : '00');
    final suffix = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    return '$hour:$rest $suffix';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pageTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Manual search inputs
            TextField(
              controller: _courseController,
              decoration: InputDecoration(
                labelText: 'Course or Course.Section (e.g., CSE263 or CSE263.11)',
                suffixIcon: (_courseController.text.isNotEmpty)
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: 'Clear',
                        onPressed: () {
                          _courseController.clear();
                          // Immediately reset the search results when clearing
                          manualSearch();
                        },
                      )
                    : null,
              ),
              textInputAction: TextInputAction.search,
              onChanged: (_) {
                setState(() {});
                _searchDebounce?.cancel();
                _searchDebounce = Timer(const Duration(milliseconds: 250), () {
                  manualSearch();
                });
              },
              onSubmitted: (_) => manualSearch(),
            ),
            // My Courses button will be shown inline with inventory chips below
            // My Courses button always visible; chips show before search
            ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.list),
                      label: const Text('My Courses'),
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const MyInventoryPage()),
                        );
                        // Refresh local inventory after returning
                        _loadInventory();
                        setState(() {});
                      },
                    ),
                    if (myInventory.isNotEmpty) ...myInventory.map((inv) {
                    final code = "${inv['course']}.${inv['section']}";
                    return InputChip(
                      label: Text(code),
                      onPressed: () {
                        setState(() {
                          _courseController.text = code;
                        });
                        manualSearch();
                      },
                      onDeleted: () => _removeFromInventory(inv['course'].toString(), inv['section'].toString()),
                    );
                    }).toList(),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                onPressed: manualSearch,
                icon: const Icon(Icons.search),
                label: const Text('Search Manually'),
              ),
            ),
            const Divider(height: 24),
            ElevatedButton(
              onPressed: pickImage,
              child: Text("Upload Registration Screenshot"),
            ),
            const SizedBox(height: 20),

            /// Loading Indicator
            if (isProcessing) CircularProgressIndicator(),

            /// Error Message
            if (errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              )
            ],

            // Inventory detailed list removed per request; only show chips under search and in My Courses page

            /// Display All Courses / Search Results
            if (!isProcessing)
              Expanded(
                child: ListView.builder(
                  itemCount: finalResults.length,
                  itemBuilder: (context, index) {
                    final item = finalResults[index];
                    final code = "${item['course']}.${item['section']}";
                    final inInv = myInventory.any((e) => "${e['course']}.${e['section']}" == code);
                    return Card(
                      child: ListTile(
                        title: Text(code),
                        subtitle: Text(
                          "Date: ${item['date']}\n"
                          "Course Title: ${item['courseTitle'] ?? ''}\n"
                          "Faculty: ${item['faculty'] ?? ''}\n"
                          "Time (24h): ${item['time24'] ?? ''}\n"
                          "Time (12h): ${item['time12'] ?? ''}",
                        ),
                        trailing: inInv
                            ? IconButton(
                                tooltip: 'Remove from My Courses',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _removeFromInventory(
                                  item['course'].toString(),
                                  item['section'].toString(),
                                ),
                              )
                            : IconButton(
                                tooltip: 'Add to My Courses',
                                icon: const Icon(Icons.playlist_add),
                                onPressed: () => _addToInventory(item),
                              ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
