import 'package:flutter/material.dart';
import 'package:meter_reader_flutter/helpers/database_helper.dart';
import 'package:meter_reader_flutter/helpers/notes_helper.dart';
import 'package:meter_reader_flutter/models/consumer_note_model.dart';

class ConsumerNoteDetailsPage extends StatefulWidget {
  final int masCode;
  final String name;
  final String accno;

  const ConsumerNoteDetailsPage({
    super.key,
    required this.masCode,
    required this.name,
    required this.accno,
  });

  @override
  State<ConsumerNoteDetailsPage> createState() => _ConsumerNoteDetailsPageState();
}

class _ConsumerNoteDetailsPageState extends State<ConsumerNoteDetailsPage> {
  List<ConsumerNoteModel> _notes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final notes = await NotesHelper().getAllNotes(widget.masCode);
    if (!mounted) return;
    setState(() {
      _notes = notes;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        title: const Text('Consumer Notes', style: TextStyle(fontWeight: FontWeight.w500)),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildConsumerInfo(),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.notes_outlined, size: 18, color: Colors.black54),
                const SizedBox(width: 6),
                Text(
                  '${_notes.length} note${_notes.length == 1 ? '' : 's'}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildNotesList()),
        ],
      ),
    );
  }

  Widget _buildConsumerInfo() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.person_outline, color: Colors.green, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.accno,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotesList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_notes.isEmpty) {
      return const Center(
        child: Text('No notes for this consumer', style: TextStyle(color: Colors.black45, fontSize: 14)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _notes.length,
      itemBuilder: (context, index) {
        final note = _notes[index];
        final dateStr = _formatDate(note.createdAt);
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Colors.black.withOpacity(0.08)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 13, color: Colors.grey.shade500),
                    const SizedBox(width: 6),
                    Text(
                      dateStr,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.person_outline, size: 13, color: Colors.grey.shade500),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        note.readerName,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (note.isArchived)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Archived',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.orange),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  note.noteText,
                  style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day}/${dt.year}';
  }
}
