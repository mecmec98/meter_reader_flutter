import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  bool _connected = false;

  @override
  void initState() {
    super.initState();
    _initBluetooth();
  }

  void _initBluetooth() async {
    bool? isConnected = await bluetooth.isConnected;
    List<BluetoothDevice> devices = await bluetooth.getBondedDevices();
    setState(() {
      _devices = devices;
      _connected = isConnected!;
    });
  }

  void _connectToDevice() async {
    if (_selectedDevice != null) {
      await bluetooth.connect(_selectedDevice!);
      setState(() {
        _connected = true;
      });
    }
  }

  void _disconnectFromDevice() async {
    await bluetooth.disconnect();
    setState(() {
      _connected = false;
    });
  }

  void _printSampleReceipt() async {
    if (_connected) {
      bluetooth.printNewLine();
      bluetooth.printCustom("Sample Receipt", 3, 1);
      bluetooth.printNewLine();
      bluetooth.printCustom("Hello World!", 1, 1);
      bluetooth.printNewLine();
      bluetooth.printQRcode("Sample QR Code", 200, 200, 1);
      bluetooth.printNewLine();
      bluetooth.paperCut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Bluetooth Printer Example'),
        ),
        body: Column(
          children: <Widget>[
            DropdownButton<BluetoothDevice>(
              items: _devices
                  .map((device) => DropdownMenuItem(
                        value: device,
                        child: Text(device.name!),
                      ))
                  .toList(),
              onChanged: (device) {
                setState(() {
                  _selectedDevice = device;
                });
              },
              value: _selectedDevice,
            ),
            ElevatedButton(
              onPressed: _connected ? _disconnectFromDevice : _connectToDevice,
              child: Text(_connected ? 'Disconnect' : 'Connect'),
            ),
            ElevatedButton(
              onPressed: _connected ? _printSampleReceipt : null,
              child: Text('Print Sample Receipt'),
            ),
          ],
        ),
      ),
    );
  }
}