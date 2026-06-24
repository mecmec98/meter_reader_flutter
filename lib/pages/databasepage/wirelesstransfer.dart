import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:meter_reader_flutter/helpers/appsettings_helper.dart';
import 'package:meter_reader_flutter/helpers/database_helper.dart';
import 'package:meter_reader_flutter/models/prefs_model.dart';
import 'package:meter_reader_flutter/models/serversettings_model.dart';
import 'package:path_provider/path_provider.dart';

class WirelessTransfer extends StatefulWidget {
  final VoidCallback onUpload;
  final VoidCallback onDownload;
  final Future<void> Function() onRefresh;
  final bool uploaded;
  final bool downloaded;
  final String? uploadTime;
  final String? downloadTime;

  const WirelessTransfer({
    super.key,
    required this.onUpload,
    required this.onDownload,
    required this.onRefresh,
    required this.uploaded,
    required this.downloaded,
    this.uploadTime,
    this.downloadTime,
  });

  @override
  State<WirelessTransfer> createState() => _WirelessTransferState();
}

class _WirelessTransferState extends State<WirelessTransfer> {
  bool _uploadLoading = false;

  // Download panel state
  bool _showDownloadPanel = false;
  bool _pinging = false;
  bool? _pingSuccess;
  List<String> _dates = [];
  String _selectedDate = '';
  List<String> _files = [];
  bool _loadingFiles = false;
  bool _downloading = false;
  double _downloadProgress = 0;
  String _downloadingFile = '';
  String? _errorMessage;

  final AppSettingsHelper _settingsHelper = AppSettingsHelper();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  String get _today => DateTime.now().toIso8601String().split('T')[0];

  // ─────────────────────────────────────────
  // Upload
  // ─────────────────────────────────────────
  Future<void> _handleUpload() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Reading Data'),
        content: const Text(
            'This will upload your completed reading data to the server. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.red)),
            child: const Text('No', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.green)),
            child: const Text('Yes', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _uploadLoading = true);
    try {
      final settings = await _settingsHelper.getServerSettings();
      final prefs = await PrefsModel.fetch();
      if (prefs == null || prefs.readername.isEmpty) {
        _showSnack('No reader data found. Download a database first.');
        return;
      }
      final readerName = _sanitize(prefs.readername);
      final dbPath = await _dbHelper.getDatabasePath();
      final dbFile = File(dbPath);
      if (!await dbFile.exists()) {
        _showSnack('Database file not found.');
        return;
      }
      final uri = Uri.parse(
          'http://${settings.ip}:${settings.port}/upload?reader=$readerName&date=$_today');
      final bytes = await dbFile.readAsBytes();
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/octet-stream'},
        body: bytes,
      ).timeout(const Duration(seconds: 30));
      if (!mounted) return;
      if (response.statusCode == 200) {
        await _settingsHelper.addLog(type: 'upload', method: 'wireless');
        widget.onUpload();
        _showSnack('Data uploaded successfully.');
      } else {
        _showSnack('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack('Could not reach server.');
    } finally {
      if (mounted) setState(() => _uploadLoading = false);
    }
  }

  // ─────────────────────────────────────────
  // Download panel
  // ─────────────────────────────────────────
  Future<void> _handleDownloadTap() async {
    if (_showDownloadPanel) {
      setState(() {
        _showDownloadPanel = false;
        _resetDownloadPanel();
      });
      return;
    }
    setState(() {
      _showDownloadPanel = true;
      _resetDownloadPanel();
    });
    await _ping();
  }

  void _resetDownloadPanel() {
    _pinging = false;
    _pingSuccess = null;
    _dates = [];
    _selectedDate = '';
    _files = [];
    _loadingFiles = false;
    _downloading = false;
    _downloadProgress = 0;
    _downloadingFile = '';
    _errorMessage = null;
  }

  Future<ServerSettingsModel> _getSettings() =>
      _settingsHelper.getServerSettings();

