import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../app_config.dart';

const List<String> kClassroomScopes = [
  'https://www.googleapis.com/auth/classroom.courses.readonly',
  'https://www.googleapis.com/auth/classroom.coursework.me.readonly',
  'https://www.googleapis.com/auth/classroom.announcements.readonly',
];

class ClassroomPermissionRequiredException implements Exception {
  final String message;
  ClassroomPermissionRequiredException([this.message = 'Classroom permission required']);
  @override
  String toString() => message;
}

class ClassroomCourse {
  final String id;
  final String name;
  final String? section;
  final String? descriptionHeading;
  final String? room;
  final String? alternateLink;

  ClassroomCourse({
    required this.id,
    required this.name,
    this.section,
    this.descriptionHeading,
    this.room,
    this.alternateLink,
  });

  factory ClassroomCourse.fromJson(Map<String, dynamic> json) {
    return ClassroomCourse(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Untitled Course',
      section: json['section'] as String?,
      descriptionHeading: json['descriptionHeading'] as String?,
      room: json['room'] as String?,
      alternateLink: json['alternateLink'] as String?,
    );
  }
}

class ClassroomCourseWork {
  final String id;
  final String title;
  final String? description;
  final String? dueDate;
  final num? maxPoints;
  final String? alternateLink;

  ClassroomCourseWork({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.maxPoints,
    this.alternateLink,
  });

  factory ClassroomCourseWork.fromJson(Map<String, dynamic> json) {
    String? formattedDueDate;
    if (json['dueDate'] != null) {
      final d = json['dueDate'] as Map<String, dynamic>;
      final year = d['year'];
      final month = d['month'];
      final day = d['day'];
      if (year != null && month != null && day != null) {
        formattedDueDate = '$day/$month/$year';
        if (json['dueTime'] != null) {
          final t = json['dueTime'] as Map<String, dynamic>;
          final hours = (t['hours'] ?? 0).toString().padLeft(2, '0');
          final minutes = (t['minutes'] ?? 0).toString().padLeft(2, '0');
          formattedDueDate += ' at $hours:$minutes';
        }
      }
    }

    return ClassroomCourseWork(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled Assignment',
      description: json['description'] as String?,
      dueDate: formattedDueDate,
      maxPoints: json['maxPoints'] as num?,
      alternateLink: json['alternateLink'] as String?,
    );
  }
}

class ClassroomAnnouncement {
  final String id;
  final String text;
  final String? alternateLink;
  final String? updateTime;

  ClassroomAnnouncement({
    required this.id,
    required this.text,
    this.alternateLink,
    this.updateTime,
  });

  factory ClassroomAnnouncement.fromJson(Map<String, dynamic> json) {
    return ClassroomAnnouncement(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      alternateLink: json['alternateLink'] as String?,
      updateTime: json['updateTime'] as String?,
    );
  }
}

class ClassroomService {
  ClassroomService._();
  static final ClassroomService instance = ClassroomService._();

  bool _initialized = false;
  GoogleSignInAccount? _currentUser;
  void Function(GoogleSignInAccount?)? onAuthChanged;

  GoogleSignInAccount? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;

  Future<void> init() async {
    if (_initialized) return;
    try {
      final clientId = AppConfig.hasClassroomClient ? AppConfig.classroomClientId : null;
      await GoogleSignIn.instance.initialize(clientId: clientId);
      _initialized = true;

      // Listen for authentication events (critical for Web GIS sign-in)
      GoogleSignIn.instance.authenticationEvents.listen((event) {
        if (event is GoogleSignInAuthenticationEventSignIn) {
          _currentUser = event.user;
          onAuthChanged?.call(_currentUser);
        } else if (event is GoogleSignInAuthenticationEventSignOut) {
          _currentUser = null;
          onAuthChanged?.call(null);
        }
      });

      // Try restoring an existing session
      final future = GoogleSignIn.instance.attemptLightweightAuthentication();
      if (future != null) {
        _currentUser = await future;
      }
    } catch (e) {
      debugPrint('ClassroomService init error: $e');
    }
  }

