//import 'dart:nativewrappers/_internal/vm/lib/ffi_native_type_patch.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
//import 'package:flutter/material.dart';
import 'dart:typed_data';

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

  void listenForDisconnects() {
    bluetooth.onStateChanged().listen((state) {
      if (state == BlueThermalPrinter.DISCONNECTED) {
        connected = false;
        notifyListeners();
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
      selectedDevice = device;
      await bluetooth.connect(device);
      connected = true;
      listenForDisconnects();
      notifyListeners();
      print(connected);
      print('Connected successfully');
    } catch (e) {
      connected = false;
      print('Connection failed: $e');
    }
  }

  Future<void> disconnectFromDevice() async {
    if (!connected || selectedDevice == null) return;
    await bluetooth.disconnect();
    connected = false;
    selectedDevice = null;
    notifyListeners();
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
    String usage, //
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
  ) async {
    if (connected && (await bluetooth.isConnected == true)) {
      //recheck if bluetooth is connected
      try {
        DateTime now = DateTime.now();
        String monthInWords =
            DateFormat.MMMM().format(now); // Get the month in words
        String year = DateFormat.y().format(now); // Get the year in numbers

        String arrearsOrAdvance = '';
        if (balance < 0) {
          arrearsOrAdvance = 'ADVANCE';
        } else {
          arrearsOrAdvance = 'ARREARS';
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
          readertrimmed = prefsReadername; // Fallback to full name if not enough parts
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
        bytes += generator.text(
            'For the Month of $monthInWords-$year'); //Current Month and year
        bytes += generator.text('Meter Reader: $readertrimmed');
        bytes += generator.text('Bill Num: $cardRefNo');
        
        bytes +=
            generator.text('Date Printed:$datePrinted'); //Current day and time
        bytes += generator
            .text('Period Covered:$trimmedPrev-$billdate'); //Bill covered
        bytes += generator.hr();
        bytes += generator.text(
          accNo,
          styles:
              PosStyles(height: PosTextSize.size2, width: PosTextSize.size2),
        );
        bytes += generator.hr();
        bytes += generator.text(name);
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
            text: 'CURR READING',
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
            text: 'PREV READING',
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
            text: 'CURR USAGE',
            width: 9,
            styles: PosStyles(height: PosTextSize.size2),
          ),
          PosColumn(
            text: usage,
            width: 3,
            styles: PosStyles(height: PosTextSize.size2, align: PosAlign.right),
          ),
        ]);
        bytes += generator.reset();
        bytes += generator.row([
          PosColumn(
            text: 'AVE USAGE',
            styles: PosStyles(height: PosTextSize.size2, bold: true),
            width: 9,
          ),
          PosColumn(
            text: averageUsage,
            styles: PosStyles(height: PosTextSize.size2, align: PosAlign.right),
            width: 3,
          ),
        ]);
        bytes += generator.reset();
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
        if (cardwithSeniorDisc == 1) {
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
            text: dateDue,
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
            text: discDate,
            width: 5,
            styles: PosStyles(
                height: PosTextSize.size1, bold: true, align: PosAlign.right),
          ),
        ]);
        bytes += generator.reset();
        bytes += generator.hr();
        bytes += generator.hr();
        //messages
        bytes += generator.text('N O T I C E',
            styles: PosStyles(align: PosAlign.center, bold: true));
        bytes += generator.text(
            'Failure to pay your bill 3 days after the due-date, your service connection will be disconnected immediately without further     notice.',
            styles: PosStyles(align: PosAlign.center));
        bytes += generator.text('   Thank you for your prompt       payment.',
            styles: PosStyles(align: PosAlign.center));
        bytes += generator.cut();

        Uint8List byteList = Uint8List.fromList(bytes);
        bluetooth.writeBytes(byteList);
      } catch (e) {
        connected = false;
        await disconnectFromDevice(); // Force disconnect to reset state
        notifyListeners();
        throw Exception('Printer disconnected or error during print: $e');
      }
    } else {
      connected = false;
      await disconnectFromDevice();
      notifyListeners();
      throw Exception('No printer connected');
    }
  }
}
