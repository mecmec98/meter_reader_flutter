import 'package:flutter/material.dart';
import 'databasepage/currentreadinginfo.dart';
import 'databasepage/wirelesstransfer.dart';
import 'databasepage/manualtransfer.dart';
import 'databasepage/disconnection_import.dart';
import 'databasepage/notice_import.dart';
import 'package:http/http.dart' as http;

import 'package:meter_reader_flutter/models/prefs_model.dart';
import 'package:meter_reader_flutter/helpers/database_helper.dart';
import 'package:meter_reader_flutter/helpers/appsettings_helper.dart';

class DatabasePage extends StatefulWidget {
  const DatabasePage({super.key});

  @override
  State<DatabasePage> createState() => _DatabasePageState();
}

class _DatabasePageState extends State<DatabasePage> {
  final PageController _pageController = PageController();
  final TextEditingController _assignedPersonController =
      TextEditingController();
  int _selectedSection = 0;
  String _assignedPerson = '';

  String? _readingDate = '--';
  String? _reader = '--';
  List<String> _zones = [];
  List<String> _books = [];

  bool wirelessUploaded = false;
  bool wirelessDownloaded = false;
  bool _serverOnline = false;
  String? wirelessUploadTime;
  String? wirelessDownloadTime;

  bool manualUploaded = false;
  bool manualDownloaded = false;
  String? manualUploadTime;
  String? manualDownloadTime;

  bool disconnectionImported = false;
  String? disconnectionImportTime;

  bool noticeImported = false;
  String? noticeImportTime;

  @override
  void initState() {
    super.initState();
    _fetchDataprefs();
    _fetchZoneBook();
    _pingServer();
    _loadAssignedPerson();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _assignedPersonController.dispose();
    super.dispose();
  }

