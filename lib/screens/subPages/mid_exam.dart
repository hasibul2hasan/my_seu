import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import './my_inventory_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

// Placeholder imports for web compatibility (assuming these exist in the project structure)
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
  Map<String, dynamic>? _scheduleCache;
  Timer? _searchDebounce;
  
  // UI state for manual search expansion
  bool _isManualSearchExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadInventory();
    loadExamJson().then((map) {
      _scheduleCache = map;
      _scheduleUnavailable = map.isEmpty;
      if (_courseController.text.isEmpty && !_scheduleUnavailable) {
        manualSearch(); // Show all initially
      }
    }).catchError((error) {
      _scheduleUnavailable = true;
      setState(() {
        isProcessing = false;
        errorMessage = "Exam schedule is not published yet or failed to load.";
      });
    });
  }

  // --- OCR & Text Extraction Methods ---

  Future<void> pickImage() async {
    if (_scheduleUnavailable) {
       setState(() => errorMessage = "Schedule data is unavailable. Cannot process image.");
       return;
    }
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
        errorMessage = "Unexpected error during image picking: $e";
      });
    }
  }

  Future<void> extractTextFromFile(XFile image) async {
    try {
      String extractedText = '';
      if (kIsWeb) {
        // Web handling via Tesseract.js stub
        final bytes = await image.readAsBytes();
        // Assuming webRecognizeImageBytes is defined in web_ocr_web.dart
        extractedText = await webRecognizeImageBytes(bytes); 
      } else {
        // Mobile handling via Google ML Kit
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
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  // --- Parsing and Matching ---

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
      if (schedule.isEmpty) {
        setState(() {
          isProcessing = false;
          errorMessage = 'Schedule is currently unavailable.';
        });
        return;
      }
      _scheduleCache ??= schedule;
      final results = <Map<String, dynamic>>[];
      final seenKeys = <String>{};

      for (final m in matches) {
        final dept = (m.group(1) ?? '').toUpperCase();
        final num = (m.group(2) ?? '');
        final base = '$dept$num';
        String? section = m.group(3);

        if (section != null) {
          section = section.replaceAll(RegExp(r'\s+'), '').replaceFirst(RegExp(r'^0+'), '');
          if (section.isEmpty) section = '0';
        }

        final keysToCheck = <String>[];
        if (section != null) {
          keysToCheck.add('${base}_${section}');
        } else {
          keysToCheck.addAll(schedule.keys.where((k) => k.startsWith(base + '_')));
        }
        
        for (final key in keysToCheck) {
          if (schedule.containsKey(key) && !seenKeys.contains(key)) {
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

  // --- Inventory & Data Loading Methods ---

  Future<void> _loadInventory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('my_courses');
    if (raw != null && raw.isNotEmpty) {
      final List<dynamic> decoded = json.decode(raw);
      myInventory = decoded.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      myInventory = [];
    }
    // Note: Do not call setState here if called from initState, 
    // but safe here as it's often called after navigation return.
    if(mounted) setState(() {}); 
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

  Future<void> manualSearch() async {
    setState(() {
      isProcessing = true;
      errorMessage = null;
    });

    try {
      if (_scheduleUnavailable) {
        setState(() {
          isProcessing = false;
          errorMessage = "Exam schedule is not published yet.";
        });
        return;
      }
      final rawCourse = _courseController.text.trim();
      final schedule = _scheduleCache ?? await loadExamJson();
      _scheduleCache ??= schedule;

      if (schedule.isEmpty && rawCourse.isNotEmpty) {
        setState(() {
          isProcessing = false;
          errorMessage = "Schedule is unavailable.";
        });
        return;
      }

      final results = <Map<String, dynamic>>[];
      final seenKeys = <String>{}; // To prevent duplicates in manual search too

      if (rawCourse.isEmpty) {
        for (final key in schedule.keys) {
          if (!seenKeys.contains(key)) {
            seenKeys.add(key);
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
        }
      } else {
        // dot-format check first (CSE281.11)
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
          // Normalize course code (e.g., CSE263)
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
            if (!seenKeys.contains(key)) {
              seenKeys.add(key);
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
      }

      if (results.isEmpty && rawCourse.isNotEmpty) {
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
      // The JSON file is an array of objects
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
        return {};
      }
    } catch (e) {
      // Treat missing or unreadable asset as unavailable
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
    final parts = t.split(':');
    if (parts.isEmpty) return t;
    int hour = int.tryParse(parts[0]) ?? 0;
    
    // Default minute/second to '00' if not present
    final minutes = parts.length > 1 ? parts[1].padLeft(2, '0') : '00';
    
    final suffix = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    
    return '$hour:$minutes $suffix';
  }


  // --- Widget Build (Revised UI) ---

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
            // 1. Primary Action: Upload Screenshot
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _scheduleUnavailable ? null : pickImage,
                icon: const Icon(Icons.camera_alt),
                label: Text(
                  _scheduleUnavailable 
                    ? "Schedule Unavailable" 
                    : "Upload Registration Screenshot",
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const Divider(height: 32),

            // 2. Secondary Action: My Courses Button & Inventory Chips
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
                      _loadInventory();
                    },
                  ),
                  if (myInventory.isNotEmpty) ...myInventory.map((inv) {
                    final code = "${inv['course']}.${inv['section']}";
                    return InputChip(
                      label: Text(code),
                      avatar: const Icon(Icons.class_, size: 18),
                      onPressed: () {
                        setState(() {
                          _courseController.text = code;
                          _isManualSearchExpanded = true;
                        });
                        manualSearch();
                      },
                      onDeleted: () => _removeFromInventory(inv['course'].toString(), inv['section'].toString()),
                    );
                  }).toList(),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // 3. Manual Search Section (Collapsible)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Search by Course Code Manually'),
              leading: Icon(_isManualSearchExpanded ? Icons.arrow_drop_down : Icons.arrow_right),
              initiallyExpanded: _isManualSearchExpanded,
              onExpansionChanged: (expanded) {
                setState(() {
                  _isManualSearchExpanded = expanded;
                });
              },
              children: [
                Column(
                  children: [
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
                                  manualSearch();
                                },
                              )
                            : null,
                      ),
                      enabled: !_scheduleUnavailable,
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
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: _scheduleUnavailable ? null : manualSearch,
                        icon: const Icon(Icons.search),
                        label: const Text('Search'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
            const Divider(height: 0),

            // 4. Status and Results Display
            
            // Loading Indicator
            if (isProcessing) const Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: CircularProgressIndicator(),
            ),

            // Error Message
            if (errorMessage != null && !isProcessing) ...[
              const SizedBox(height: 16),
              Text(
                '🚨 ${errorMessage!}',
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              )
            ],

            // Results List
            if (!isProcessing && finalResults.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: finalResults.length,
                  itemBuilder: (context, index) {
                    final item = finalResults[index];
                    final code = "${item['course']}.${item['section']}";
                    final inInv = myInventory.any((e) => "${e['course']}.${e['section']}" == code);
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6.0),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        title: Text(
                          code,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: "${item['courseTitle'] ?? ''}\n"),
                              const TextSpan(text: "🗓️ ", style: TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(text: "Date: ${item['date']}\n"),
                              const TextSpan(text: "⏰ ", style: TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(text: "Time (24h): ${item['time24'] ?? 'N/A'}\n"), // 24h Time
                              const TextSpan(text: "⏱️ ", style: TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(text: "Time (12h): ${item['time12'] ?? 'N/A'}\n"), // 12h Time
                              const TextSpan(text: "🧑‍🏫 ", style: TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(text: "Faculty: ${item['faculty'] ?? ''}"),
                            ],
                          ),
                          style: const TextStyle(height: 1.5),
                        ),
                        isThreeLine: true,
                        trailing: inInv
                            ? IconButton(
                                tooltip: 'Remove from My Courses',
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _removeFromInventory(
                                  item['course'].toString(),
                                  item['section'].toString(),
                                ),
                              )
                            : IconButton(
                                tooltip: 'Add to My Courses',
                                icon: const Icon(Icons.playlist_add, color: Colors.blue),
                                onPressed: () => _addToInventory(item),
                              ),
                      ),
                    );
                  },
                ),
              )
            else if (!isProcessing && errorMessage == null)
               const Expanded(
                 child: Center(
                   child: Text(
                     "Upload a screenshot or use the manual search to find exam schedules.",
                     textAlign: TextAlign.center,
                     style: TextStyle(color: Colors.grey, fontSize: 16),
                   ),
                 ),
               ),
          ],
        ),
      ),
    );
  }
}