  Future<void> _ping() async {
    setState(() => _pinging = true);
    try {
      final settings = await _getSettings();
      final response = await http
          .get(Uri.parse(
              'http://${settings.ip}:${settings.port}/ping'))
          .timeout(const Duration(seconds: 5));
      if (!mounted) return;
      if (response.statusCode == 200 &&
          response.body.contains('MRA_SERVER_OK')) {
        setState(() {
          _pingSuccess = true;
          _pinging = false;
        });
        await _loadDates();
      } else {
        setState(() {
          _pingSuccess = false;
          _pinging = false;
          _errorMessage = 'Server responded unexpectedly.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _pingSuccess = false;
        _pinging = false;
        _errorMessage =
            'Cannot reach server. Make sure it is running and you are on the same Wi-Fi.';
      });
    }
  }

  Future<void> _loadDates() async {
    try {
      final settings = await _getSettings();
      final response = await http
          .get(Uri.parse(
              'http://${settings.ip}:${settings.port}/dates'))
          .timeout(const Duration(seconds: 5));
      if (!mounted) return;
      final data = json.decode(response.body);
      final dates = List<String>.from(data['dates'] ?? []);
      setState(() {
        _dates = dates;
        _selectedDate =
            dates.contains(_today) ? _today : (dates.isNotEmpty ? dates.first : '');
      });
      if (_selectedDate.isNotEmpty) await _loadFiles(_selectedDate);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Failed to load available dates.');
    }
  }

  Future<void> _loadFiles(String date) async {
    setState(() {
      _loadingFiles = true;
      _selectedDate = date;
      _files = [];
    });
    try {
      final settings = await _getSettings();
      final response = await http
          .get(Uri.parse(
              'http://${settings.ip}:${settings.port}/files?date=$date'))
          .timeout(const Duration(seconds: 5));
      if (!mounted) return;
      final data = json.decode(response.body);
      setState(() {
        _files = List<String>.from(data['files'] ?? []);
        _loadingFiles = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingFiles = false;
        _errorMessage = 'Failed to load files for $date.';
      });
    }
  }

  Future<void> _downloadFile(String filename) async {
    setState(() {
      _downloadingFile = filename;
      _downloading = true;
      _downloadProgress = 0;
    });
    try {
      final settings = await _getSettings();
      final uri = Uri.parse(
          'http://${settings.ip}:${settings.port}/download?date=$_selectedDate&file=${Uri.encodeComponent(filename)}');
      final request = http.Request('GET', uri);
      final response =
          await request.send().timeout(const Duration(seconds: 60));
      if (response.statusCode != 200) {
        setState(() {
          _downloading = false;
          _errorMessage = 'Server returned error ${response.statusCode}';
        });
        return;
      }
      final contentLength = response.contentLength ?? 0;
      final bytes = <int>[];
      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
        if (contentLength > 0 && mounted) {
          setState(() => _downloadProgress = bytes.length / contentLength);
        }
      }
      if (!mounted) return;
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_import.dbi');
      await tempFile.writeAsBytes(bytes);
      final success = await _dbHelper.importNewDatabase(tempFile.path);
      await tempFile.delete();
      if (!mounted) return;
      if (success) {
        await widget.onRefresh();
        await _settingsHelper.addLog(type: 'download', method: 'wireless');
        widget.onDownload();
        setState(() {
          _downloading = false;
          _showDownloadPanel = false;
          _resetDownloadPanel();
        });
        _showSnack('$filename imported successfully.');
      } else {
        setState(() {
          _downloading = false;
          _errorMessage = 'Failed to import the downloaded database.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _downloading = false;
        _errorMessage = 'Download failed: $e';
      });
    }
  }

  String _sanitize(String name) =>
      name.trim().toLowerCase().replaceAll(' ', '_');

  void _showSnack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Main wireless card ─────────────────
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black.withOpacity(0.08)),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.wifi, size: 20, color: Colors.blue),
                    const SizedBox(width: 10),
                    const Text(
                      'Wireless',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 207, 228, 255),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Wi-Fi',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 0.5),

              // Buttons
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: _TransferButton(
                        label: 'Upload',
                        icon: Icons.upload_outlined,
                        filled: true,
                        color: Colors.blue,
                        loading: _uploadLoading,
                        onPressed: _handleUpload,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _TransferButton(
                        label: _showDownloadPanel ? 'Cancel' : 'Download',
                        icon: _showDownloadPanel
                            ? Icons.close
                            : Icons.download_outlined,
                        filled: false,
                        color: Colors.blue,
                        loading: false,
                        onPressed: _handleDownloadTap,
                      ),
                    ),
                  ],
                ),
              ),

              // Status indicators
              if (widget.uploaded)
                _StatusRow(
                  icon: Icons.check_circle_outline,
                  iconColor: const Color(0xFF1D9E75),
                  message: 'Data uploaded successfully',
                  textColor: const Color(0xFF0F6E56),
                  time: widget.uploadTime,
                ),
              if (widget.downloaded)
                _StatusRow(
                  icon: Icons.check_circle_outline,
                  iconColor: Colors.blue,
                  message: 'File downloaded successfully',
                  textColor: Colors.blue,
                  time: widget.downloadTime,
                ),
            ],
          ),
        ),

        // ── Download panel ─────────────────────
        if (_showDownloadPanel) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withOpacity(0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Panel header
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.download_outlined,
                          size: 18, color: Colors.blue),
                      const SizedBox(width: 8),
                      const Text(
                        'Download Reading Data',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 0.5),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Ping status
                      _buildPingStatus(),

                      if (_pingSuccess == true) ...[
                        const SizedBox(height: 16),

                        // ── Date chips
                        const Text(
                          'SELECT DATE',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.black45,
                              letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 8),
                        _dates.isEmpty
                            ? const Text('No dates available.',
                                style: TextStyle(
                                    fontSize: 13, color: Colors.black45))
                            : SizedBox(
                                height: 36,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _dates.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 8),
                                  itemBuilder: (context, index) {
                                    final d = _dates[index];
                                    final isSelected = d == _selectedDate;
                                    final isToday = d == _today;
                                    return GestureDetector(
                                      onTap: _loadingFiles || _downloading
                                          ? null
                                          : () => _loadFiles(d),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? Colors.blue
                                              : Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: isSelected
                                                ? Colors.blue
                                                : Colors.black
                                                    .withOpacity(0.12),
                                          ),
                                        ),
                                        child: Text(
                                          isToday ? 'Today' : d,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.black87,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),

                        const SizedBox(height: 16),

                        // ── File list
                        const Text(
                          'SELECT FILE',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.black45,
                              letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 8),
                        _buildFileList(),
                      ],

                      // ── Error
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.red.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 16, color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () {
                            setState(() => _errorMessage = null);
                            _ping();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black87,
                            side: BorderSide(
                                color: Colors.black.withOpacity(0.2)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Retry',
                              style: TextStyle(fontSize: 13)),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPingStatus() {
    if (_pinging) {
      return const Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.blue),
          ),
          SizedBox(width: 10),
          Text('Connecting to server...',
              style: TextStyle(fontSize: 13, color: Colors.black54)),
        ],
      );
    }
    if (_pingSuccess == true) {
      return const Row(
        children: [
          Icon(Icons.circle, size: 10, color: Colors.green),
          SizedBox(width: 8),
          Text('Server connected',
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.green,
                  fontWeight: FontWeight.w500)),
        ],
      );
    }
    if (_pingSuccess == false) {
      return const Row(
        children: [
          Icon(Icons.circle, size: 10, color: Colors.red),
          SizedBox(width: 8),
          Text('Server unreachable',
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.red,
                  fontWeight: FontWeight.w500)),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildFileList() {
    if (_loadingFiles) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.blue),
            ),
            SizedBox(width: 10),
            Text('Loading files...',
                style: TextStyle(fontSize: 13, color: Colors.black54)),
          ],
        ),
      );
    }
    if (_downloading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Downloading $_downloadingFile...',
              style:
                  const TextStyle(fontSize: 13, color: Colors.black54)),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _downloadProgress > 0 ? _downloadProgress : null,
            backgroundColor: Colors.black.withOpacity(0.08),
            color: Colors.blue,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 4),
          Text(
            _downloadProgress > 0
                ? '${(_downloadProgress * 100).toStringAsFixed(0)}%'
                : 'Starting...',
            style: const TextStyle(fontSize: 11, color: Colors.black45),
          ),
        ],
      );
    }
    if (_files.isEmpty) {
      return const Text('No files available for this date.',
          style: TextStyle(fontSize: 13, color: Colors.black45));
    }
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black.withOpacity(0.08)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: _files.asMap().entries.map((entry) {
          final index = entry.key;
          final file = entry.value;
          final isLast = index == _files.length - 1;
          return Column(
            children: [
              InkWell(
                onTap: () => _downloadFile(file),
                borderRadius: isLast
                    ? const BorderRadius.vertical(
                        bottom: Radius.circular(8))
                    : BorderRadius.zero,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.storage_outlined,
                          size: 18, color: Colors.blue),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          file,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87),
                        ),
                      ),
                      const Icon(Icons.download_outlined,
                          size: 16, color: Colors.black38),
                    ],
                  ),
                ),
              ),
              if (!isLast)
                const Divider(height: 1, thickness: 0.5, indent: 12),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Shared widgets
// ─────────────────────────────────────────
class _TransferButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final Color color;
  final bool loading;
  final VoidCallback onPressed;

  const _TransferButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.color,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return ElevatedButton.icon(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        icon: loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : Icon(icon, size: 16),
        label: Text(loading ? 'Uploading...' : label,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500)),
      );
    } else {
      return OutlinedButton.icon(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black87,
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: BorderSide(color: Colors.black.withOpacity(0.2)),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
        ),
        icon: loading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black.withOpacity(0.5)))
            : Icon(icon, size: 16),
        label: Text(loading ? 'Downloading...' : label,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500)),
      );
    }
  }
}

class _StatusRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String message;
  final Color textColor;
  final String? time;

  const _StatusRow({
    required this.icon,
    required this.iconColor,
    required this.message,
    required this.textColor,
    this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(height: 1, thickness: 0.5),
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Text(message,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: textColor)),
              if (time != null) ...[
                const Spacer(),
                Text(time!,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.black45)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}