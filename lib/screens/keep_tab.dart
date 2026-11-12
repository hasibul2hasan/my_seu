import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Data model ──────────────────────────────────────────────────────────────
class _Note {
  final String id;
  String title;
  String body;
  Color color;
  final DateTime createdAt;

  _Note({
    required this.id,
    required this.title,
    required this.body,
    required this.color,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'color': color.toARGB32(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory _Note.fromJson(Map<String, dynamic> j) => _Note(
        id: j['id'] as String,
        title: j['title'] as String,
        body: j['body'] as String,
        color: Color(j['color'] as int),
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}

// ─── Note colors ──────────────────────────────────────────────────────────────
const _kNoteColors = [
  Colors.white,
  Color(0xFFFFD54F), // amber
  Color(0xFF80DEEA), // cyan
  Color(0xFFA5D6A7), // green
  Color(0xFFEF9A9A), // red
  Color(0xFFCE93D8), // purple
  Color(0xFF90CAF9), // blue
];

// ─── Tab widget ───────────────────────────────────────────────────────────────
class KeepTab extends StatefulWidget {
  const KeepTab({super.key});

  @override
  _KeepTabState createState() => _KeepTabState();
}

class _KeepTabState extends State<KeepTab> with AutomaticKeepAliveClientMixin {
  static const _kPrefsKey = 'myseu_notes';

  @override
  bool get wantKeepAlive => true;

  List<_Note> _notes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  // ── Persistence ────────────────────────────────────────────────────────────
  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kPrefsKey);
    if (raw != null) {
      final list = jsonDecode(raw) as List<dynamic>;
      _notes = list.map((e) => _Note.fromJson(e as Map<String, dynamic>)).toList();
    }
    setState(() => _loading = false);
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefsKey, jsonEncode(_notes.map((n) => n.toJson()).toList()));
  }

  void _addOrEditNote({_Note? existing}) async {
    final result = await showModalBottomSheet<_Note>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NoteEditor(note: existing),
    );
    if (result == null) return;
    setState(() {
      if (existing != null) {
        final idx = _notes.indexWhere((n) => n.id == existing.id);
        if (idx != -1) _notes[idx] = result;
      } else {
        _notes.insert(0, result);
      }
    });
    await _saveNotes();
  }

  void _deleteNote(String id) async {
    setState(() => _notes.removeWhere((n) => n.id == id));
    await _saveNotes();
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_loading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            pinned: true,
            title: const Text(
              'Notes',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 24,
                color: Colors.black87,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search_rounded, color: Colors.black54),
                onPressed: () => showSearch(
                  context: context,
                  delegate: _NoteSearchDelegate(_notes, _addOrEditNote),
                ),
              ),
            ],
          ),

          if (_notes.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sticky_note_2_outlined,
                        size: 72, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'No notes yet',
                      style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap + to create your first note',
                      style:
                          TextStyle(fontSize: 14, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _NoteCard(
                    note: _notes[i],
                    onTap: () => _addOrEditNote(existing: _notes[i]),
                    onDelete: () => _deleteNote(_notes[i].id),
                  ),
                  childCount: _notes.length,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditNote(),
        backgroundColor: Colors.amber[600],
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}

// ─── Note card ────────────────────────────────────────────────────────────────
class _NoteCard extends StatelessWidget {
  final _Note note;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NoteCard({
    required this.note,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: note.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    note.title.isEmpty ? 'Untitled' : note.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
                InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close_rounded, size: 16, color: Colors.black38),
                  ),
                ),
              ],
            ),
            if (note.body.isNotEmpty) ...[
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  note.body,
                  maxLines: 6,
                  overflow: TextOverflow.fade,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ),
            ] else
              const Spacer(),
            const SizedBox(height: 8),
            Text(
              _formatDate(note.createdAt),
              style: const TextStyle(fontSize: 11, color: Colors.black38),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ─── Note editor bottom sheet ─────────────────────────────────────────────────
class _NoteEditor extends StatefulWidget {
  final _Note? note;
  const _NoteEditor({this.note});

  @override
  State<_NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<_NoteEditor> {
  late TextEditingController _titleCtrl;
  late TextEditingController _bodyCtrl;
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.note?.title ?? '');
    _bodyCtrl = TextEditingController(text: widget.note?.body ?? '');
    _selectedColor = widget.note?.color ?? Colors.white;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final note = _Note(
      id: widget.note?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleCtrl.text.trim(),
      body: _bodyCtrl.text.trim(),
      color: _selectedColor,
      createdAt: widget.note?.createdAt ?? DateTime.now(),
    );
    Navigator.of(context).pop(note);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      decoration: BoxDecoration(
        color: _selectedColor == Colors.white ? Colors.white : _selectedColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              hintText: 'Title',
              border: InputBorder.none,
              hintStyle: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black38),
            ),
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w700),
            textCapitalization: TextCapitalization.sentences,
          ),

          // Body
          TextField(
            controller: _bodyCtrl,
            decoration: const InputDecoration(
              hintText: 'Note…',
              border: InputBorder.none,
              hintStyle: TextStyle(fontSize: 15, color: Colors.black38),
            ),
            style: const TextStyle(fontSize: 15),
            maxLines: 8,
            minLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),

          const SizedBox(height: 12),

          // Color picker row
          Row(
            children: [
              ..._kNoteColors.map((c) => GestureDetector(
                    onTap: () => setState(() => _selectedColor = c),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedColor == c
                              ? Colors.black87
                              : Colors.black26,
                          width: _selectedColor == c ? 2.5 : 1,
                        ),
                      ),
                    ),
                  )),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _save,
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Search delegate ──────────────────────────────────────────────────────────
class _NoteSearchDelegate extends SearchDelegate<void> {
  final List<_Note> notes;
  final void Function({_Note? existing}) onEdit;

  _NoteSearchDelegate(this.notes, this.onEdit);

  @override
  List<Widget> buildActions(BuildContext context) =>
      [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];

  @override
  Widget buildLeading(BuildContext context) =>
      IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));

  @override
  Widget buildResults(BuildContext context) => _buildList();

  @override
  Widget buildSuggestions(BuildContext context) => _buildList();

  Widget _buildList() {
    final q = query.toLowerCase();
    final filtered = notes
        .where((n) =>
            n.title.toLowerCase().contains(q) ||
            n.body.toLowerCase().contains(q))
        .toList();

    if (filtered.isEmpty) {
      return Center(
        child: Text('No notes match "$query"',
            style: const TextStyle(color: Colors.grey)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final note = filtered[i];
        return ListTile(
          tileColor: note.color,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(note.title.isEmpty ? 'Untitled' : note.title,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle:
              note.body.isNotEmpty ? Text(note.body, maxLines: 2) : null,
          onTap: () => onEdit(existing: note),
        );
      },
    );
  }
}
