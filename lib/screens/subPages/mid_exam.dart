import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import './my_inventory_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

// Placeholder imports for web compatibility
import '../../services/web_ocr_stub.dart'
  if (dart.library.html) '../../services/web_ocr_web.dart'; 

class ExamScheduleExtractorPage extends StatefulWidget {
  final String scheduleAssetPath;
  final String pageTitle;

  const ExamScheduleExtractorPage({
    Key? key,
    this.scheduleAssetPath = "assets/data/exam_schedule.json",
    this.pageTitle = "Exam Schedule Finder",
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
  
  // UI state
  bool _isManualSearchExpanded = false;
  final ScrollController _scrollController = ScrollController();

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
      final seenKeys = <String>{};

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
    
    final minutes = parts.length > 1 ? parts[1].padLeft(2, '0') : '00';
    
    final suffix = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    
    return '$hour:$minutes $suffix';
  }

  // Build method with corrected errors
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.pageTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue[800],
        iconTheme: IconThemeData(color: Colors.blue[800]),
      ),
      body: Column(
        children: [
          // Header Section
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Actions Row
                  Row(
                    children: [
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.camera_alt_rounded,
                          title: "Upload Screenshot",
                          subtitle: "Extract from registration",
                          color: Colors.blue,
                          onTap: _scheduleUnavailable ? null : pickImage,
                          disabled: _scheduleUnavailable,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.list_alt_rounded,
                          title: "My Courses",
                          subtitle: "${myInventory.length} saved",
                          color: Colors.green,
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => MyInventoryPage(
                                  scheduleAssetPath: widget.scheduleAssetPath,
                                ),
                              ),
                            );
                            _loadInventory();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Icon(Icons.search_rounded, color: Colors.grey[500]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _courseController,
                              decoration: InputDecoration(
                                hintText: 'Search by course code (CSE263 or CSE263.11)',
                                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              style: const TextStyle(fontSize: 14),
                              onChanged: (_) {
                                _searchDebounce?.cancel();
                                _searchDebounce = Timer(const Duration(milliseconds: 250), () {
                                  manualSearch();
                                });
                              },
                              onSubmitted: (_) => manualSearch(),
                            ),
                          ),
                          if (_courseController.text.isNotEmpty)
                            IconButton(
                              icon: Icon(Icons.clear_rounded, color: Colors.grey[500], size: 20),
                              onPressed: () {
                                _courseController.clear();
                                manualSearch();
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Quick Access Chips
          if (myInventory.isNotEmpty)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Quick Access",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: myInventory.length,
                      itemBuilder: (context, index) {
                        final inv = myInventory[index];
                        final code = "${inv['course']}.${inv['section']}";
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(
                              code,
                              style: const TextStyle(fontSize: 12),
                            ),
                            avatar: CircleAvatar(
                              backgroundColor: Colors.blue[100],
                              radius: 12,
                              child: Icon(
                                Icons.class_rounded, // FIXED: class_rounded instead of class__rounded
                                size: 14,
                                color: Colors.blue[800],
                              ),
                            ),
                            onSelected: (_) {
                              _courseController.text = code;
                              manualSearch();
                              _scrollController.animateTo(
                                0,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                              );
                            },
                            backgroundColor: Colors.grey[50],
                            selectedColor: Colors.blue[50],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

          // Status Indicators
          if (isProcessing)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[800]!),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Processing...",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

          if (errorMessage != null && !isProcessing)
            Container(
              width: double.infinity,
              color: Colors.red[50],
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: Colors.red[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      errorMessage!,
                      style: TextStyle(
                        color: Colors.red[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Results Section
          Expanded(
            child: _buildResultsSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection() {
    if (finalResults.isEmpty && !isProcessing && errorMessage == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.schedule_rounded,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              "Not Published Yet",
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "Upload a registration screenshot or search by course code to find exam schedules once published.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(20),
      itemCount: finalResults.length,
      itemBuilder: (context, index) {
        final item = finalResults[index];
        final code = "${item['course']}.${item['section']}";
        final inInv = myInventory.any((e) => "${e['course']}.${e['section']}" == code);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {},
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with course code and action button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            code,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Colors.blue[800],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            inInv ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                            color: inInv ? Colors.blue[800] : Colors.grey[400],
                            size: 20,
                          ),
                          onPressed: () {
                            if (inInv) {
                              _removeFromInventory(
                                item['course'].toString(),
                                item['section'].toString(),
                              );
                            } else {
                              _addToInventory(item);
                            }
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: inInv ? 'Remove from My Courses' : 'Add to My Courses',
                        ),
                      ],
                    ),
                    
                    // Course title
                    if (item['courseTitle'] != null && item['courseTitle'].toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          item['courseTitle'].toString(),
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    
                    // Schedule details
                    _buildDetailRow(
                      icon: Icons.calendar_today_rounded,
                      label: "Date",
                      value: item['date']?.toString() ?? 'N/A',
                    ),
                    _buildDetailRow(
                      icon: Icons.access_time_rounded,
                      label: "Time (12h)",
                      value: item['time12']?.toString() ?? 'N/A',
                    ),
                    _buildDetailRow(
                      icon: Icons.schedule_rounded,
                      label: "Time (24h)",
                      value: item['time24']?.toString() ?? 'N/A',
                    ),
                    if (item['faculty'] != null && item['faculty'].toString().isNotEmpty)
                      _buildDetailRow(
                        icon: Icons.person_rounded,
                        label: "Faculty",
                        value: item['faculty'].toString(),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.grey[500],
          ),
          const SizedBox(width: 8),
          Text(
            "$label: ",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Keep the _ActionCard widget (it's fine as a separate widget)
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
  final bool disabled;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.5 : 1.0,
      child: Material(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: disabled ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.2),
                  radius: 20,
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: color,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}