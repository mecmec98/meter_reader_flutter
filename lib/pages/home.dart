import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:meter_reader_flutter/helpers/blueprinter_helper.dart';
import 'package:meter_reader_flutter/pages/databasedrawer.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool isBluetoothOn = false;

  @override
  void initState() {
    super.initState();
    // Run bluetooth init after frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initBluetooth();
      //helloword
    });
  }

  void _initBluetooth() async {
    final bluetoothHelper = context.read<BluePrinterHelper>();

    //print(bluetoothHelper.connected);
    isBluetoothOn = (await bluetoothHelper.bluetooth.isOn)!;

    if (!isBluetoothOn) {
      _showBluetoothDialog();
    } else {
      await bluetoothHelper.initBluetooth();
      //print(bluetoothHelper.connected);
    }
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
      endDrawer: drawerforPrinter(context),
      drawer: Databasedrawer(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          menuButtons(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Drawer drawerforPrinter(BuildContext context) {
    final bluetoothHelper = context.watch<BluePrinterHelper>();

    return Drawer(
      child: Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.only(top: 60),
            child: Text(
              'Connect Printer',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 25),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              await bluetoothHelper.initBluetooth();
            },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(Colors.blue),
            ),
            icon: const Icon(Icons.bluetooth, color: Colors.white),
            label: const Text(
              'Refresh Devices',
              style:
                  TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
          const Text('Select Bluetooth Device'),
          DropdownButton<BluetoothDevice>(
            items: bluetoothHelper.devices
                .map((device) => DropdownMenuItem(
                      value: device,
                      child: Text(device.name ?? "Unknown Device"),
                    ))
                .toList(),
            onChanged: (device) {
              if (device != null) {
                bluetoothHelper.selectedDevice = device;
              }
            },
            value: bluetoothHelper.selectedDevice,
          ),
          ElevatedButton.icon(
            onPressed: bluetoothHelper.connected
                ? () async {
                    await bluetoothHelper.disconnectFromDevice();
                  }
                : () async {
                    if (bluetoothHelper.selectedDevice != null) {
                      await bluetoothHelper
                          .connectToDevice(bluetoothHelper.selectedDevice!);
                    }
                  },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(Colors.blue),
            ),
            label: Text(
              bluetoothHelper.connected ? 'Disconnect' : 'Connect',
              style:
                  TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
          // Connection status display
          Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bluetoothHelper.connected
                  ? Colors.green.shade100
                  : Colors.red.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: bluetoothHelper.connected ? Colors.green : Colors.red,
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Status: ${bluetoothHelper.connectionStatus}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: bluetoothHelper.connected
                        ? Colors.green.shade800
                        : Colors.red.shade800,
                  ),
                ),
                if (bluetoothHelper.isReconnecting)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              ],
            ),
          ),
          // Manual reconnect button
          if (!bluetoothHelper.connected &&
              bluetoothHelper.selectedDevice != null)
            ElevatedButton.icon(
              onPressed: bluetoothHelper.isReconnecting
                  ? null
                  : () async {
                      await bluetoothHelper.manualReconnect();
                    },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.orange),
              ),
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text(
                'Manual Reconnect',
                style:
                    TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

// Adjust for less wider screens sizes
  Column menuButtons() {
    double screenWidth = MediaQuery.of(context).size.width;
    double buttonPadding = screenWidth * 0.12;
    double iconSize = screenWidth * 0.11;
    double fontSize = screenWidth * 0.052;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 10.0, right: 10.0),
          child: Text(
            '',
            style: TextStyle(
              color: Colors.black,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 1),
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Post Meter Reading
            Padding(
              padding: EdgeInsets.only(
                  top: 1, right: buttonPadding, left: buttonPadding),
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/postmeterreading');
                },
                child: Container(
                  height: 100,
                  padding: EdgeInsets.all(screenWidth * 0.045),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: const Color.fromARGB(255, 28, 85, 227),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/icons/reading.svg',
                          height: iconSize,
                          width: iconSize,
                          colorFilter: const ColorFilter.mode(
                              Color.fromARGB(255, 245, 243, 243),
                              BlendMode.srcIn),
                        ),
                        SizedBox(width: screenWidth * 0.015),
                        Text(
                          'Post Meter Reading',
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Edit Meter Reading
            Padding(
              padding: EdgeInsets.only(
                  top: 20, right: buttonPadding, left: buttonPadding),
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/editbilllist');
                },
                child: Container(
                  height: 100,
                  padding: EdgeInsets.all(screenWidth * 0.045),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: const Color.fromARGB(255, 28, 117, 227),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/icons/edit.svg',
                          height: iconSize,
                          width: iconSize,
                          colorFilter: const ColorFilter.mode(
                              Color.fromARGB(255, 245, 243, 243),
                              BlendMode.srcIn),
                        ),
                        SizedBox(width: screenWidth * 0.015),
                        Text(
                          'Edit Meter Reading',
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Print Bill
            Padding(
              padding: EdgeInsets.only(
                  top: 20, right: buttonPadding, left: buttonPadding),
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/printbilllist');
                },
                child: Container(
                  height: 100,
                  padding: EdgeInsets.all(screenWidth * 0.045),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: const Color.fromARGB(255, 28, 137, 227),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/icons/print.svg',
                          height: iconSize,
                          width: iconSize,
                          colorFilter: const ColorFilter.mode(
                              Color.fromARGB(255, 245, 243, 243),
                              BlendMode.srcIn),
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        Text(
                          'Print Bill',
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        )
      ],
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
        onTap: () => _scaffoldKey.currentState?.openDrawer(),
        child: Container(
          margin: const EdgeInsets.all(10),
          alignment: Alignment.center,
          child: SvgPicture.asset(
            'assets/icons/menu.svg',
            height: 25,
            width: 25,
            colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
          ),
        ),
      ),
      actions: [
        GestureDetector(
          onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
          child: Container(
            margin: const EdgeInsets.all(10),
            width: 37,
            alignment: Alignment.center,
            child: SvgPicture.asset(
              'assets/icons/print.svg',
              height: 25,
              width: 25,
              colorFilter: ColorFilter.mode(
                  bluetoothHelper.connected ? Colors.green : Colors.black,
                  BlendMode.srcIn),
            ),
          ),
        )
      ],
    );
  }
}
