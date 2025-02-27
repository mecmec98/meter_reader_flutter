import 'dart:nativewrappers/_internal/vm/lib/ffi_native_type_patch.dart';

import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';

class BluePrinterHelper {
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  List<BluetoothDevice> devices = [];
  BluetoothDevice? selectedDevice;
  bool connected = false;

  Future<void> initBluetooth() async {
    bool? isConnected = await bluetooth.isConnected;
    devices = await bluetooth.getBondedDevices();
    connected = isConnected!;
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    await bluetooth.connect(device);
    connected = true;
    selectedDevice = device;
  }

  Future<void> disconnectFromDevice() async {
    await bluetooth.disconnect();
    connected = false;
    selectedDevice = null;
  }

  Future<void> printSampleReceipt(
      String datePrinted,
      String dateDue,
      String name,
      String address,
      String meterNo,
      String meterBrand,
      String accNo,
      String currReading,
      String prevReading,
      String usage,
      String waterBill,
      String watermf,
      String balance,
      String totaldue) async {
    if (connected) {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);

      List<int> bytes = [];

      // Print header
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
      bytes += generator.text('For the Month of:'); //Current Month and year
      bytes += generator.text('Date Printed: $datePrinted'); //Current day and time
      bytes += generator.text('Period Covered:'); //Bill covered
      bytes += generator.hr();
      bytes += generator.text(
        '101-102-179-D',
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
          text: 'USAGE',
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
      bytes += generator.hr();
      bytes += generator.row([
        PosColumn(
          text: 'WATER BILL',
          width: 9,
          styles: PosStyles(height: PosTextSize.size1, bold: true),
        ),
        PosColumn(
          text: waterBill,
          width: 3,
          styles: PosStyles(
              height: PosTextSize.size1, bold: true, align: PosAlign.right),
        ),
      ]);
      bytes += generator.row([
        PosColumn(
          text: 'W.M.F.',
          width: 9,
          styles: PosStyles(height: PosTextSize.size1, bold: true),
        ),
        PosColumn(
          text: watermf,
          width: 3,
          styles: PosStyles(
              height: PosTextSize.size1, bold: true, align: PosAlign.right),
        ),
      ]);
      bytes += generator.row([
        PosColumn(
          text: 'Advancec/Arrears',
          width: 9,
          styles: PosStyles(height: PosTextSize.size1, bold: true),
        ),
        PosColumn(
          text: balance,
          width: 3,
          styles: PosStyles(
              height: PosTextSize.size1, bold: true, align: PosAlign.right),
        ),
      ]);
      bytes += generator.row([
        PosColumn(
          text: 'TOTAL DUE',
          width: 9,
          styles: PosStyles(height: PosTextSize.size2, bold: true),
        ),
        PosColumn(
          text: totaldue,
          width: 3,
          styles: PosStyles(
              height: PosTextSize.size2, bold: true, align: PosAlign.right),
        ),
      ]);
      bytes += generator.reset();
      bytes += generator.text(dateDue);
      bytes += generator.hr();
      bytes += generator.text(
          'Please pay on time to avoid late penalties!');

      bytes += generator.feed(1);
      bytes += generator.cut();

      Uint8List byteList = Uint8List.fromList(bytes);
      bluetooth.writeBytes(byteList);
    }
  }
}
