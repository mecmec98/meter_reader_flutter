import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:meter_reader_flutter/pages/postmeterreading.dart';
//import 'package:path/path.dart';
import 'package:meter_reader_flutter/helpers/database_helper.dart';

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
  Future<Map<String, dynamic>?>? _masterData;
  // List<CategoryModel> categories = [];

  // void _getCategories() {
  //   categories = CategoryModel.getCategories();
  // }

  @override
  void initState() {
    super.initState();
    _fetchData();
    // _getCategories();
  }

  void _fetchData() {
    setState(() {
      _masterData = DatabaseHelper().getMasterByID(1);
    });
  }

  @override
  Widget build(BuildContext context) {
    // _getCategories();
    return Scaffold(
      appBar: appBar(),
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
          Center(child: databaseConnectionSample())
        ],
      ),
    );
  }

  Container databaseConnectionSample() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey,
        borderRadius: BorderRadius.circular(10),
      ),
      child: FutureBuilder<Map<String, dynamic>?>(
        future: _masterData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else if (!snapshot.hasData || snapshot.data == null) {
            return Text('No data found');
          } else {
            final data = snapshot.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ACC: ${data['ACC1']}'),
                Text('Name: ${data['NAME']}'),
                Text('ADDRESS:${data['ADDRESS']}'),
              ],
            );
          }
        },
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
              )
             
            ),
            //Print Bill
            Padding(
              padding: EdgeInsets.only(top: 20, right: 50, left: 50),
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
          ],
        )
        //Commented Container sample
        // Container(
        //   height: 600,
        //   //color: Colors.blue,
        //   child: ListView.separated(
        //       scrollDirection: Axis.vertical,
        //       padding: EdgeInsets.only(left: 20, right: 20,),
        //       separatorBuilder: (context, index) => SizedBox(width: 30),
        //       itemCount: categories.length,
        //       itemBuilder: (context, index) {
        //         return Container(
        //           width: 105,
        //           decoration: BoxDecoration(
        //               color: categories[index].boxColor.withOpacity(0.8),
        //               borderRadius: BorderRadius.circular(17)),
        //           child: Column(
        //             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        //             children: [
        //               Container(
        //                 width: 50,
        //                 height: 50,
        //                 decoration: BoxDecoration(
        //                   color: Colors.white,
        //                   shape: BoxShape.circle,
        //                 ),
        //                 child:
        //                 Padding(
        //                   padding: const EdgeInsets.all(8.0),
        //                   child: SvgPicture.asset(categories[index].iconPath),
        //                 ),
        //               ),
        //               Text(categories[index].name,
        //               style: TextStyle(
        //                 fontWeight: FontWeight.w400,
        //                 color: Colors.black,
        //                 fontSize: 14,
        //               ),)

        //             ],
        //           ),
        //         );
        //       }),
        // )
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
          onTap: () {},
          child: Container(
            margin: EdgeInsets.all(10),
            width: 37,
            alignment: Alignment.center,
            child: SvgPicture.asset(
              'assets/icons/person.svg',
              height: 25,
              width: 25,
              colorFilter:
                  const ColorFilter.mode(Colors.black, BlendMode.srcIn),
            ),
          ),
        )
      ],
    );
  }
}
