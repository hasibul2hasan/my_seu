import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_config.dart';
import '../services/classroom_service.dart';

class ClassroomTab extends StatefulWidget {
  const ClassroomTab({super.key});

  @override
  State<ClassroomTab> createState() => _ClassroomTabState();
}

class _ClassroomTabState extends State<ClassroomTab>
    with AutomaticKeepAliveClientMixin {
  bool _initializing = true;
  bool _loadingCourses = false;
  String? _errorMessage;
  List<ClassroomCourse> _courses = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoad();
  }

  Future<void> _checkAuthAndLoad() async {
    setState(() => _initializing = true);
    await ClassroomService.instance.init();
    if (mounted) {
      setState(() => _initializing = false);
      if (ClassroomService.instance.isSignedIn) {
        _loadCourses();
      }
    }
  }

  Future<void> _loadCourses() async {
    setState(() {
      _loadingCourses = true;
      _errorMessage = null;
    });

    try {
      final courses = await ClassroomService.instance.fetchCourses();
      if (mounted) {
        setState(() {
          _courses = courses;
          _loadingCourses = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _loadingCourses = false;
        });
      }
    }
  }

  Future<void> _handleSignIn() async {
    setState(() {
      _loadingCourses = true;
      _errorMessage = null;
    });

    try {
      final account = await ClassroomService.instance.signIn();
      if (account != null && mounted) {
        await _loadCourses();
      } else if (mounted) {
        setState(() => _loadingCourses = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Sign in failed: ${e.toString().replaceFirst("Exception: ", "")}';
          _loadingCourses = false;
        });
      }
    }
  }

  Future<void> _handleSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to disconnect Google Classroom?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ClassroomService.instance.signOut();
      if (mounted) {
        setState(() {
          _courses = [];
          _errorMessage = null;
        });
      }
    }
  }

  Future<void> _openUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showCourseDetails(ClassroomCourse course) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CourseDetailsSheet(course: course),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_initializing) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!ClassroomService.instance.isSignedIn) {
      return _buildSignedOutView();
    }

    return _buildSignedInView();
  }

  Widget _buildSignedOutView() {
    final hasClientId = AppConfig.hasClassroomClient;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF25A244).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      size: 44,
                      color: Color(0xFF1E8238),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Google Classroom',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Connect your student Google account to see your enrolled SEU courses, assignments, and class announcements directly inside the app.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (!hasClientId) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber.shade700.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.amber.shade800, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'CLASSROOM_CLIENT_ID is not set in .env. Configure OAuth in Google Cloud Console to enable native in-app sign in.',
                              style: TextStyle(color: Colors.amber.shade900, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1E8238),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _loadingCourses ? null : _handleSignIn,
                      icon: _loadingCourses
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.login_rounded),
                      label: Text(
                        _loadingCourses ? 'Connecting...' : 'Sign in with Google',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _openUrl('https://classroom.google.com'),
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: const Text('Open in Browser'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignedInView() {
    final user = ClassroomService.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: _loadCourses,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Student Profile Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: const Color(0xFF1E8238),
                          backgroundImage: user?.photoUrl != null
                              ? NetworkImage(user!.photoUrl!)
                              : null,
                          child: user?.photoUrl == null
                              ? Text(
                                  (user?.displayName ?? 'S')[0].toUpperCase(),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                )
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.displayName ?? 'Student',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                user?.email ?? '',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded),
                          tooltip: 'Reload Courses',
                          onPressed: _loadingCourses ? null : _loadCourses,
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                          tooltip: 'Sign Out',
                          onPressed: _handleSignOut,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Courses Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Enrolled Courses',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (!_loadingCourses)
                      Text(
                        '${_courses.length} active',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                  ],
                ),
              ),
            ),

            // Loading / Error / Empty / List State
            if (_loadingCourses)
              const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading your enrolled courses...'),
                    ],
                  ),
                ),
              )
            else if (_errorMessage != null)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 54, color: Colors.redAccent),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14, color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _loadCourses,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (_courses.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text(
                        'No active courses found',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Join a class in Google Classroom to see it here.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final course = _courses[index];
                      return _buildCourseCard(course);
                    },
                    childCount: _courses.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseCard(ClassroomCourse course) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showCourseDetails(course),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Accent Banner
            Container(
              height: 6,
              width: double.infinity,
              color: const Color(0xFF1E8238),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          course.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.open_in_new_rounded, size: 20),
                        tooltip: 'Open in Classroom',
                        onPressed: () => _openUrl(course.alternateLink),
                      ),
                    ],
                  ),
                  if (course.descriptionHeading != null &&
                      course.descriptionHeading!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      course.descriptionHeading!,
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (course.section != null && course.section!.isNotEmpty)
                        Chip(
                          avatar: const Icon(Icons.group_outlined, size: 16),
                          label: Text(course.section!),
                          backgroundColor: Colors.grey.withValues(alpha: 0.1),
                          padding: EdgeInsets.zero,
                          labelStyle: const TextStyle(fontSize: 12),
                        ),
                      if (course.room != null && course.room!.isNotEmpty)
                        Chip(
                          avatar: const Icon(Icons.room_outlined, size: 16),
                          label: Text(course.room!),
                          backgroundColor: Colors.grey.withValues(alpha: 0.1),
                          padding: EdgeInsets.zero,
                          labelStyle: const TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _showCourseDetails(course),
                        icon: const Icon(Icons.assignment_outlined, size: 18),
                        label: const Text('Assignments & Info'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseDetailsSheet extends StatefulWidget {
  final ClassroomCourse course;
  const _CourseDetailsSheet({required this.course});

  @override
  State<_CourseDetailsSheet> createState() => _CourseDetailsSheetState();
}

class _CourseDetailsSheetState extends State<_CourseDetailsSheet> {
  bool _loading = true;
  String? _error;
  List<ClassroomCourseWork> _courseWork = [];
  List<ClassroomAnnouncement> _announcements = [];

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final work = await ClassroomService.instance.fetchCourseWork(widget.course.id);
      final ann = await ClassroomService.instance.fetchAnnouncements(widget.course.id);
      if (mounted) {
        setState(() {
          _courseWork = work;
          _announcements = ann;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  Future<void> _openUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.course.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const TabBar(
                  tabs: [
                    Tab(icon: Icon(Icons.assignment_outlined), text: 'Assignments'),
                    Tab(icon: Icon(Icons.campaign_outlined), text: 'Announcements'),
                  ],
                ),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.error_outline, color: Colors.red, size: 40),
                                    const SizedBox(height: 12),
                                    Text(_error!, textAlign: TextAlign.center),
                                    const SizedBox(height: 12),
                                    FilledButton(
                                      onPressed: _loadDetails,
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : TabBarView(
                              children: [
                                _buildWorkList(scrollController),
                                _buildAnnouncementsList(scrollController),
                              ],
                            ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWorkList(ScrollController controller) {
    if (_courseWork.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.task_alt_outlined, size: 54, color: Colors.grey[400]),
            const SizedBox(height: 12),
            const Text('No assignments posted yet', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.all(16),
      itemCount: _courseWork.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final w = _courseWork[i];
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFE8F5E9),
              child: Icon(Icons.assignment, color: Color(0xFF1E8238)),
            ),
            title: Text(w.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (w.dueDate != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 14, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text('Due: ${w.dueDate!}', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
                if (w.maxPoints != null) ...[
                  const SizedBox(height: 2),
                  Text('${w.maxPoints} points', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.open_in_new, size: 18),
              tooltip: 'Open in Classroom',
              onPressed: () => _openUrl(w.alternateLink),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnnouncementsList(ScrollController controller) {
    if (_announcements.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none_outlined, size: 54, color: Colors.grey[400]),
            const SizedBox(height: 12),
            const Text('No announcements posted yet', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.all(16),
      itemCount: _announcements.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final a = _announcements[i];
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 14,
                      backgroundColor: Color(0xFFE3F2FD),
                      child: Icon(Icons.campaign, size: 16, color: Colors.blue),
                    ),
                    const SizedBox(width: 8),
                    const Text('Announcement', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const Spacer(),
                    if (a.alternateLink != null)
                      IconButton(
                        icon: const Icon(Icons.open_in_new, size: 16),
                        onPressed: () => _openUrl(a.alternateLink),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(a.text, style: const TextStyle(fontSize: 14, height: 1.4)),
              ],
            ),
          ),
        );
      },
    );
  }
}
