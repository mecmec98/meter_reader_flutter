import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:meter_reader_flutter/models/category_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:meter_reader_flutter/pages/postmeterreading.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:meter_reader_flutter/pages/postmeterreading.dart';

class HomePage extends StatefulWidget {
  HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<CategoryModel> categories = [];

  void _getCategories() {
    categories = CategoryModel.getCategories();
  }

  @override
  void _initState() {
    _getCategories();
  }

  @override
  Widget build(BuildContext context) {
    _getCategories();
    return Scaffold(
      appBar: appBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //searchBar(),
          SizedBox(
            height: 20,
          ),
          categoriesSection()
        ],
      ),
    );
  }

  Column categoriesSection() {
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
                  Navigator.of(context as BuildContext).push(
                    MaterialPageRoute(
                        builder: (context) => const Postmeterreading()),
                  );
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

  Container searchBar() {
    return Container(
      margin: EdgeInsets.only(top: 40, left: 20, right: 20),
      decoration: BoxDecoration(boxShadow: [
        BoxShadow(
          color: Color.fromARGB(255, 230, 223, 223).withValues(),
          blurRadius: 8,
          spreadRadius: 0.0,
        )
      ]),
      child: TextField(
          decoration: InputDecoration(
        hintText: 'Search',
        hintStyle: TextStyle(color: Color.fromARGB(255, 195, 186, 186)),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Padding(
          padding: const EdgeInsets.all(10.0),
          child: SvgPicture.asset(
            'assets/icons/search.svg',
            colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
          ),
        ),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none),
      )),
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
