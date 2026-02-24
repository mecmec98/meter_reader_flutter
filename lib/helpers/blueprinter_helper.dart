import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'dart:typed_data';
import 'dart:async';

import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;

class BluePrinterHelper extends ChangeNotifier {
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  List<BluetoothDevice> devices = [];
  bool _connected = false;
  bool get connected => _connected;
  set connected(bool value) {
    _connected = value;
    notifyListeners();
  }

  // Auto-reconnection properties
  Timer? _reconnectionTimer;
  Timer? _healthCheckTimer;
  int _reconnectionAttempts = 0;
  final int _maxReconnectionAttempts = 5;
  bool _isReconnecting = false;
  bool get isReconnecting => _isReconnecting;

  // Connection state
  String _connectionStatus = 'Disconnected';
  String get connectionStatus => _connectionStatus;
  set connectionStatus(String value) {
    _connectionStatus = value;
    notifyListeners();
  }

  void listenForDisconnects() {
    bluetooth.onStateChanged().listen((state) {
      if (state == BlueThermalPrinter.DISCONNECTED) {
        connected = false;
        connectionStatus = 'Disconnected - Attempting to reconnect...';
        notifyListeners();
        // Start auto-reconnection
        _attemptReconnection();
      }
    });
  }

  BluetoothDevice? _selectedDevice;
  BluetoothDevice? get selectedDevice => _selectedDevice;
  set selectedDevice(BluetoothDevice? device) {
    _selectedDevice = device;
    notifyListeners();
  }

