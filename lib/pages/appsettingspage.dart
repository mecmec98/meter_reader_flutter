import 'package:flutter/material.dart';
import 'package:meter_reader_flutter/helpers/appsettings_helper.dart';
import 'package:meter_reader_flutter/models/features_model.dart';
import 'package:meter_reader_flutter/models/databaselog_model.dart';

class AppSettingsPage extends StatefulWidget {
  const AppSettingsPage({super.key});

  @override
  State<AppSettingsPage> createState() => _AppSettingsPageState();
}

class _AppSettingsPageState extends State<AppSettingsPage> {
  final AppSettingsHelper _settingsHelper = AppSettingsHelper();
  List<FeatureModel> _features = [];
  List<DatabaseLogModel> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final features = await _settingsHelper.getAllFeatures();
    final logs = await _settingsHelper.getLogs();
    if (!mounted) return;
    setState(() {
      _features = features;
      _logs = logs;
      _loading = false;
    });
  }

  Future<void> _toggle(String key, bool value) async {
    await _settingsHelper.setFeature(key, value);
    await _loadData();
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
