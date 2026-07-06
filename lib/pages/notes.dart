import 'package:flutter/material.dart';
import 'package:meter_reader_flutter/helpers/database_helper.dart';
import 'package:meter_reader_flutter/helpers/notes_helper.dart';
import 'package:meter_reader_flutter/models/prefs_model.dart';
import 'package:meter_reader_flutter/pages/consumer_note_details.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  String _reader = '--';
  String _readingDate = '--';
  List<String> _zones = [];
  List<String> _books = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> _noteSummaries = [];
  List<Map<String, dynamic>> _filteredSummaries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await PrefsModel.fetch();
    final zbList = await DatabaseHelper().getDistinctZB();
    final summaries = await NotesHelper().getNoteSummaries();
    final enriched = <Map<String, dynamic>>[];
    for (final s in summaries) {
      final consumer = await DatabaseHelper().getConsumerByMasCode(s['mas_code'] as int);
      if (consumer != null) {
        enriched.add({
          'mas_code': s['mas_code'],
          'note_count': s['note_count'],
          'name': consumer['NAME'] ?? '',
          'acc1': consumer['ACC1'] ?? '',
          'zb': consumer['ZB'] ?? '',
          'clsssz': consumer['CLSSSZ'] ?? '',
        });
      }
    }
    if (!mounted) return;
    setState(() {
      _reader = prefs?.readername ?? '--';
      _readingDate = prefs?.billdate ?? '--';
      _zones = zbList.map((zb) => zb.substring(0, 2)).toSet().toList()..sort();
      _books = zbList.map((zb) => zb.substring(2)).toSet().toList()..sort();
      _noteSummaries = enriched;
      _filteredSummaries = enriched;
      _loading = false;
    });
  }

  void _filter(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredSummaries = _noteSummaries;
      } else {
        final q = query.toLowerCase();
        _filteredSummaries = _noteSummaries.where((s) {
          final accno = '${s['zb']}-${s['clsssz']}-${s['acc1']}'.toLowerCase();
          return (s['name'] as String).toLowerCase().contains(q) ||
                 accno.contains(q) ||
                 s['mas_code'].toString().contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        title: const Text(
          'Notes',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard(),
                const SizedBox(height: 16),
                _buildSearchBar(),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildNotesList()),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.person_outline,
            label: 'Reader',
            value: _reader,
            showDivider: true,
          ),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Billing date',
            value: _readingDate,
            showDivider: true,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                Expanded(child: _buildChipColumn(Icons.location_on_outlined, 'Zone', _zones)),
                const SizedBox(width: 16),
                Expanded(child: _buildChipColumn(Icons.menu_book_outlined, 'Book', _books)),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by consumer name, account no, or MAS code',
          hintStyle: const TextStyle(color: Color.fromARGB(255, 195, 186, 186), fontSize: 13),
          filled: true,
          fillColor: Colors.white,
          prefixIcon: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(Icons.search, color: Colors.grey.shade500, size: 20),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onChanged: (value) {
          _filter(value);
        },
      ),
    );
  }

  Widget _buildNotesList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_filteredSummaries.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isEmpty ? 'No notes yet' : 'No notes found',
          style: const TextStyle(color: Colors.black45, fontSize: 14),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredSummaries.length,
      itemBuilder: (context, index) {
        final item = _filteredSummaries[index];
        final accno = '${item['zb']}-${item['clsssz']}-${item['acc1']}';
        final count = item['note_count'] as int;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Colors.black.withOpacity(0.08)),
          ),
          child: ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ConsumerNoteDetailsPage(
                    masCode: item['mas_code'] as int,
                    name: item['name'] as String,
                    accno: accno,
                  ),
                ),
              );
            },
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            title: Text(
              item['name'] as String,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            subtitle: Text(
              accno,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$count note${count == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChipColumn(IconData icon, String label, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.green),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],
        ),
        const SizedBox(height: 6),
        items.isEmpty
            ? const Text('--', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87))
            : Wrap(
                spacing: 6,
                runSpacing: 4,
                children: items
                    .map((item) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.green.withOpacity(0.3)),
                          ),
                          child: Text(
                            item,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ))
                    .toList(),
              ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool showDivider;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              Icon(icon, size: 18, color: Colors.green),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1, thickness: 0.5, indent: 14, endIndent: 14),
      ],
    );
  }
}