  Future<void> _pingServer() async {
    try {
      final settings = await AppSettingsHelper().getServerSettings();
      final response = await http
          .get(Uri.parse('http://${settings.ip}:${settings.port}/ping'))
          .timeout(const Duration(seconds: 5));
      if (!mounted) return;
      setState(() {
        _serverOnline = response.statusCode == 200 &&
            response.body.contains('MRA_SERVER_OK');
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _serverOnline = false);
    }
  }

  Future<void> _fetchDataprefs() async {
    final fetchedPrefs = await PrefsModel.fetch();
    if (!mounted) return;
    setState(() {
      _reader = fetchedPrefs?.readername ?? '';
      _readingDate = fetchedPrefs?.billdate ?? '';
    });
  }

  Future<void> _fetchZoneBook() async {
    final zbList = await DatabaseHelper().getDistinctZB();
    if (!mounted) return;
    final zones = zbList.map((zb) => zb.substring(0, 2)).toSet().toList()
      ..sort();
    final books = zbList.map((zb) => zb.substring(2)).toSet().toList()..sort();
    setState(() {
      _zones = zones;
      _books = books;
    });
  }

  Future<void> _refreshAll() async {
    await _fetchDataprefs();
    await _fetchZoneBook();
  }

  Future<void> _loadAssignedPerson() async {
    final assignedPerson = await AppSettingsHelper().getAssignedPerson();
    if (!mounted) return;
    _assignedPersonController.text = assignedPerson;
    setState(() => _assignedPerson = assignedPerson);
  }

  void _handleWirelessUpload() {
    final time = TimeOfDay.now().format(context);
    setState(() {
      wirelessUploaded = true;
      wirelessUploadTime = time;
    });
  }

  void _handleWirelessDownload() {
    final time = TimeOfDay.now().format(context);
    setState(() {
      wirelessDownloaded = true;
      wirelessDownloadTime = time;
    });
  }

  void _handleManualUpload() {
    AppSettingsHelper().addLog(type: 'upload', method: 'manual');
    final time = TimeOfDay.now().format(context);
    setState(() {
      manualUploaded = true;
      manualUploadTime = time;
    });
  }

  void _handleManualDownload() {
    AppSettingsHelper().addLog(type: 'download', method: 'manual');
    final time = TimeOfDay.now().format(context);
    setState(() {
      manualDownloaded = true;
      manualDownloadTime = time;
    });
  }

  void _handleDisconnectionImport() {
    final time = TimeOfDay.now().format(context);
    setState(() {
      disconnectionImported = true;
      disconnectionImportTime = time;
    });
  }

  void _handleNoticeImport() {
    final time = TimeOfDay.now().format(context);
    setState(() {
      noticeImported = true;
      noticeImportTime = time;
    });
  }

  Future<void> _saveAssignedPerson() async {
    final assignedPerson = _assignedPersonController.text.trim();
    if (assignedPerson.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an assigned person')),
      );
      return;
    }

    await AppSettingsHelper().saveAssignedPerson(assignedPerson);
    if (!mounted) return;
    setState(() => _assignedPerson = assignedPerson);
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Assigned person saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        title: const Text(
          'Database Settings',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        elevation: 0,
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _selectedSection = index);
        },
        children: [
          _buildReadingSettingsPage(),
          _buildDisconnectionSettingsPage(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFFCF7),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.black.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BottomNavigationBar(
                currentIndex: _selectedSection,
                onTap: (index) {
                  setState(() => _selectedSection = index);
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                  );
                },
                backgroundColor: Colors.transparent,
                elevation: 0,
                type: BottomNavigationBarType.fixed,
                selectedItemColor: _selectedSection == 0
                    ? const Color(0xFF1565C0)
                    : Colors.orange.shade800,
                unselectedItemColor: const Color(0xFF8A8178),
                selectedLabelStyle: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600),
                unselectedLabelStyle: const TextStyle(fontSize: 12),
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.storage_outlined),
                    activeIcon: Icon(Icons.storage),
                    label: 'Reading Data',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.warning_amber_outlined),
                    activeIcon: Icon(Icons.warning_amber),
                    label: 'Notice & Disconnection',
                  ),
                ],
              ),
              const SizedBox(height: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadingSettingsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel(label: 'Current reading info'),
          const SizedBox(height: 8),
          CurrentReadingInfo(
            readingDate: _readingDate ?? '',
            reader: _reader ?? '',
            zone: _zones,
            book: _books,
          ),
          const SizedBox(height: 20),
          const SectionLabel(label: 'Transfer'),
          const SizedBox(height: 8),
          WirelessTransfer(
            serverOnline: _serverOnline,
            onUpload: _handleWirelessUpload,
            onDownload: _handleWirelessDownload,
            onRefresh: _refreshAll,
            uploaded: wirelessUploaded,
            downloaded: wirelessDownloaded,
            uploadTime: wirelessUploadTime,
            downloadTime: wirelessDownloadTime,
          ),
          const SizedBox(height: 12),
          ManualTransfer(
            onUpload: _handleManualUpload,
            onDownload: _handleManualDownload,
            onRefresh: _refreshAll,
            uploaded: manualUploaded,
            downloaded: manualDownloaded,
            uploadTime: manualUploadTime,
            downloadTime: manualDownloadTime,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDisconnectionSettingsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel(label: 'Assignment'),
          const SizedBox(height: 8),
          _buildAssignedPersonCard(),
          const SizedBox(height: 20),
          const SectionLabel(label: 'Disconnection'),
          const SizedBox(height: 8),
          DisconnectionImport(
            onImported: _handleDisconnectionImport,
            imported: disconnectionImported,
            importTime: disconnectionImportTime,
          ),
          const SizedBox(height: 20),
          const SectionLabel(label: 'Notice'),
          const SizedBox(height: 8),
          NoticeImport(
            onImported: _handleNoticeImport,
            imported: noticeImported,
            importTime: noticeImportTime,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAssignedPersonCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _assignedPersonController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Assigned Person',
              hintText: 'Enter the assigned person',
              prefixIcon: const Icon(Icons.person_outline),
              filled: true,
              fillColor: const Color(0xFFF8F8F8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saveAssignedPerson,
              icon: const Icon(Icons.save_outlined, size: 18),
              label: const Text('Save Assigned Person'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
            ),
          ),
          if (_assignedPerson.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Currently assigned to $_assignedPerson',
              style: const TextStyle(fontSize: 12, color: Color(0xFF1565C0)),
            ),
          ],
        ],
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  final String label;
  const SectionLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Colors.black54,
        letterSpacing: 0.8,
      ),
    );
  }
}
