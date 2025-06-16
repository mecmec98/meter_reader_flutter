//import 'dart:nativewrappers/_internal/vm/lib/ffi_native_type_patch.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
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
    // ignore: unnecessary_null_comparison
    if (device == null) return;
    try {
      selectedDevice = device;
      await bluetooth.connect(device);
      connected = true;
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

  Future<void> printSampleReceipt(
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
  ) async {
    if (connected) {
      DateTime now = DateTime.now();
      String monthInWords =
          DateFormat.MMMM().format(now); // Get the month in words
      String year = DateFormat.y().format(now); // Get the year in numbers

      String arrearsOrAdvance = '';
      if (balance < 0) {
        arrearsOrAdvance = 'Advance';
      } else {
        arrearsOrAdvance = 'Arrears';
      }

     //calculate scdiscount
     String finalSCdisc = "";
     if (cardwithSeniorDisc == 1) {
        double scdiscount = (double.parse(waterBill) * 0.05);
        finalSCdisc = scdiscount.toStringAsFixed(2);
      }

      //Trim the reader name to first initial and last name
      List<String> parts = prefsReadername.trim().split(' ');
      String readertrimmed = '${parts[0][0]} ${parts[1]}';

      // Trim the last 5 characters from lastReading
      String trimmedPrev = lastReading.substring(0, lastReading.length - 5);

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
        'National Highway Polo, Dapitan City',
        styles: PosStyles(
          align: PosAlign.center,
          fontType: PosFontType.fontB, // Explicitly set Font B
        ),
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
        styles: PosStyles(align: PosAlign.center),
      );
      bytes += generator.text('Meter Reader: $readertrimmed');
      bytes += generator.text('Bill Num: $cardRefNo');
      bytes += generator.text(
          'For the Month of: $monthInWords-$year'); //Current Month and year
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
      bytes += generator.text(name);
      bytes += generator.text(
        address,
        styles: PosStyles(
          fontType: PosFontType.fontB, // Explicitly set Font B
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
          text: 'W.M.F.',
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
   
      bytes += generator.row([
        PosColumn(
          text: arrearsOrAdvance,
          width: 8,
          styles: PosStyles(height: PosTextSize.size1, bold: true),
        ),
        PosColumn(
          text: balance.toString(),
          width: 4,
          styles: PosStyles(
              height: PosTextSize.size1, bold: true, align: PosAlign.right),
        ),
      ]);
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
    } else {
      //print('no printer connected');
    }
  }
}
