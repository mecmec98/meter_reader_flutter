import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:meter_reader_flutter/helpers/blueprinter_helper.dart';
import 'package:provider/provider.dart';

class PrinterFab extends StatefulWidget {
  const PrinterFab({super.key});

  @override
  State<PrinterFab> createState() => _PrinterFabState();
}

class _PrinterFabState extends State<PrinterFab> {
  bool _isOpen = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  void _toggle() {
    if (_isOpen) {
      _close();
    } else {
      _open();
    }
  }

  void _open() {
    _overlayEntry = _buildOverlay();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _close() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() => _isOpen = false);
  }

  OverlayEntry _buildOverlay() {
    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Tap outside to dismiss
          Positioned.fill(
            child: GestureDetector(
              onTap: _close,
              behavior: HitTestBehavior.translucent,
              child: const SizedBox.expand(),
            ),
          ),
          // Popup card anchored above the FAB
          Positioned(
            bottom: 80,
            right: 16,
            child: Material(
              color: Colors.transparent,
              child: _PrinterPopupCard(onClose: _close),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bluetoothHelper = context.watch<BluePrinterHelper>();

    final isConnected = bluetoothHelper.connected;

    return CompositedTransformTarget(
      link: _layerLink,
      child: FloatingActionButton(
        backgroundColor: isConnected ? Colors.green : Colors.white,
        foregroundColor: isConnected ? Colors.white : Colors.black,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isConnected ? Colors.green : Colors.black,
            width: 1.5,
          ),
        ),
        onPressed: _toggle,
        child: Icon(
          _isOpen ? Icons.close : Icons.print_outlined,
        ),
      ),
    );
  }
}

class _PrinterPopupCard extends StatelessWidget {
  final VoidCallback onClose;

  const _PrinterPopupCard({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final bluetoothHelper = context.watch<BluePrinterHelper>();

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.black.withOpacity(0.07)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 4),
            child: Row(
              children: [
                const Icon(Icons.print_outlined, size: 18, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Connect Printer',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onClose,
                  icon:
                      const Icon(Icons.close, size: 18, color: Colors.black45),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 0.5),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Refresh button
                ElevatedButton.icon(
                  onPressed: () async {
                    await bluetoothHelper.initBluetooth();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.bluetooth, size: 16),
                  label: const Text(
                    'Refresh Devices',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 10),

                // Device dropdown
                const Text(
                  'Select Bluetooth Device',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black.withOpacity(0.15)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: bluetoothHelper.devices.isEmpty
                      ? const Center(
                          child: Text(
                            'No devices found',
                            style:
                                TextStyle(fontSize: 13, color: Colors.black45),
                          ),
                        )
                      : Builder(
                          builder: (context) {
                            final sortedDevices = [...bluetoothHelper.devices]
                              ..sort((a, b) =>
                                  (a.name ?? '').compareTo(b.name ?? ''));

                            return SingleChildScrollView(
                              child: Column(
                                children:
                                    sortedDevices.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final device = entry.value;
                                  final isSelected =
                                      bluetoothHelper.selectedDevice == device;
                                  final isLast =
                                      index == sortedDevices.length - 1;

                                  return Column(
                                    children: [
                                      InkWell(
                                        onTap: () => bluetoothHelper
                                            .selectedDevice = device,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 10),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.bluetooth,
                                                size: 16,
                                                color: isSelected
                                                    ? Colors.blue
                                                    : Colors.black38,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  device.name ??
                                                      'Unknown Device',
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: isSelected
                                                        ? FontWeight.w600
                                                        : FontWeight.normal,
                                                    color: isSelected
                                                        ? Colors.blue
                                                        : Colors.black87,
                                                  ),
                                                ),
                                              ),
                                              if (isSelected)
                                                const Icon(Icons.check,
                                                    size: 16,
                                                    color: Colors.blue),
                                            ],
                                          ),
                                        ),
                                      ),
                                      if (!isLast)
                                        const Divider(
                                            height: 1,
                                            thickness: 0.5,
                                            indent: 12),
                                    ],
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        ),
                ),

                const SizedBox(height: 10),

                // Connect / Disconnect button
                ElevatedButton.icon(
                  onPressed: bluetoothHelper.connected
                      ? () async {
                          await bluetoothHelper.disconnectFromDevice();
                        }
                      : () async {
                          if (bluetoothHelper.selectedDevice != null) {
                            await bluetoothHelper.connectToDevice(
                                bluetoothHelper.selectedDevice!);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: Icon(
                    bluetoothHelper.connected
                        ? Icons.bluetooth_disabled
                        : Icons.bluetooth_connected,
                    size: 16,
                  ),
                  label: Text(
                    bluetoothHelper.connected ? 'Disconnect' : 'Connect',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 10),

                // Status indicator
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: bluetoothHelper.connected
                        ? Colors.green.shade100
                        : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          bluetoothHelper.connected ? Colors.green : Colors.red,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Status: ${bluetoothHelper.connectionStatus}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: bluetoothHelper.connected
                              ? Colors.green.shade800
                              : Colors.red.shade800,
                        ),
                      ),
                      if (bluetoothHelper.isReconnecting)
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                    ],
                  ),
                ),

                // Manual reconnect button
                if (!bluetoothHelper.connected &&
                    bluetoothHelper.selectedDevice != null) ...[
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: bluetoothHelper.isReconnecting
                        ? null
                        : () async {
                            await bluetoothHelper.manualReconnect();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text(
                      'Manual Reconnect',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
