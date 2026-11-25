import 'dart:io';

import 'package:flutter/material.dart';
import 'package:meter_reader_flutter/helpers/appsettings_helper.dart';
import 'package:meter_reader_flutter/helpers/blueprinter_helper.dart';
import 'package:meter_reader_flutter/helpers/camera_helper.dart';
import 'package:meter_reader_flutter/helpers/notice_helper.dart';
import 'package:meter_reader_flutter/models/disconnection_model.dart';
import 'package:meter_reader_flutter/models/notice_model.dart';
import 'package:provider/provider.dart';

class NoticeDetailsPage extends StatefulWidget {
  final NoticeModel item;

  const NoticeDetailsPage({super.key, required this.item});

  @override
  State<NoticeDetailsPage> createState() => _NoticeDetailsPageState();
}

class _NoticeDetailsPageState extends State<NoticeDetailsPage> {
  static const _meterStatuses = [
    'N/A',
    'Padlocked',
    'Pulled Out',
    'Univ-Key',
    'Seal',
    'Plugged',
    'Tapping Pt',
    'Blind',
  ];

  late final TextEditingController _readingController;
  late final TextEditingController _remarksController;
  late String _meterStatus;
  late NoticeModel _editedItem;
  CapturedPhoto? _capturedPhoto;
  bool _photoLoading = true;
  bool _photoLoadError = false;
  final CameraHelper _cameraHelper = CameraHelper();

  @override
  void initState() {
    super.initState();
    _editedItem = widget.item;
    _readingController =
        TextEditingController(text: widget.item.disconReading.toString());
    _remarksController = TextEditingController(text: widget.item.remarks);
    _meterStatus = _meterStatuses.contains(widget.item.metStat)
        ? widget.item.metStat
        : 'N/A';
    _loadSavedPhoto();
  }