  Future<void> initBluetooth() async {
    devices = await bluetooth.getBondedDevices();
    notifyListeners();
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      connectionStatus = 'Connecting...';
      selectedDevice = device;
      await bluetooth.connect(device);
      connected = true;
      connectionStatus = 'Connected';
      _reconnectionAttempts = 0; // Reset attempts on successful connection
      _isReconnecting = false;
      listenForDisconnects();
      startHealthCheck();
      notifyListeners();
      print(connected);
      print('Connected successfully');
    } catch (e) {
      connected = false;
      connectionStatus = 'Connection failed';
      _isReconnecting = false;
      print('Connection failed: $e');
    }
  }

  Future<void> disconnectFromDevice() async {
    // Stop timers first
    _reconnectionTimer?.cancel();
    _healthCheckTimer?.cancel();

    if (connected) {
      try {
        await bluetooth.disconnect();
      } catch (e) {
        print('Error during disconnect: $e');
      }
    }

    connected = false;
    connectionStatus = 'Disconnected';
    selectedDevice = null;
    _isReconnecting = false;
    _reconnectionAttempts = 0;
    notifyListeners();
  }

  // Auto-reconnection method
  Future<void> _attemptReconnection() async {
    if (_isReconnecting || _reconnectionAttempts >= _maxReconnectionAttempts) {
      return;
    }

    _isReconnecting = true;
    _reconnectionAttempts++;

    connectionStatus =
        'Reconnecting... (Attempt $_reconnectionAttempts/$_maxReconnectionAttempts)';
    notifyListeners();

    try {
      if (selectedDevice != null) {
        await bluetooth.connect(selectedDevice!);
        connected = true;
        connectionStatus = 'Connected';
        _reconnectionAttempts = 0; // Reset on success
        _isReconnecting = false;
        notifyListeners();
        print('Reconnected successfully');
      } else {
        connectionStatus = 'No device selected for reconnection';
        _isReconnecting = false;
        notifyListeners();
        return;
      }
    } catch (e) {
      print('Reconnection attempt $_reconnectionAttempts failed: $e');
      _isReconnecting = false;

      if (_reconnectionAttempts < _maxReconnectionAttempts) {
        // Exponential backoff: 2s, 4s, 8s, 16s, 32s
        int delaySeconds = 2 << (_reconnectionAttempts - 1);
        connectionStatus =
            'Reconnecting in ${delaySeconds}s... (Attempt $_reconnectionAttempts/$_maxReconnectionAttempts)';
        notifyListeners();

        _reconnectionTimer = Timer(Duration(seconds: delaySeconds), () {
          _attemptReconnection();
        });
      } else {
        connectionStatus = 'Reconnection failed. Please reconnect manually.';
        notifyListeners();
      }
    }
  }

  // Health check method
  void startHealthCheck() {
    _healthCheckTimer?.cancel(); // Cancel existing timer
    _healthCheckTimer = Timer.periodic(Duration(seconds: 30), (timer) async {
      if (selectedDevice != null) {
        try {
          bool isActuallyConnected = await bluetooth.isConnected ?? false;
          if (!isActuallyConnected && connected) {
            print('Health check detected disconnection');
            connected = false;
            connectionStatus = 'Disconnected - Attempting to reconnect...';
            notifyListeners();
            _attemptReconnection();
          }
        } catch (e) {
          print('Health check error: $e');
        }
      } else {
        // Stop health check if no device is selected
        timer.cancel();
        print('Health check stopped - no device selected');
      }
    });
  }

  // Manual reconnection method for UI
  Future<void> manualReconnect() async {
    if (selectedDevice != null) {
      _reconnectionAttempts = 0; // Reset attempts for manual reconnection
      await _attemptReconnection();
    } else {
      connectionStatus = 'No device selected. Please select a device first.';
      notifyListeners();
    }
  }

  // Stop all timers when disposing
  @override
  void dispose() {
    _reconnectionTimer?.cancel();
    _healthCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> printReceipt(
    String datePrinted, //
    String dateDue, //
    String name, //
    String address, //
    String meterNo, //
    String meterBrand, //
    String accNo, //
    String currReading, //
    String prevReading, //
    int usage, //
    String waterBill, //
    String watermf, //
    double balance,
    String totaldue,
    String discDate,
    String lastReading,
    String billdate,
    String averageUsage,
    String otherFees,
    String cardRefNo,
    String prefsReadername,
    int cardwithSeniorDisc,
    String cardOthers,
    int previousUsage,
    int ftax,
    String messageText1,
    String messageText2,
    String messageText3
  ) async {
    // Check connection before printing
    if (selectedDevice == null) {
      connectionStatus = 'No device selected';
      notifyListeners();
      throw Exception('No printer device selected');
    }

    bool actuallyConnected = await bluetooth.isConnected ?? false;
    if (!actuallyConnected && connected) {
      connected = false;
      connectionStatus = 'Disconnected - Attempting to reconnect...';
      notifyListeners();
      await _attemptReconnection();
    }
    try {
      String formonth = billdate;

// Convert date from "01/07/2025" format to "July 2025"
      if (formonth.isNotEmpty && formonth.contains('/')) {
        try {
          print(formonth);
          print("parsing month");
          DateTime date = DateFormat('MM/dd/yyyy').parse(formonth);
          formonth = DateFormat('MMMM yyyy').format(date);
        } catch (e) {
          print('Error parsing date: $e');
        }
      }
      bool fordisconnect = false;
      String arrearsOrAdvance = '';
      if (balance <= 0) {
        arrearsOrAdvance = 'ADVANCE';
        fordisconnect = false;
      } else {
        arrearsOrAdvance = 'ARREARS';
        fordisconnect = true;
      }

      //calculate scdiscount
      String finalSCdisc = "";
      if (cardwithSeniorDisc == 1) {
        double scdiscount = (double.parse(waterBill) * 0.05);
        finalSCdisc = scdiscount.toStringAsFixed(2);
      }

      //Trim the reader name to first initial and last name
      List<String> parts = prefsReadername.trim().split(' ');
      String readertrimmed;
      if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
        readertrimmed = '${parts[0][0]}. ${parts[1]}';
      } else {
        readertrimmed =
            prefsReadername; // Fallback to full name if not enough parts
      }

      // Trim the last 5 characters from lastReading (with safety check)
      String trimmedPrev = lastReading.length > 5
          ? lastReading.substring(0, lastReading.length - 5)
          : lastReading;

      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);

      List<int> bytes = [];

      // Print header
      bytes += generator.feed(2);
      try {
        final ByteData data = await rootBundle
            .load('assets/icons/receiptlogo.png'); // path in your assets
        final Uint8List imageBytes = data.buffer.asUint8List();
        final img.Image? logo = img.decodeImage(imageBytes);
        if (logo != null) {
          bytes += generator.image(logo, align: PosAlign.center);
        }
      } catch (e) {
        print('Error loading logo: $e');
      }
      bytes += generator.text(
        'Dapitan City Water District',
        styles: PosStyles(
          align: PosAlign.center,
          height: PosTextSize.size1,
          width: PosTextSize.size1,
          bold: true,
        ),
      );

      // Print smaller font text
      bytes += generator.text(
        'National Highway Polo',
        styles: PosStyles(
          align: PosAlign.center,
          fontType: PosFontType.fontA, // Explicitly set Font B
        ),
      );
      bytes += generator.text(
        'Dapitan City',
        styles: PosStyles(align: PosAlign.center),
      );

      bytes += generator.text(
        'HOTLINE NO. 0948-4616-970',
        styles: PosStyles(align: PosAlign.center),
      );

      bytes += generator.text(
        'NON-VAT-REG. TIN 553-002',
        styles: PosStyles(align: PosAlign.center),
      );

      bytes += generator.reset();
      bytes += generator.hr();

      bytes += generator.text(
        'BILLING STATEMENT',
        styles: PosStyles(align: PosAlign.center, bold: true),
      );
      bytes +=
          generator.text('For the Month of $formonth'); //Current Month and year
      bytes += generator.text('Meter Reader: $readertrimmed');
      bytes += generator.text('Bill Num: $cardRefNo');

      bytes +=
          generator.text('Date Printed:$datePrinted'); //Current day and time
      bytes += generator
          .text('Period Covered:$trimmedPrev-$billdate'); //Bill covered
      bytes += generator.hr();
      bytes += generator.text(
        accNo,
        styles: PosStyles(height: PosTextSize.size2, width: PosTextSize.size2),
      );
      bytes += generator.hr();
      bytes += generator.text(
        name,
        styles: PosStyles(width: PosTextSize.size2, bold: true),
      );
      bytes += generator.reset();
      bytes += generator.text(
        address,
        styles: PosStyles(
          fontType: PosFontType.fontA, // Explicitly set Font B
        ),
      );
      bytes += generator.reset();
      bytes += generator.text('Meter #: $meterNo');
      bytes += generator.text('Meter Brand: $meterBrand');
      bytes += generator.reset();
      bytes += generator.hr();
      bytes += generator.row([
        PosColumn(
          text: 'Curr READING',
          width: 9,
          styles: PosStyles(height: PosTextSize.size2),
        ),
        PosColumn(
          text: currReading,
          width: 3,
          styles: PosStyles(height: PosTextSize.size2, align: PosAlign.right),
        ),
      ]);
      bytes += generator.row([
        PosColumn(
          text: 'Prev READING',
          width: 9,
          styles: PosStyles(height: PosTextSize.size2),
        ),
        PosColumn(
          text: prevReading,
          width: 3,
          styles: PosStyles(height: PosTextSize.size2, align: PosAlign.right),
        ),
      ]);
      bytes += generator.row([
        PosColumn(
          text: 'Curr USAGE',
          width: 9,
          styles: PosStyles(height: PosTextSize.size2),
        ),
        PosColumn(
          text: usage.toString(),
          width: 3,
          styles: PosStyles(height: PosTextSize.size2, align: PosAlign.right),
        ),
      ]);
      //only show up if previous usage is available
      if (previousUsage != 0) {
        bytes += generator.row([
          PosColumn(
            text: 'Prev USAGE',
            width: 9,
            styles: PosStyles(height: PosTextSize.size2),
          ),
          PosColumn(
            text: previousUsage.toString(),
            width: 3,
            styles: PosStyles(height: PosTextSize.size2, align: PosAlign.right),
          ),
        ]);
      }
      bytes += generator.reset();
      /**bytes += generator.row([
        PosColumn(
          text: '(3 Months AVE USAGE $averageUsage)',
          width: 9,
        ),
        PosColumn(
          text: '',
          width: 3,
        ),
      ]);
      bytes += generator.reset();
      */
      bytes += generator.hr();
      bytes += generator.row([
        PosColumn(
          text: 'WATER BILL',
          width: 8,
          styles: PosStyles(height: PosTextSize.size1, bold: true),
        ),
        PosColumn(
          text: waterBill,
          width: 4,
          styles: PosStyles(
              height: PosTextSize.size1, bold: true, align: PosAlign.right),
        ),
      ]);
      //show up if senior citizen discount is applied
      if (cardwithSeniorDisc == 1 && usage < 31) {
        bytes += generator.row([
          PosColumn(
            text: 'SC DISCOUNT',
            width: 8,
            styles: PosStyles(height: PosTextSize.size1, bold: true),
          ),
          PosColumn(
            text: '-$finalSCdisc',
            width: 4,
            styles: PosStyles(
                height: PosTextSize.size1, bold: true, align: PosAlign.right),
          ),
        ]);
      }
      bytes += generator.row([
        PosColumn(
          text: 'W.M.C.',
          width: 8,
          styles: PosStyles(height: PosTextSize.size1, bold: true),
        ),
        PosColumn(
          text: watermf,
          width: 4,
          styles: PosStyles(
              height: PosTextSize.size1, bold: true, align: PosAlign.right),
        ),
      ]);
      if (balance != 0) {
        bytes += generator.row([
          PosColumn(
            text: arrearsOrAdvance,
            width: 8,
            styles: PosStyles(height: PosTextSize.size1, bold: true),
          ),
          PosColumn(
            text: balance.toStringAsFixed(2),
            width: 4,
            styles: PosStyles(
                height: PosTextSize.size1, bold: true, align: PosAlign.right),
          ),
        ]);
      }

      if (cardOthers != "0.00" && cardOthers.isNotEmpty) {
        bytes += generator.row([
          PosColumn(
            text: 'W.S.C.',
            width: 8,
            styles: PosStyles(height: PosTextSize.size1, bold: true),
          ),
          PosColumn(
            text: cardOthers,
            width: 4,
            styles: PosStyles(
                height: PosTextSize.size1, bold: true, align: PosAlign.right),
          ),
        ]);
      }

      bytes += generator.row([
        PosColumn(
          text: 'TOTAL DUE',
          width: 8,
          styles: PosStyles(height: PosTextSize.size2, bold: true),
        ),
        PosColumn(
          text: totaldue,
          width: 4,
          styles: PosStyles(
              height: PosTextSize.size2, bold: true, align: PosAlign.right),
        ),
      ]);
      bytes += generator.row([
        PosColumn(
          text: 'DUE DATE',
          width: 7,
          styles: PosStyles(height: PosTextSize.size1, bold: true),
        ),
        PosColumn(
          text: fordisconnect ? 'IMMEDIATELY' : dateDue,
          width: 5,
          styles: PosStyles(
              height: PosTextSize.size1, bold: true, align: PosAlign.right),
        ),
      ]);
      bytes += generator.row([
        PosColumn(
          text: 'DISC DATE',
          width: 7,
          styles: PosStyles(height: PosTextSize.size1, bold: true),
        ),
        PosColumn(
          text: fordisconnect ? 'IMMEDIATELY' : discDate,
          width: 5,
          styles: PosStyles(
              height: PosTextSize.size1, bold: true, align: PosAlign.right),
        ),
      ]);
      bytes += generator.reset();
      bytes += generator.hr();
      //messages
      bytes += generator.text('N O T I C E',
          styles: PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.text(
          'Failure to pay your bill 3 days after the due-date, your service connection will be disconnected immediately without further     notice.',
          styles: PosStyles(align: PosAlign.center));
      bytes += generator.text(
          'Accounts with existing arrears  will be disconnected immediately without further notice.',
          styles: PosStyles(align: PosAlign.center));
      bytes += generator.text('   Thank you for your prompt       payment.',
          styles: PosStyles(align: PosAlign.center));
      bytes += generator.cut();

      Uint8List byteList = Uint8List.fromList(bytes);
      bluetooth.writeBytes(byteList);
    } catch (e) {
      connected = false;
      connectionStatus = 'Print failed - Attempting to reconnect...';
      notifyListeners();
      // Try to reconnect automatically
      await _attemptReconnection();
      throw Exception('Printer disconnected or error during print: $e');
    }
  }
}
