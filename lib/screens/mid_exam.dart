import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter/services.dart' show rootBundle;

class ExamScheduleExtractorPage extends StatefulWidget {
  @override
  _ExamScheduleExtractorPageState createState() =>
      _ExamScheduleExtractorPageState();
}

class _ExamScheduleExtractorPageState extends State<ExamScheduleExtractorPage> {
  final ImagePicker _picker = ImagePicker();
  bool isProcessing = false;
  String? errorMessage;

  List<Map<String, dynamic>> finalResults = [];

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

      await extractText(image.path);
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

  Future<void> parseAndMatch(String extractedText) async {
    try {
      // More robust pattern: allow optional spaces and separators between parts
      // Examples matched: CSE343.6, CSE 343.6, CSE343-6, CSE 343 6
      final codeRegex = RegExp(
        r'([A-Za-z]{3,4})\s*(\d{3})(?:[\.\-_/\s]*(\d{1,2}))?',
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

      final schedule = await loadExamJson();
      final results = <Map<String, dynamic>>[];
      final seenKeys = <String>{};

      for (final m in matches) {
        final dept = (m.group(1) ?? '').toUpperCase();
        final num = (m.group(2) ?? '');
        final base = '$dept$num'; // e.g. CSE263
        String? section = m.group(3);
        if (section != null) {
          section = section.replaceFirst(RegExp(r'^0+'), ''); // strip leading zeros
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
              'time': schedule[key]['time'],
              'room': schedule[key]['room'],
            });
          }
        } else {
          // No section in screenshot: include all sections for this base code.
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
                'time': schedule[key]['time'],
                'room': schedule[key]['room'],
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

  Future<Map<String, dynamic>> loadExamJson() async {
    try {
      String jsonStr =
          await rootBundle.loadString("assets/data/exam_schedule.json");
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
                scheduleMap[key] = {
                  'date': item['Date'],
                  // Combine start/end time if available
                  'time': _combineTime(item['Start Time'], item['End Time']),
                  // Use Slot as a proxy for room if no explicit room
                  'room': (item['Room'] ?? item['Slot '] ?? '').toString().trim(),
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
      throw "Failed to load exam schedule JSON. Error: $e";
    }
  }

  String _combineTime(dynamic start, dynamic end) {
    final s = start?.toString().trim();
    final e = end?.toString().trim();
    if (s == null || s.isEmpty) return e ?? '';
    if (e == null || e.isEmpty) return s;
    return '$s - $e';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Midterm Schedule Finder"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
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

            /// Display Results
            if (!isProcessing && finalResults.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: finalResults.length,
                  itemBuilder: (context, index) {
                    final item = finalResults[index];
                    return Card(
                      child: ListTile(
                        title:
                            Text("${item['course']} (Sec ${item['section']})"),
                        subtitle: Text(
                          "Date: ${item['date']}\n"
                          "Time: ${item['time']}\n"
                          "Room: ${item['room']}",
                        ),
                      ),
                    );
                  },
                ),
              )
          ],
        ),
      ),
    );
  }
}
