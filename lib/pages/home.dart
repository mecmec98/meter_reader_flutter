import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import 'package:meter_reader_flutter/pages/databasepage.dart';
import 'package:meter_reader_flutter/pages/appsettingspage.dart';

import 'package:meter_reader_flutter/helpers/blueprinter_helper.dart';
import 'package:meter_reader_flutter/helpers/database_helper.dart';
import 'package:meter_reader_flutter/pages/databasedrawer.dart';

import 'package:meter_reader_flutter/widgets/printerfab_widget.dart';
import 'package:meter_reader_flutter/widgets/pin_dialog.dart';

class HomePage extends StatefulWidget {
  HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool isBluetoothOn = false;
  Map<String, int>? _readingStats;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initBluetooth();
      _loadReadingStats();
    });
  }

  void _initBluetooth() async {
    final bluetoothHelper = context.read<BluePrinterHelper>();
    isBluetoothOn = (await bluetoothHelper.bluetooth.isOn)!;

    if (!isBluetoothOn) {
      _showBluetoothDialog();
    } else {
      await bluetoothHelper.initBluetooth();
    }
  }

  Future<void> _loadReadingStats() async {
    final stats = await DatabaseHelper().getReadingStats();
    if (!mounted) return;
    setState(() => _readingStats = stats);
  }

  void _showBluetoothDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Bluetooth Required"),
          content: const Text("Please turn on Bluetooth to proceed."),
          actions: <Widget>[
            TextButton(
              child: const Text("OK"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: appBar(context),
      floatingActionButton: const PrinterFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      drawer: Databasedrawer(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          if (_readingStats != null) _buildStatsCard(),
          const SizedBox(height: 16),
          menuButtons(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    final stats = _readingStats!;
    final total = stats['total'] ?? 0;
    final completed = stats['completed'] ?? 0;
    final remaining = stats['remaining'] ?? 0;
    final progress = total > 0 ? completed / total : 0.0;
    final percentText = total > 0 ? '${(progress * 100).toStringAsFixed(0)}%' : '0%';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart_rounded, size: 20, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Reading Progress',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Text(
                  '$completed / $total',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _statChip(
                  icon: Icons.check_circle_outline,
                  label: '$completed Completed',
                  color: Colors.green,
                ),
                const SizedBox(width: 12),
                _statChip(
                  icon: Icons.pending_outlined,
                  label: '$remaining Remaining',
                  color: Colors.orange,
                ),
                const Spacer(),
                Text(
                  percentText,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black45,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  Column menuButtons() {
    double screenWidth = MediaQuery.of(context).size.width;
    double buttonPadding = screenWidth * 0.08;
    double iconSize = screenWidth * 0.09;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            '',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
              letterSpacing: 0.8,
            ),
          ),
        ),
        _menuButton(
          padding: buttonPadding,
          iconSize: iconSize,
          iconPath: 'assets/icons/reading.svg',
          color: const Color.fromARGB(255, 28, 85, 227),
          label: 'Post Meter Reading',
          description: 'Record new meter readings for consumers',
          onTap: () => Navigator.pushNamed(context, '/postmeterreading'),
        ),
        const SizedBox(height: 14),
        _menuButton(
          padding: buttonPadding,
          iconSize: iconSize,
          iconPath: 'assets/icons/edit.svg',
          color: const Color.fromARGB(255, 28, 117, 227),
          label: 'Edit Meter Reading',
          description: 'Modify previously saved meter readings',
          onTap: () => Navigator.pushNamed(context, '/editbilllist'),
        ),
        const SizedBox(height: 14),
        _menuButton(
          padding: buttonPadding,
          iconSize: iconSize,
          iconPath: 'assets/icons/print.svg',
          color: const Color.fromARGB(255, 28, 137, 227),
          label: 'Print Bill',
          description: 'Print billing statements for completed readings',
          onTap: () => Navigator.pushNamed(context, '/printbilllist'),
        ),
      ],
    );
  }

  Widget _menuButton({
    required double padding,
    required double iconSize,
    required String iconPath,
    required Color color,
    required String label,
    required String description,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(padding * 0.5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: color,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    iconPath,
                    height: iconSize,
                    width: iconSize,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withOpacity(0.6),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  AppBar appBar(BuildContext context) {
    final bluetoothHelper = context.watch<BluePrinterHelper>();
    return AppBar(
      title: const Text(
        'Home',
        style: TextStyle(
          color: Colors.black,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      leading: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DatabasePage()),
          );
        },
        child: Container(
          margin: const EdgeInsets.all(10),
          alignment: Alignment.center,
          child: SvgPicture.asset(
            'assets/icons/database.svg',
            height: 25,
            width: 25,
            colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
          ),
        ),
      ),
      actions: [
        GestureDetector(
          onTap: () async {
            final granted = await showPinDialog(context);
            if (granted && context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AppSettingsPage()),
              );
            }
          },
          child: Container(
            margin: const EdgeInsets.all(10),
            width: 37,
            alignment: Alignment.center,
            child: const Icon(Icons.settings_outlined, color: Colors.black),
          ),
        ),
      ],
    );
  }
}
