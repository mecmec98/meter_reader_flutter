import 'package:flutter/material.dart';
import 'package:meter_reader_flutter/pages/home.dart';
import 'package:meter_reader_flutter/pages/postmeterreading.dart';
import 'package:meter_reader_flutter/pages/consumercard.dart';
import 'package:meter_reader_flutter/pages/sample.dart';
import 'package:meter_reader_flutter/pages/printbilllist.dart';
//import 'package:sqflite/sqflite.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => HomePage(),
        '/postmeterreading': (context) => Postmeterreading(),
        '/consumercard': (context) => Consumercard(),
        '/printbilllist': (context) => PrintbillList(),
        '/sample': (context) => TestBillingPage()
      },
    );
  }
}
