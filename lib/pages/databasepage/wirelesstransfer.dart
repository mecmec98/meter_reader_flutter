import 'package:flutter/material.dart';

class WirelessTransfer extends StatefulWidget {
  final VoidCallback onUpload;
  final VoidCallback onDownload;
  final bool uploaded;
  final bool downloaded;
  final String? uploadTime;
  final String? downloadTime;

  const WirelessTransfer({
    super.key,
    required this.onUpload,
    required this.onDownload,
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
  bool _downloadLoading = false;

  Future<void> _handleUpload() async {
    setState(() => _uploadLoading = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    setState(() => _uploadLoading = false);
    widget.onUpload();
  }

  Future<void> _handleDownload() async {
    setState(() => _downloadLoading = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    setState(() => _downloadLoading = false);
    widget.onDownload();
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
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.wifi, size: 20, color: Colors.blue),
                const SizedBox(width: 10),
                const Text(
                  'Wireless',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 207, 228, 255),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Wi-Fi',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue,
                    ),
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
                    label: 'Download',
                    icon: Icons.download_outlined,
                    filled: false,
                    color: const Color(0xFF1D9E75),
                    loading: _downloadLoading,
                    onPressed: _handleDownload,
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
              iconColor: const Color(0xFF378ADD),
              message: 'File downloaded successfully',
              textColor: const Color(0xFF185FA5),
              time: widget.downloadTime,
            ),
        ],
      ),
    );
  }
}

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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
        label: Text(loading ? 'Uploading...' : label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      );
    } else {
      return OutlinedButton.icon(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black87,
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: BorderSide(color: Colors.black.withOpacity(0.2)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: loading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.black.withOpacity(0.5)),
              )
            : Icon(icon, size: 16),
        label: Text(loading ? 'Downloading...' : label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Text(
                message,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
              if (time != null) ...[
                const Spacer(),
                Text(
                  time!,
                  style: const TextStyle(fontSize: 11, color: Colors.black45),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}