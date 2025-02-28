import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:meter_reader_flutter/helpers/blueprinter_helper.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  BluePrinterHelper bluetoothHelper = BluePrinterHelper();
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  bool _connected = false;

  @override
  void initState() {
    super.initState();
    _initBluetooth();
  }

  void _initBluetooth() async {
    await bluetoothHelper.initBluetooth();
    setState(() {
      _devices = bluetoothHelper.devices;
      _connected = bluetoothHelper.connected;
    });
  }

  void _connectToDevice() async {
    if (_selectedDevice != null) {
      await bluetoothHelper.connectToDevice(_selectedDevice!);
      setState(() {
        _connected = bluetoothHelper.connected;
      });
    }
  }

  void _disconnectFromDevice() async {
    await bluetoothHelper.disconnectFromDevice();
    setState(() {
      _connected = bluetoothHelper.connected;
    });
  }

  void _printSampleReceipt() async {
    //await bluetoothHelper.printSampleReceipt();
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