  Future<GoogleSignInAccount?> signIn() async {
    await init();
    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      return null;
    }
    try {
      final account = await GoogleSignIn.instance.authenticate(
        scopeHint: kClassroomScopes,
      );
      _currentUser = account;
      onAuthChanged?.call(account);
      return account;
    } catch (e) {
      debugPrint('ClassroomService signIn error: $e');
      rethrow;
    }
  }

  Future<bool> authorizeScopes() async {
    final user = _currentUser;
    if (user == null) return false;
    try {
      await user.authorizationClient.authorizeScopes(kClassroomScopes);
      return true;
    } catch (e) {
      debugPrint('authorizeScopes error: $e');
      if (e is GoogleSignInException && e.code == GoogleSignInExceptionCode.canceled) {
        throw ClassroomPermissionRequiredException('Authorization popup was closed before completing consent.');
      }
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } finally {
      _currentUser = null;
      onAuthChanged?.call(null);
    }
  }

  Future<Map<String, String>> _getAuthHeaders({bool allowPrompt = false}) async {
    final user = _currentUser;
    if (user == null) {
      throw Exception('User is not signed in to Google Classroom');
    }

    Map<String, String>? headers =
        await user.authorizationClient.authorizationHeaders(kClassroomScopes, promptIfNecessary: false);

    if (headers == null && allowPrompt) {
      headers = await user.authorizationClient.authorizationHeaders(kClassroomScopes, promptIfNecessary: true);
    }

    if (headers == null || headers.isEmpty) {
      throw ClassroomPermissionRequiredException(
        'Classroom access permissions required. Click below to grant access.',
      );
    }
    return headers;
  }

  Future<List<ClassroomCourse>> fetchCourses({bool allowPrompt = false}) async {
    final headers = await _getAuthHeaders(allowPrompt: allowPrompt);

    final Map<String, ClassroomCourse> coursesMap = {};
    int? firstErrorCode;
    String? firstErrorMessage;

    // Google Classroom has multiple list variants depending on user role (student, teacher, or domain-wide)
    final endpoints = [
      'https://classroom.googleapis.com/v1/courses?studentId=me',
      'https://classroom.googleapis.com/v1/courses?teacherId=me',
      'https://classroom.googleapis.com/v1/courses',
    ];

    for (final url in endpoints) {
      try {
        final uri = Uri.parse(url);
        final response = await http.get(uri, headers: headers);
        debugPrint('Classroom API ($url) status: ${response.statusCode}');

        if (response.statusCode == 200) {
          final data = json.decode(response.body) as Map<String, dynamic>;
          final list = data['courses'] as List<dynamic>? ?? [];
          for (final c in list) {
            final course = ClassroomCourse.fromJson(c as Map<String, dynamic>);
            if (course.id.isNotEmpty) {
              coursesMap[course.id] = course;
            }
          }
        } else if (response.statusCode != 404) {
          if (firstErrorCode == null) {
            firstErrorCode = response.statusCode;
            try {
              final errObj = json.decode(response.body);
              firstErrorMessage = errObj['error']?['message'] ?? response.body;
            } catch (_) {
              firstErrorMessage = response.body;
            }
          }
        }
      } catch (e) {
        debugPrint('Error fetching courses from $url: $e');
      }
    }

    // If no courses were found and an authorization or server error occurred, throw it
    if (coursesMap.isEmpty && firstErrorCode != null && (firstErrorCode == 401 || firstErrorCode == 403)) {
      throw Exception('Google Classroom Error ($firstErrorCode): $firstErrorMessage');
    }

    return coursesMap.values.toList();
  }

  Future<List<ClassroomCourseWork>> fetchCourseWork(String courseId) async {
    final headers = await _getAuthHeaders(allowPrompt: false);
    final uri = Uri.parse(
      'https://classroom.googleapis.com/v1/courses/$courseId/courseWork',
    );
    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final list = data['courseWork'] as List<dynamic>? ?? [];
      return list.map((w) => ClassroomCourseWork.fromJson(w as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load coursework (${response.statusCode})');
    }
  }

  Future<List<ClassroomAnnouncement>> fetchAnnouncements(String courseId) async {
    final headers = await _getAuthHeaders(allowPrompt: false);
    final uri = Uri.parse(
      'https://classroom.googleapis.com/v1/courses/$courseId/announcements',
    );
    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final list = data['announcements'] as List<dynamic>? ?? [];
      return list.map((a) => ClassroomAnnouncement.fromJson(a as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load announcements (${response.statusCode})');
    }
  }
}
