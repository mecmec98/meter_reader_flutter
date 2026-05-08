import 'package:flutter/material.dart';
import 'databasepage/currentreadinginfo.dart';
import 'databasepage/wirelesstransfer.dart';
import 'databasepage/manualtransfer.dart';

import 'package:meter_reader_flutter/models/prefs_model.dart';
import 'package:meter_reader_flutter/helpers/database_helper.dart';
import 'package:meter_reader_flutter/helpers/appsettings_helper.dart';

import 'package:file_picker/file_picker.dart';

class DatabasePage extends StatefulWidget {
  const DatabasePage({super.key});

  @override
  State<DatabasePage> createState() => _DatabasePageState();
}

class _DatabasePageState extends State<DatabasePage> {
  // Reading data — replace with your actual model/provider
  String? _readingDate = '--';
  String? _reader = '--';
  List<String> _zones = [];
  List<String> _books = [];

  bool wirelessUploaded = false;
  bool wirelessDownloaded = false;
  String? wirelessUploadTime;
  String? wirelessDownloadTime;

  bool manualUploaded = false;
  bool manualDownloaded = false;
  String? manualUploadTime;
  String? manualDownloadTime;

  @override
  void initState() {
    super.initState();
    _fetchDataprefs();
    _fetchZoneBook();
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

    // Split each ZB into zone and book then deduplicate
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

  void _handleWirelessUpload() {
    AppSettingsHelper().addLog(type: 'upload', method: 'wireless');
    final time = TimeOfDay.now().format(context);
    setState(() {
      wirelessUploaded = true;
      wirelessUploadTime = time;
    });
  }

  void _handleWirelessDownload() {
    AppSettingsHelper().addLog(type: 'download', method: 'wireless');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        title: const Text(
          'Reading data',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel(label: 'Current reading info'),
            const SizedBox(height: 8),
            CurrentReadingInfo(
              readingDate: _readingDate ?? "",
              reader: _reader ?? "",
              zone: _zones,
              book: _books,
            ),
            const SizedBox(height: 20),
            const SectionLabel(label: 'Transfer'),
            const SizedBox(height: 8),
            WirelessTransfer(
              onUpload: _handleWirelessUpload,
              onDownload: _handleWirelessDownload,
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
          ],
        ),
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
