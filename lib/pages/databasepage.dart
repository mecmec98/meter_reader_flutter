import 'package:flutter/material.dart';
import 'databasepage/currentreadinginfo.dart';
import 'databasepage/wirelesstransfer.dart';
import 'databasepage/manualtransfer.dart';
 
class DatabasePage extends StatefulWidget {
  const DatabasePage({super.key});
 
  @override
  State<DatabasePage> createState() => _DatabasePageState();
}
 
class _DatabasePageState extends State<DatabasePage> {
  // Reading data — replace with your actual model/provider
  final String readingDate = 'May 6, 2026';
  final String reader = 'Juan dela Cruz';
  final String zone = 'Zone A — North';
  final String book = 'Book 04';
 
  bool wirelessUploaded = false;
  bool wirelessDownloaded = false;
  String? wirelessUploadTime;
  String? wirelessDownloadTime;
 
  bool manualUploaded = false;
  bool manualDownloaded = false;
  String? manualUploadTime;
  String? manualDownloadTime;
 
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
    final time = TimeOfDay.now().format(context);
    setState(() {
      manualUploaded = true;
      manualUploadTime = time;
    });
  }
 
  void _handleManualDownload() {
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
        backgroundColor:  Colors.blue,
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
              readingDate: readingDate,
              reader: reader,
              zone: zone,
              book: book,
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