  @override
  void dispose() {
    _readingController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        title: const Text(
          'Notice Details',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildConsumerHeader(),
            const SizedBox(height: 12),
            _buildSection(
              title: 'Meter Information',
              icon: Icons.speed_outlined,
              children: [
                _buildDetailRow('Meter No.', _editedItem.metNo),
                _buildDetailRow('Brand', _editedItem.brand),
                const SizedBox(height: 4),
              ],
            ),
            const SizedBox(height: 12),
            _buildSection(
              title: 'Notice Information',
              icon: Icons.notifications_active_outlined,
              children: [
                _buildDetailRow('Notice Date', _editedItem.disconDate,
                    valueColor: Colors.orange.shade800),
                if (_editedItem.printedAt != null)
                  _buildDetailRow(
                    'Printed',
                    _editedItem.printedAt!.replaceFirst('T', ' '),
                    valueColor: const Color(0xFF2E7D32),
                  ),
                _buildDetailRow(
                  'Notice Status',
                  _noticeStatusLabel,
                  valueColor: _editedItem.noticeStatus ==
                          NoticeModel.noticeStatusPrintedWithPhoto
                      ? const Color(0xFF2E7D32)
                      : Colors.orange.shade800,
                ),
                _buildDetailRow('Months Overdue', _editedItem.months.toString(),
                    valueColor: Colors.orange.shade800),
                _buildDetailRow('Last Reading', _editedItem.lrdg.toString()),
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _photoLoading || _photoLoadError
                            ? null
                            : () => _printNotice(context),
                        icon: const Icon(Icons.print_outlined, size: 18),
                        label: const Text('Print Notice'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange.shade800,
                          side: BorderSide(color: Colors.orange.shade800),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                            _photoLoading || _editedItem.printedAt == null
                                ? null
                                : _takePhotoProof,
                        icon: const Icon(Icons.camera_alt_outlined, size: 18),
                        label: const Text('Take Photo Proof'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange.shade800,
                          side: BorderSide(color: Colors.orange.shade800),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_photoLoading)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (!_photoLoading && _capturedPhoto != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(_capturedPhoto!.path),
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _capturedPhoto!.fileName,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsumerHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(Icons.person_outline,
                    color: Colors.orange.shade800, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_editedItem.name,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 3),
                    Text(_editedItem.accNo,
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(_editedItem.address,
              style: TextStyle(
                  fontSize: 13, color: Colors.grey.shade800, height: 1.35)),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Outstanding Balance',
                  style: TextStyle(fontSize: 13, color: Colors.black54)),
              Text(_formatAmount(_editedItem.balance),
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.orange.shade800)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.orange.shade800),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(label,
                style: const TextStyle(fontSize: 13, color: Colors.black54)),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(value,
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: valueColor ?? Colors.black87)),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) => '₱${amount.toStringAsFixed(2)}';

  String get _noticeStatusLabel {
    switch (_editedItem.noticeStatus) {
      case NoticeModel.noticeStatusPrintedWithPhoto:
        return 'Printed with photo confirmation';
      case NoticeModel.noticeStatusPrinted:
        return 'Printed - photo confirmation pending';
      default:
        return 'Pending';
    }
  }

  Future<void> _loadSavedPhoto() async {
    try {
      final photos = await _cameraHelper.getPhotos(
        accountNo: _editedItem.accNo,
        category: 'notices',
      );
      if (!mounted) return;
      setState(() {
        _capturedPhoto = _editedItem.noticeStatus ==
                    NoticeModel.noticeStatusPrintedWithPhoto &&
                photos.isNotEmpty
            ? photos.first
            : null;
        _photoLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _photoLoading = false;
        _photoLoadError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to load saved photo: $error')),
      );
    }
  }

  Future<void> _takePhotoProof() async {
    if (_editedItem.printedAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Print the notice before taking proof.')),
      );
      return;
    }

    try {
      final photo = await _cameraHelper.takePhoto(
        accountNo: _editedItem.accNo,
        category: 'notices',
      );
      if (!mounted) return;
      if (photo == null) return;

      await NoticeHelper().markNoticePhotoEvidence(_editedItem.accNo);
      if (!mounted) return;
      setState(() {
        _capturedPhoto = photo;
        _photoLoadError = false;
        _editedItem = _editedItem.copyWith(
          noticeStatus: _editedItem.printedAt == null
              ? _editedItem.noticeStatus
              : NoticeModel.noticeStatusPrintedWithPhoto,
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Photo saved: ${photo.fileName}')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Camera failed: $error')),
      );
    }
  }

  void _updateEditedItem() {
    final reading = int.tryParse(_readingController.text.trim());
    _editedItem = _editedItem.copyWith(
      disconReading: reading ?? _editedItem.disconReading,
      metStat: _meterStatus,
      remarks: _remarksController.text.trim(),
    );
  }

  Future<void> _printNotice(BuildContext context) async {
    try {
      _updateEditedItem();
      await NoticeHelper().updateNoticeDetails(_editedItem);
      if (!context.mounted) return;
      final printer = context.read<BluePrinterHelper>();
      final assignedPerson = await AppSettingsHelper().getAssignedPerson();
      if (!context.mounted) return;
      if (assignedPerson.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Set the assigned person in Database settings before printing.',
            ),
          ),
        );
        return;
      }
      await printer.printDisconnection(
        _asDisconnection(_editedItem),
        assignedPerson: assignedPerson,
      );
      await NoticeHelper().markNoticePrinted(_editedItem.accNo);
      if (mounted) {
        setState(() {
          _capturedPhoto = null;
          _editedItem = _editedItem.copyWith(
            printedAt: DateTime.now().toIso8601String(),
            noticeStatus: NoticeModel.noticeStatusPrinted,
          );
        });
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notice printed. Take a photo to confirm delivery.'),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Printing failed: $error')),
        );
      }
    }
  }

  DisconnectionModel _asDisconnection(NoticeModel item) {
    return DisconnectionModel(
      id: item.id,
      accNo: item.accNo,
      name: item.name,
      address: item.address,
      metNo: item.metNo,
      brand: item.brand,
      lrdg: item.lrdg,
      months: item.months,
      oldest: item.oldest,
      balance: item.balance,
      others: item.others,
      payDate: item.payDate,
      payAmt: item.payAmt,
      months2: item.months2,
      oldest1: item.oldest1,
      masCode: item.masCode,
      metStat: item.metStat,
      disconReading: item.disconReading,
      remarks: item.remarks,
      disconDate: item.disconDate,
      optionType: item.optionType,
    );
  }
}
