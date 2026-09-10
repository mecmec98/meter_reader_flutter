import 'package:flutter/material.dart';
import 'package:meter_reader_flutter/helpers/blueprinter_helper.dart';
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
                _buildDetailRow('Months Overdue', _editedItem.months.toString(),
                    valueColor: Colors.orange.shade800),
                _buildDetailRow('Last Reading', _editedItem.lrdg.toString()),
                const SizedBox(height: 4),
                const Divider(height: 1),
                const SizedBox(height: 12),
                _buildInputField(
                  controller: _readingController,
                  label: 'Disconnection Reading',
                  keyboardType: TextInputType.number,
                ),
                _buildDropdown(),
                _buildInputField(
                  controller: _remarksController,
                  label: 'Remarks',
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _saveDetails(context),
                        icon: const Icon(Icons.save_outlined, size: 18),
                        label: const Text('Save'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
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
                        onPressed: () => _printNotice(context),
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
                  ],
                ),
                const SizedBox(height: 8),
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFF8F8F8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: DropdownButtonFormField<String>(
        initialValue: _meterStatus,
        decoration: InputDecoration(
          labelText: 'Meter Status',
          filled: true,
          fillColor: const Color(0xFFF8F8F8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        items: _meterStatuses
            .map((status) =>
                DropdownMenuItem(value: status, child: Text(status)))
            .toList(),
        onChanged: (status) {
          if (status != null) setState(() => _meterStatus = status);
        },
      ),
    );
  }

  void _updateEditedItem() {
    final reading = int.tryParse(_readingController.text.trim());
    _editedItem = _editedItem.copyWith(
      disconReading: reading ?? _editedItem.disconReading,
      metStat: _meterStatus,
      remarks: _remarksController.text.trim(),
    );
  }

  Future<void> _saveDetails(BuildContext context) async {
    _updateEditedItem();
    await NoticeHelper().updateNoticeDetails(_editedItem);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notice details saved')),
    );
  }

  Future<void> _printNotice(BuildContext context) async {
    try {
      _updateEditedItem();
      await NoticeHelper().updateNoticeDetails(_editedItem);
      await context
          .read<BluePrinterHelper>()
          .printDisconnection(_asDisconnection(_editedItem));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Details saved and notice printed')),
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