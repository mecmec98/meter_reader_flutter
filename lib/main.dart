import 'package:flutter/material.dart';
import 'package:meter_reader_flutter/pages/home.dart';
import 'package:meter_reader_flutter/pages/postmeterreading.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
      routes: {
        '/postmeterreading': (context) => Postmeterreading()
      },
    );
  }
}
