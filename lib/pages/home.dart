import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:meter_reader_flutter/helpers/blueprinter_helper.dart';
//import 'package:meter_reader_flutter/helpers/database_helper.dart';

//import 'package:path/path.dart';
// import 'dart:io';
// import 'package:meter_reader_flutter/pages/postmeterreading.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:sqflite/sqflite.dart';
// import 'package:meter_reader_flutter/models/category_model.dart';
// import 'package:file_picker/file_picker.dart';

class HomePage extends StatefulWidget {
  HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  BluePrinterHelper bluetoothHelper = BluePrinterHelper();
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  bool _connected = false;
  bool isBluetoothOn = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
  }

  void _initBluetooth() async {
    isBluetoothOn = (await bluetoothHelper.bluetooth.isOn)!;
    if (!isBluetoothOn) {
      _showBluetoothDialog();
    } else {
      await bluetoothHelper.initBluetooth();
      setState(() {
        _devices = bluetoothHelper.devices;
        _connected = bluetoothHelper.connected;
      });
    }
  }

  void _showBluetoothDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Bluetooth Required"),
          content: Text("Please turn on Bluetooth to proceed."),
          actions: <Widget>[
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _connectToDevice() async {
    if (_selectedDevice != null) {
      await bluetoothHelper
          .connectToDevice(_selectedDevice!); // Connect to the selected device
      setState(() {
        _connected = bluetoothHelper.connected; // Update the connection status
      });
    }
  }

  void _disconnectFromDevice() async {
    await bluetoothHelper.disconnectFromDevice(); // Disconnect from the device
    setState(() {
      _connected = bluetoothHelper.connected; // Update the connection status
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: appBar(),
      endDrawer: drawerforPrinter(),
      drawer: drawrforUpload(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //searchBar(),
          SizedBox(
            height: 20,
          ),
          menuButtons(),
          SizedBox(
            height: 20,
          ),
        ],
      ),
    );
  }

  Drawer drawrforUpload() {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            child: Text('Upload Data'),
          )
        ],
      ),
    );
  }

  Drawer drawerforPrinter() {
    return Drawer(
      child: Column(
        children: <Widget>[
          DrawerHeader(
            //decoration: BoxDecoration(color: Colors.blue),
            child: Text(
              'Connect Printer',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: _initBluetooth,
            child: Text("Scan Bluetooth Devices"),
          ),
          DropdownButton<BluetoothDevice>(
            items: _devices
                .map((device) => DropdownMenuItem(
                      value: device,
                      child: Text(device.name!), // Display device name
                    ))
                .toList(),
            onChanged: (device) {
              setState(() {
                _selectedDevice = device; // Update the selected device
              });
              _connectToDevice(); // Connect to the selected device
            },
            value: _selectedDevice, // Set the selected device
          ),
          ElevatedButton(
            onPressed: _connected
                ? _disconnectFromDevice
                : _connectToDevice, // Button to connect or disconnect
            child: Text(_connected ? 'Disconnect' : 'Connect'), // Button text
          ),
          Text(
            'Printer is ${_connected ? "Disconnected" : "Connected"}', // Display connection status
          ),
        ],
      ),
    );
  }

  Column menuButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10.0, right: 10.0),
          child: Text(
            '',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 1,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            //Post Meter Reading
            Padding(
              padding: EdgeInsets.only(top: 1, right: 50, left: 50),
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/postmeterreading');
                },
                child: Container(
                  height: 100,
                  padding: EdgeInsets.all(20),
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
                          height: 50,
                          width: 50,
                          colorFilter: const ColorFilter.mode(
                              Color.fromARGB(255, 245, 243, 243),
                              BlendMode.srcIn),
                        ),
                        SizedBox(
                          width: 5,
                        ),
                        Text(
                          'Post Meter Reading',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            //Edit Meter Reading
            Padding(
                padding: EdgeInsets.only(top: 20, right: 50, left: 50),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/sample');
                  },
                  child: Container(
                    height: 100,
                    padding: EdgeInsets.all(20),
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
                            height: 50,
                            width: 50,
                            colorFilter: const ColorFilter.mode(
                                Color.fromARGB(255, 245, 243, 243),
                                BlendMode.srcIn),
                          ),
                          SizedBox(
                            width: 5,
                          ),
                          Text(
                            'Edit Meter Reading',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                )),
            //Print Bill
            Padding(
              padding: EdgeInsets.only(top: 20, right: 50, left: 50),
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/printbilllist');
                },
                child: Container(
                  height: 100,
                  padding: EdgeInsets.all(20),
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
                          height: 50,
                          width: 50,
                          colorFilter: const ColorFilter.mode(
                              Color.fromARGB(255, 245, 243, 243),
                              BlendMode.srcIn),
                        ),
                        SizedBox(
                          width: 15,
                        ),
                        Text(
                          'Print Bill',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
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

  AppBar appBar() {
    return AppBar(
      //backgroundColor: Colors.white,
      //elevation: 5.0,
      title: Text(
        'Home',
        style: TextStyle(
          color: Colors.black,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      leading: GestureDetector(
        onTap: () {},
        child: Container(
          margin: EdgeInsets.all(10),
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
          onTap: () {
            _scaffoldKey.currentState?.openEndDrawer();
          },
          child: Container(
            margin: EdgeInsets.all(10),
            width: 37,
            alignment: Alignment.center,
            child: SvgPicture.asset(
              'assets/icons/print.svg',
              height: 25,
              width: 25,
              colorFilter: ColorFilter.mode(
                  _connected ? Colors.green : Colors.black, BlendMode.srcIn),
            ),
          ),
        )
      ],
    );
  }
}
