//import 'package:meter_reader_flutter/pages/sample.dart';

import 'package:flutter/material.dart';

import 'package:meter_reader_flutter/pages/home.dart';
import 'package:meter_reader_flutter/pages/postmeterreading.dart';
import 'package:meter_reader_flutter/pages/consumercard.dart';
import 'package:meter_reader_flutter/pages/printbilllist.dart';
import 'package:meter_reader_flutter/pages/printface.dart';
import 'package:meter_reader_flutter/pages/editbilllist.dart';

import 'package:provider/provider.dart';
import 'package:meter_reader_flutter/helpers/blueprinter_helper.dart';
//import 'package:flutter_svg/flutter_svg.dart';



void main() async {

  
  // Precache SVG assets
  // WidgetsFlutterBinding.ensureInitialized();
  // 
  // 
  // final svgLoader = SvgAssetLoader('assets/icons/print.svg');
  // final menuLoader = SvgAssetLoader('assets/icons/menu.svg');
  
  // await Future.wait([
  //   svg.cache.putIfAbsent(svgLoader.cacheKey(null), () => svgLoader.loadBytes(null)),
  //   svg.cache.putIfAbsent(menuLoader.cacheKey(null), () => menuLoader.loadBytes(null)),
  // ]);


  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => BluePrinterHelper()),
      ],
      child: MyApp(),
    ),
  );
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
        '/editbilllist': (context) => PrintEditList(),
        //'/consumercardbill': (context) => ConsumercardBill(),
        '/printbilllist': (context) => PrintbillList(),
        // '/sample': (context) => SamplePrint(),
        '/printface': (context) => Printface(),
      },
    );
  }
}

