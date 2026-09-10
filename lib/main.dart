//import 'package:meter_reader_flutter/pages/sample.dart';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';


import 'package:meter_reader_flutter/pages/home.dart';
import 'package:meter_reader_flutter/pages/postmeterreading.dart';
import 'package:meter_reader_flutter/pages/consumercard.dart';
import 'package:meter_reader_flutter/pages/printbilllist.dart';
import 'package:meter_reader_flutter/pages/editbilllist.dart';
import 'package:meter_reader_flutter/pages/databasepage.dart';
import 'package:meter_reader_flutter/pages/appsettingspage.dart';
import 'package:meter_reader_flutter/pages/notes.dart';
import 'package:meter_reader_flutter/pages/consumer_note_details.dart';
import 'package:meter_reader_flutter/pages/disconnectionlist.dart';
import 'package:meter_reader_flutter/pages/noticelist.dart';


import 'package:provider/provider.dart';
import 'package:meter_reader_flutter/helpers/blueprinter_helper.dart';
//import 'package:flutter_svg/flutter_svg.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Precache SVG assets
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
        // '/printface': (context) => Printface(),
        '/databasepage': (context) => DatabasePage(),
        '/appsettingspage': (context) => AppSettingsPage(),
        '/notes': (context) => NotesPage(),
        '/disconnectionlist': (context) => DisconnectionList(),
        '/noticelist': (context) => NoticeList(),
      },
    );
  }
}


