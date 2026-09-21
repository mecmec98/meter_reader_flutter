import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:meter_reader_flutter/helpers/disconnection_helper.dart';
import 'package:meter_reader_flutter/models/disconnection_model.dart';

class DisconnectionImport extends StatefulWidget {
  final VoidCallback onImported;
  final bool imported;
  final String? importTime;

  const DisconnectionImport({
    super.key,
    required this.onImported,
    required this.imported,
    this.importTime,
  });

  @override
  State<DisconnectionImport> createState() => _DisconnectionImportState();
}

class _DisconnectionImportState extends State<DisconnectionImport> {
  bool _loading = false;
  bool _exportLoading = false;
  String? _error;

  Future<void> _importFromDownloads() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null ||
          result.files.single.path == null ||
          !result.files.single.name.toLowerCase().endsWith('.json')) {
        throw 'Please select a valid Disconnection.json file';
      }

      final jsonString = await File(result.files.single.path!).readAsString();
      final List<dynamic> decoded = json.decode(jsonString);

      final items = decoded
          .map((map) => DisconnectionModel.fromMap(map as Map<String, dynamic>))
          .toList();

      final helper = DisconnectionHelper();
      final count = await helper.upsertDisconnections(items);

      if (!mounted) return;
      widget.onImported();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported $count disconnection records')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to import: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _exportToDownloads() async {
    setState(() {
      _exportLoading = true;
      _error = null;
    });

    try {
      final path = await DisconnectionHelper().exportDisconnections();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported disconnection list to $path')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export disconnection list: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _exportLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.file_open_outlined,
                    size: 20, color: Color(0xFF888780)),
                const SizedBox(width: 10),
                const Text(
                  'Disconnection List',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.red,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1EFE8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.black.withOpacity(0.08)),
                  ),
                  child: const Text(
                    'Downloads',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF5F5E5A),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 0.5),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: _ImportButton(
                    label: 'Import JSON',
                    icon: Icons.upload_outlined,
                    filled: true,
                    loading: _loading,
                    onPressed: _importFromDownloads,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ImportButton(
                    label: 'Export JSON',
                    icon: Icons.download_outlined,
                    filled: false,
                    loading: _exportLoading,
                    onPressed: _exportToDownloads,
                  ),
                ),
              ],
            ),
          ),
          if (widget.imported)
            _StatusRow(
              icon: Icons.check_circle_outline,
              iconColor: const Color(0xFF1D9E75),
              message: 'Disconnection list imported',
              textColor: const Color(0xFF0F6E56),
              time: widget.importTime,
            ),
          if (_error != null)
            _StatusRow(
              icon: Icons.error_outline,
              iconColor: Colors.red,
              message: _error!,
              textColor: Colors.red,
            ),
        ],
      ),
    );
  }
}

class _ImportButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final bool loading;
  final VoidCallback onPressed;

  const _ImportButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF444441),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
      icon: loading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            )
          : Icon(icon, size: 16),
      label: Text(
        loading ? 'Importing...' : label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),
              if (time != null)
                Text(
                  time!,
                  style: const TextStyle(fontSize: 11, color: Colors.black45),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
