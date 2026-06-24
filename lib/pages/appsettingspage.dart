import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:meter_reader_flutter/helpers/appsettings_helper.dart';
import 'package:meter_reader_flutter/models/features_model.dart';
import 'package:meter_reader_flutter/models/databaselog_model.dart';
import 'package:meter_reader_flutter/models/serversettings_model.dart';

class AppSettingsPage extends StatefulWidget {
  const AppSettingsPage({super.key});

  @override
  State<AppSettingsPage> createState() => _AppSettingsPageState();
}

class _AppSettingsPageState extends State<AppSettingsPage> {
  final AppSettingsHelper _settingsHelper = AppSettingsHelper();
  List<FeatureModel> _features = [];
  List<DatabaseLogModel> _logs = [];
  ServerSettingsModel? _server;
  bool _loading = true;

  // Server settings controllers
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController();

  // Ping state
  bool _pinging = false;
  bool? _pingSuccess;
  String _pingMessage = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final features = await _settingsHelper.getAllFeatures();
    final logs = await _settingsHelper.getLogs();
    final server = await _settingsHelper.getServerSettings();
    if (!mounted) return;
    setState(() {
      _features = features;
      _logs = logs;
      _server = server;
      _ipController.text = server.ip;
      _portController.text = server.port.toString();
      _loading = false;
    });
  }

  Future<void> _toggle(String key, bool value) async {
    await _settingsHelper.setFeature(key, value);
    await _loadData();
  }

  Future<void> _saveServerSettings() async {
    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 8765;
    if (ip.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a server IP address')),
      );
      return;
    }
    await _settingsHelper.saveServerSettings(ip: ip, port: port);
    if (!mounted) return;
    setState(() => _pingSuccess = null);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Server settings saved')),
    );
  }

  Future<void> _pingServer() async {
    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 8765;
    if (ip.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter an IP address first')),
      );
      return;
    }
    setState(() {
      _pinging = true;
      _pingSuccess = null;
      _pingMessage = '';
    });
    try {
      final uri = Uri.parse('http://$ip:$port/ping');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (!mounted) return;
      if (response.statusCode == 200 &&
          response.body.contains('MRA_SERVER_OK')) {
        setState(() {
          _pingSuccess = true;
          _pingMessage = 'Server is reachable at $ip:$port';
        });
      } else {
        setState(() {
          _pingSuccess = false;
          _pingMessage = 'Server responded but returned an unexpected response';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _pingSuccess = false;
        _pingMessage = 'Could not reach server at $ip:$port';
      });
    } finally {
      if (mounted) setState(() => _pinging = false);
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        title: const Text(
          'App Settings',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Server Settings ────────────────────────
                const _SectionLabel(label: 'Server Settings'),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black.withOpacity(0.08)),
                  ),
                  child: Column(
                    children: [
                      // IP field
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                        child: TextField(
                          controller: _ipController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Server IP Address',
                            hintText: '192.168.1.1',
                            prefixIcon: const Icon(Icons.computer_outlined,
                                color: Colors.blue, size: 20),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.blue),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                          onChanged: (_) => setState(() => _pingSuccess = null),
                        ),
                      ),
                      // Port field
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                        child: TextField(
                          controller: _portController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Server Port',
                            hintText: '8765',
                            prefixIcon: const Icon(Icons.lan_outlined,
                                color: Colors.blue, size: 20),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.blue),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                          onChanged: (_) => setState(() => _pingSuccess = null),
                        ),
                      ),
                      const Divider(height: 1, thickness: 0.5),
                      // Ping status
                      if (_pingSuccess != null)
                        Container(
                          margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _pingSuccess!
                                ? Colors.green.withOpacity(0.08)
                                : Colors.red.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _pingSuccess!
                                  ? Colors.green.shade300
                                  : Colors.red.shade300,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _pingSuccess!
                                    ? Icons.check_circle_outline
                                    : Icons.error_outline,
                                size: 16,
                                color: _pingSuccess!
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _pingMessage,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: _pingSuccess!
                                        ? Colors.green.shade700
                                        : Colors.red.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Buttons
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _pinging ? null : _pingServer,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.blue,
                                  side: const BorderSide(color: Colors.blue),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: _pinging
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2, color: Colors.blue),
                                      )
                                    : const Icon(Icons.wifi_find_outlined,
                                        size: 16),
                                label: Text(
                                  _pinging ? 'Pinging...' : 'Test Connection',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _saveServerSettings,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.save_outlined, size: 16),
                                label: const Text(
                                  'Save',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Features ──────────────────────────────
                const _SectionLabel(label: 'Features'),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black.withOpacity(0.08)),
                  ),
                  child: Column(
                    children: _features.asMap().entries.map((entry) {
                      final index = entry.key;
                      final feature = entry.value;
                      final isLast = index == _features.length - 1;

                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        feature.label,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        feature.enabled
                                            ? 'Enabled'
                                            : 'Disabled',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: feature.enabled
                                              ? Colors.blue
                                              : Colors.black45,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: feature.enabled,
                                  activeColor: Colors.blue,
                                  onChanged: (val) => _toggle(feature.key, val),
                                ),
                              ],
                            ),
                          ),
                          if (!isLast)
                            const Divider(
                                height: 1, thickness: 0.5, indent: 14),
                        ],
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Database Logs ──────────────────────────
                Row(
                  children: [
                    const _SectionLabel(label: 'Database Logs'),
                    const Spacer(),
                    if (_logs.isNotEmpty)
                      Text(
                        '${_logs.length} entries',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black45,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                _logs.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Colors.black.withOpacity(0.08)),
                        ),
                        child: const Center(
                          child: Text(
                            'No logs yet',
                            style:
                                TextStyle(fontSize: 13, color: Colors.black45),
                          ),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Colors.black.withOpacity(0.08)),
                        ),
                        child: Column(
                          children: [
                            // Table header
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.07),
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12)),
                              ),
                              child: const Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'Date & Time',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      'Type',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      'Method',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1, thickness: 0.5),
                            // Table rows
                            ..._logs.asMap().entries.map((entry) {
                              final index = entry.key;
                              final log = entry.value;
                              final isLast = index == _logs.length - 1;
                              final isUpload = log.type == 'upload';
                              final isWireless = log.method == 'wireless';

                              return Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 10),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            _formatDateTime(log.datetime),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: isUpload
                                                  ? Colors.green
                                                      .withOpacity(0.1)
                                                  : Colors.blue
                                                      .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              isUpload ? 'Upload' : 'Download',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: isUpload
                                                    ? Colors.green.shade700
                                                    : Colors.blue.shade700,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Icon(
                                                isWireless
                                                    ? Icons.wifi
                                                    : Icons.usb_outlined,
                                                size: 13,
                                                color: Colors.black45,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                isWireless
                                                    ? 'Wireless'
                                                    : 'Manual',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!isLast)
                                    const Divider(
                                        height: 1, thickness: 0.5, indent: 14),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                const SizedBox(height: 20),
              ],
            ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

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
